#![no_std]
#![no_main]
mod display_initialisation;
mod sight;

use arduino_hal::hal::port::PB2;
use embedded_graphics::mono_font::ascii::FONT_6X10;
use embedded_graphics::mono_font::MonoTextStyle;
use embedded_graphics::prelude::Primitive;
use embedded_graphics::primitives::PrimitiveStyleBuilder;
use embedded_graphics::text::renderer::TextRenderer;
use embedded_graphics::text::{Text, TextStyle};
use embedded_graphics::Drawable;
use embedded_graphics::{
    pixelcolor::Rgb565,
    prelude::{Point, RgbColor},
};
use embedded_graphics_core::{prelude::Size, primitives::Rectangle};
use ssd1351::mode::GraphicsMode;

use crate::display_initialisation::{create_display, SpiWrapper};
use crate::sight::Sight;

#[arduino_hal::entry]
fn main() -> ! {
    let dp = arduino_hal::Peripherals::take().unwrap();
    let pins = arduino_hal::pins!(dp);

    let mut interface = create_display(dp.SPI, pins);

    display_sight(
        &mut interface,
        &Sight {
            x_zero: 15,
            y_zero: -9,
            battery_power: 15,
            range: 33,
        },
    );

    loop {}
}

fn display_sight(interface: &mut GraphicsMode<SpiWrapper<PB2>>, sight: &Sight) {
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

fn draw_reticle(interface: &mut GraphicsMode<SpiWrapper<PB2>>, sight: &Sight) {
    let reticle_size: u8 = 4;
    let position_x = (128 / 2 + sight.x_zero ) as u8;
    let position_y = (96 / 2 + sight.y_zero) as u8;
    let r = Rectangle::new(
        Point::new(
            (position_x - reticle_size / 2) as i32,
            (position_y - reticle_size / 2) as i32,
        ),
        Size::new(reticle_size as u32, reticle_size as u32),
    )
    .into_styled(
        PrimitiveStyleBuilder::new()
            .stroke_width(1)
            .stroke_color(Rgb565::RED)
            .build(),
    );
    r.draw(interface).unwrap();
}

fn write_value(
    interface: &mut GraphicsMode<SpiWrapper<PB2>>,
    value: u8,
    position: Point,
    buffer: &mut [u8],
) {
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
