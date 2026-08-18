#![no_std]
#![no_main]
#![feature(abi_avr_interrupt)]
mod buttons;
mod display_initialisation;
mod embedded_graphics_transform;
mod settings;
mod sight;
mod text;

use core::fmt::Debug;

use ::ballistic_calculator::CalculatorConfiguration;
use arduino_hal::default_serial;
use embedded_graphics::prelude::{Dimensions, DrawTarget, Primitive};
use embedded_graphics::primitives::{Line, PrimitiveStyleBuilder};
use embedded_graphics::Drawable;
use embedded_graphics::{pixelcolor::BinaryColor, prelude::Point};
use embedded_graphics_core::{prelude::Size, primitives::Rectangle};

use crate::display_initialisation::{create_display, Display};
use crate::sight::Sight;

#[arduino_hal::entry]
fn main() -> ! {
    let dp = arduino_hal::Peripherals::take().unwrap();
    let pins = arduino_hal::pins!(dp);
    let mut serial = default_serial!(dp, pins, 57600);

    // Hardware I2C (TWI) on the ATmega2560 is hardwired to PD1/PD0 (Mega pins D20/D21).
    let sda = pins.d20.into_pull_up_input(); // PD1 / SDA
    let scl = pins.d21.into_pull_up_input(); // PD0 / SCL
    let rst = pins.d4.downgrade().into_output();

    let mut interface = create_display(dp.TWI, sda, scl, rst, &mut serial);

    display_startup_screen(&mut interface);

    let mut sight = Sight {
        x_zero: 0,
        y_zero: 0,
        battery_power: 15,
        range: 30,
        last_range: 0,
        drift: Point::default(),
        configuration: CalculatorConfiguration::default(),
        time_of_flight_ms: 0,
    };
    // Buttons: active-low with internal pull-ups. up=d2 (INT4), down=d3 (INT5),
    // select=d18 (INT3). The interrupt vectors read the port directly, so the pin
    // handles are dropped once the pull-ups/DDR are latched.
    let _up = pins.d2.into_pull_up_input();
    let _down = pins.d3.into_pull_up_input();
    let _select = pins.d18.into_pull_up_input();

    // Falling-edge sense (ISCx1:ISCx0 = 0b10) on INT3/INT4/INT5, then unmask them.
    dp.EXINT.eicra.modify(|_, w| w.isc3().val_0x02()); // INT3 (d18)
    dp.EXINT
        .eicrb
        .modify(|_, w| w.isc4().val_0x02().isc5().val_0x02()); // INT4 (d2), INT5 (d3)
    dp.EXINT.eifr.write(|w| w.bits(0b0011_1000)); // clear any pending INT3/4/5 flags
    dp.EXINT.eimsk.write(|w| w.bits(0b0011_1000)); // enable INT3/4/5
    unsafe { avr_device::interrupt::enable() };

    let mut last_update_loop = 0;
    let mut settings_state = settings::SettingsState::new();
    interface.clear_oled();
    let mut settings_were_opened = false;
    ufmt::uwriteln!(&mut serial, "start1").ok();
    display_sight(&mut interface, &sight);
    interface.flush().unwrap();
    loop {
        let last_sight = sight.clone();
        last_update_loop += 1;
        let event = buttons::poll();
        let settings_was_updated = settings_state.update(&mut sight, event);
        if settings_was_updated || settings_state.is_open() {
            if settings_was_updated {
                interface.clear_oled();
                settings_state.draw(&mut interface, &sight);
                interface.flush().unwrap();
                last_update_loop = 8000;
                settings_were_opened = true;
            }
        } else {
            if let Some(event) = event {
                if event == buttons::ButtonEvent::Up {
                    sight.range += 5;
                }
                if event == buttons::ButtonEvent::Down && sight.range >= 5 {
                    sight.range -= 5;
                }
                sight.update();
            }
            if last_sight != sight || settings_were_opened {
                interface.clear_oled();
                display_sight(&mut interface, &sight);
                interface.flush().unwrap();
                ufmt::uwriteln!(&mut serial, "TOF {}", sight.time_of_flight_ms).ok();
                last_update_loop = 0;
                settings_were_opened = false;
            }
        }
    }
}

fn display_startup_screen(interface: &mut Display) {
    let dimensions = interface.bounding_box().size;
    text::draw_text(
        interface,
        "EXACTO XM1E0",
        Point::new((dimensions.width / 2 - 12) as i32, 0),
        BinaryColor::On,
        BinaryColor::Off,
    );
    Rectangle::new(Point::new(10, 10), Size::new(40, 30))
        .into_styled(
            PrimitiveStyleBuilder::new()
                .fill_color(BinaryColor::On)
                .build(),
        )
        .draw(interface)
        .unwrap();
    interface.flush().unwrap();

    arduino_hal::delay_ms(200);

    Rectangle::new(Point::new(15, 15), Size::new(40, 30))
        .into_styled(
            PrimitiveStyleBuilder::new()
                .fill_color(BinaryColor::On)
                .build(),
        )
        .draw(interface)
        .unwrap();
    interface.flush().unwrap();

    arduino_hal::delay_ms(200);

    Rectangle::new(Point::new(20, 20), Size::new(40, 30))
        .into_styled(
            PrimitiveStyleBuilder::new()
                .fill_color(BinaryColor::On)
                .build(),
        )
        .draw(interface)
        .unwrap();
    interface.flush().unwrap();

    arduino_hal::delay_ms(200);
    let line_style = PrimitiveStyleBuilder::new()
        .stroke_color(BinaryColor::On)
        .stroke_width(1)
        .build();

    Line::new(
        Point::new(0, 0),
        Point::new(dimensions.width as i32 - 1, dimensions.height as i32 - 1),
    )
    .into_styled(line_style)
    .draw(interface)
    .unwrap();

    Line::new(
        Point::new(0, dimensions.height as i32 - 1),
        Point::new(dimensions.width as i32 - 1, 0),
    )
    .into_styled(line_style)
    .draw(interface)
    .unwrap();
    interface.flush().unwrap();

    arduino_hal::delay_ms(500);
}

fn display_sight<T>(interface: &mut T, sight: &Sight)
where
    T: DrawTarget<Color = BinaryColor, Error: Debug>,
{
    let mut buffer = *b"PWR: XXX";
    write_value(
        interface,
        sight.battery_power as u16,
        Point::new(0, 0),
        &mut buffer,
    );
    draw_reticle(interface, sight);
}

fn draw_reticle<T>(interface: &mut T, sight: &Sight)
where
    T: DrawTarget<Color = BinaryColor, Error: Debug>,
{
    let reticle_size: u32 = 8;
    let center = sight.point_of_aim();
    draw_rectangle(
        interface,
        Rectangle::with_center(center, Size::new(reticle_size, reticle_size)),
    );

    let point_of_impact = sight.calculated_point_of_impact();
    draw_rectangle(
        interface,
        Rectangle::with_center(
            point_of_impact,
            Size::new(reticle_size / 2, reticle_size / 2),
        ),
    );
    let text_position = point_of_impact + Point::new((reticle_size / 2 + 8) as i32, 0);
    let mut buffer = *b"TOF: XXX";
    write_value(
        interface,
        sight.time_of_flight_ms / 10, // tens of miliseconds
        text_position,
        &mut buffer,
    );
    buffer = *b"RNG: XXX";
    write_value(
        interface,
        sight.range as u16,
        text_position + Point::new(0, 6),
        &mut buffer,
    );
}

fn draw_rectangle<T>(interface: &mut T, rectangle: Rectangle)
where
    T: DrawTarget<Color = BinaryColor, Error: Debug>,
{
    let r = rectangle.into_styled(
        PrimitiveStyleBuilder::new()
            .stroke_width(1)
            .stroke_color(BinaryColor::On)
            .build(),
    );
    r.draw(interface).unwrap();
}

fn write_value<T>(interface: &mut T, value: u16, position: Point, buffer: &mut [u8])
where
    T: DrawTarget<Color = BinaryColor, Error: Debug>,
{
    format_two_digit_16(value as i16, buffer);
    // `buffer` holds ASCII produced by `format_two_digit_16`, so it is valid UTF-8.
    let text = unsafe { core::str::from_utf8_unchecked(buffer) };
    text::draw_text(interface, text, position, BinaryColor::On, BinaryColor::Off);
}

fn format_two_digit_16(num: i16, buf: &mut [u8]) {
    assert!(buf.len() >= 4, "Buffer must be at least 4 bytes long");

    let len = buf.len();
    let abs_num = num.abs() as u16;

    buf[len - 4] = if num < 0 { b'-' } else { b' ' };
    buf[len - 3] = b'0' + ((abs_num / 100) % 10) as u8;
    buf[len - 2] = b'0' + ((abs_num / 10) % 10) as u8;
    buf[len - 1] = b'0' + (abs_num % 10) as u8;
}
