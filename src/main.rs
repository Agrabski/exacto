#![no_std]
#![no_main]
mod display_initialisation;
mod embedded_graphics_transform;
mod encoder;
mod settings;
mod sight;
mod ballistic_calculator;
mod physics;

use core::fmt::Debug;

use arduino_hal::default_serial;
use embedded_graphics::mono_font::ascii::FONT_6X10;
use embedded_graphics::mono_font::MonoTextStyle;
use embedded_graphics::prelude::{DrawTarget, Primitive};
use embedded_graphics::primitives::PrimitiveStyleBuilder;
use embedded_graphics::text::Text;
use embedded_graphics::Drawable;
use embedded_graphics::{
    pixelcolor::Rgb565,
    prelude::{Point, RgbColor},
};
use embedded_graphics_core::{prelude::Size, primitives::Rectangle};

use crate::ballistic_calculator::BBDrift;
use crate::display_initialisation::create_display;
use crate::encoder::RotaryEncoder;
use crate::sight::Sight;

#[arduino_hal::entry]
fn main() -> ! {
    let dp = arduino_hal::Peripherals::take().unwrap();
    let pins = arduino_hal::pins!(dp);
    let cs = pins.d10.into_output();
    let clk = pins.d13.into_output();
    let din = pins.d11.into_output();
    let rst = pins.d4.downgrade().into_output();
    let dc = pins.d5.downgrade().into_output();
    let miso = pins.d12.into_pull_up_input();

    let mut interface = create_display(dp.SPI, cs, clk, din, rst, dc, miso);

    let mut sight = Sight {
        x_zero: 0,
        y_zero: 0,
        battery_power: 15,
        range: 33,
        last_range: 0,
        drift: BBDrift::default(),
        configuration: ballistic_calculator::CalculatorConfiguration::default(),
    };
    interface.clear_oled();
    display_sight(&mut interface, &sight);
    let pin_a = pins.d2.into_pull_up_input();
    let pin_b = pins.d3.into_pull_up_input();
    let pin_sw = pins.d9.into_pull_up_input();

    let mut encoder = RotaryEncoder::new(pin_a, pin_b, pin_sw).unwrap();

    let mut serial = default_serial!(dp, pins, 57600);
    let mut last_update_loop = 0;
    let mut last_sight = sight;
    let mut settings_state = settings::SettingsState::new();

    loop {
        encoder.update().unwrap();
        ufmt::uwriteln!(&mut serial, "position {}", encoder.position()).ok();
        last_update_loop += 1;
        let settings_was_updated = settings_state.update(&mut sight, &mut encoder);
        if settings_was_updated || settings_state.is_open() {
            if settings_was_updated {
                interface.clear_oled();
                settings_state.draw(&mut interface, &sight);
                last_update_loop = 8000;
            }
        } else {
            let mut position = encoder.position();
            if position < 0 {
                encoder.reset();
                position = 0;
            }
            if sight.range != position as u8 {
                sight.range = position as u8;
                sight.update();
            }
            if (last_update_loop > 500 && last_sight != sight)
                || last_update_loop > 5000
                || absolute_difference(last_sight.range, sight.range) > 8
            {
                interface.clear_oled();
                display_sight(&mut interface, &sight);
                last_update_loop = 0;
                last_sight = sight;
            }
        }
    }
}

fn display_sight<T>(interface: &mut T, sight: &Sight)
where
    T: DrawTarget<Color = Rgb565, Error: Debug>,
{
    let mut buffer = *b"RNG: XXX";
    write_value(interface, sight.range, Point::new(0, 76), &mut buffer);

    buffer = *b"PWR: XXX";
    write_value(
        interface,
        sight.battery_power,
        Point::new(0, 86),
        &mut buffer,
    );
    draw_reticle(interface, sight);
}

fn absolute_difference(a: u8, b: u8) -> u8 {
    (a as i16 - b as i16).abs() as u8
}

fn draw_reticle<T>(interface: &mut T, sight: &Sight)
where
    T: DrawTarget<Color = Rgb565, Error: Debug>,
{
    let reticle_size: u8 = 8;
    let center = sight.point_of_aim();
    let r = Rectangle::with_center(
        center,
        Size::new(reticle_size as u32, reticle_size as u32),
    )
    .into_styled(
        PrimitiveStyleBuilder::new()
            .stroke_width(1)
            .stroke_color(Rgb565::RED)
            .build(),
    );
    r.draw(interface).unwrap();
    let point_of_impact = sight.calculated_point_of_impact();
    let adjusted = Rectangle::with_center(
        point_of_impact,
        Size::new((reticle_size / 2) as u32, (reticle_size / 2) as u32),
    )
    .into_styled(
        PrimitiveStyleBuilder::new()
            .stroke_width(1)
            .stroke_color(Rgb565::RED)
            .build(),
    );
    adjusted.draw(interface).unwrap();

    Rectangle::new(Point::new(0, 0), interface.bounding_box().size)
        .into_styled(
            PrimitiveStyleBuilder::new()
                .stroke_width(1)
                .stroke_color(Rgb565::WHITE)
                .build(),
        )
        .draw(interface)
        .unwrap();
}

fn write_value<T>(interface: &mut T, value: u8, position: Point, buffer: &mut [u8])
where
    T: DrawTarget<Color = Rgb565, Error: Debug>,
{
    let style = MonoTextStyle::new(&FONT_6X10, Rgb565::WHITE);

    format_two_digit(value, buffer);
    Text::new(str::from_utf8(&buffer).unwrap(), position, style)
        .draw(interface)
        .unwrap();
}

fn format_two_digit(num: u8, buf: &mut [u8]) {
    assert!(buf.len() >= 3, "Buffer must be at least 3 bytes long");

    let len = buf.len();
    buf[len - 3] = b'0' + ((num / 100) % 10) as u8;
    buf[len - 2] = b'0' + ((num / 10) % 10) as u8;
    buf[len - 1] = b'0' + (num % 10) as u8;
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
