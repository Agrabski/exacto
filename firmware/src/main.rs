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

use ::ballistic_calculator::{BBDrift, CalculatorConfiguration};
use arduino_hal::default_serial;
use embedded_graphics::prelude::{DrawTarget, Primitive};
use embedded_graphics::primitives::{Line, PrimitiveStyleBuilder};
use embedded_graphics::Drawable;
use embedded_graphics::{
    pixelcolor::Rgb565,
    prelude::{Point, RgbColor},
};
use embedded_graphics_core::{prelude::Size, primitives::Rectangle};

use crate::display_initialisation::create_display;
use crate::sight::Sight;

#[arduino_hal::entry]
fn main() -> ! {
    let dp = arduino_hal::Peripherals::take().unwrap();
    let pins = arduino_hal::pins!(dp);
    // Hardware SPI on the ATmega2560 lives on PB0-PB3 (Mega pins D53/D52/D51/D50).
    let cs = pins.d53.into_output(); // PB0 / SS
    let clk = pins.d52.into_output(); // PB1 / SCK
    let din = pins.d51.into_output(); // PB2 / MOSI
    let rst = pins.d4.downgrade().into_output();
    let dc = pins.d5.downgrade().into_output();
    let miso = pins.d50.into_pull_up_input(); // PB3 / MISO

    let mut interface = create_display(dp.SPI, cs, clk, din, rst, dc, miso);

    display_startup_screen(&mut interface);

    let mut sight = Sight {
        x_zero: 0,
        y_zero: 0,
        battery_power: 15,
        range: 33,
        last_range: 0,
        drift: Point::default(),
        configuration: CalculatorConfiguration::default(),
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

    let mut serial = default_serial!(dp, pins, 57600);

    let mut last_update_loop = 0;
    let mut settings_state = settings::SettingsState::new();
    interface.clear_oled();
    let mut settings_were_opened = false;
    ufmt::uwriteln!(&mut serial, "start").ok();
    display_sight(&mut interface, &sight);
    loop {
        let mut last_sight = sight.clone();
        last_update_loop += 1;
        let event = buttons::poll();
        let settings_was_updated = settings_state.update(&mut sight, event);
        if settings_was_updated || settings_state.is_open() {
            if settings_was_updated {
                interface.clear_oled();
                settings_state.draw(&mut interface, &sight);
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
                last_update_loop = 0;
                settings_were_opened = false;
            }
        }
    }
}

fn display_startup_screen<T>(interface: &mut T)
where
    T: DrawTarget<Color = Rgb565, Error: Debug>,
{
    let dimensions = interface.bounding_box().size;
    text::draw_text(
        interface,
        "EXACTO XM1E0",
        Point::new((dimensions.width / 2 - 12) as i32, 0),
        Rgb565::WHITE,
        Rgb565::BLACK,
    );
    Rectangle::new(Point::new(10, 10), Size::new(40, 30))
        .into_styled(PrimitiveStyleBuilder::new().fill_color(Rgb565::RED).build())
        .draw(interface)
        .unwrap();

    arduino_hal::delay_ms(200);

    Rectangle::new(Point::new(15, 15), Size::new(40, 30))
        .into_styled(
            PrimitiveStyleBuilder::new()
                .fill_color(Rgb565::GREEN)
                .build(),
        )
        .draw(interface)
        .unwrap();

    arduino_hal::delay_ms(200);

    Rectangle::new(Point::new(20, 20), Size::new(40, 30))
        .into_styled(
            PrimitiveStyleBuilder::new()
                .fill_color(Rgb565::BLUE)
                .build(),
        )
        .draw(interface)
        .unwrap();

    arduino_hal::delay_ms(200);
    let line_style = PrimitiveStyleBuilder::new()
        .stroke_color(Rgb565::WHITE)
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

    arduino_hal::delay_ms(500);
}

fn display_sight<T>(interface: &mut T, sight: &Sight)
where
    T: DrawTarget<Color = Rgb565, Error: Debug>,
{
    let mut buffer = *b"RNG: XXX";
    write_value(interface, sight.range, Point::new(0, 84), &mut buffer);

    buffer = *b"PWR: XXX";
    write_value(
        interface,
        sight.battery_power,
        Point::new(0, 90),
        &mut buffer,
    );
    draw_reticle(interface, sight);
}

fn draw_reticle<T>(interface: &mut T, sight: &Sight)
where
    T: DrawTarget<Color = Rgb565, Error: Debug>,
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
}

fn draw_rectangle<T>(interface: &mut T, rectangle: Rectangle)
where
    T: DrawTarget<Color = Rgb565, Error: Debug>,
{
    let r = rectangle.into_styled(
        PrimitiveStyleBuilder::new()
            .stroke_width(1)
            .stroke_color(Rgb565::RED)
            .build(),
    );
    r.draw(interface).unwrap();
}

fn write_value<T>(interface: &mut T, value: u8, position: Point, buffer: &mut [u8])
where
    T: DrawTarget<Color = Rgb565, Error: Debug>,
{
    format_two_digit_16(value as i16, buffer);
    // `buffer` holds ASCII produced by `format_two_digit_16`, so it is valid UTF-8.
    let text = unsafe { core::str::from_utf8_unchecked(buffer) };
    text::draw_text(interface, text, position, Rgb565::WHITE, Rgb565::BLACK);
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
