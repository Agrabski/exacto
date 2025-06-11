#![no_std]
#![no_main]
mod display_initialisation;

use embedded_graphics::Drawable;
use embedded_graphics::{
    pixelcolor::Rgb565,
    prelude::{Point, Primitive, RgbColor},
    primitives::PrimitiveStyleBuilder,
};
use embedded_graphics_core::{prelude::Size, primitives::Rectangle};

use crate::display_initialisation::create_display;

#[arduino_hal::entry]
fn main() -> ! {
    let dp = arduino_hal::Peripherals::take().unwrap();
    let pins = arduino_hal::pins!(dp);

    let mut interface = create_display(dp.SPI, pins);
    let r = Rectangle::new(Point::new(0, 0), Size::new(48, 48)).into_styled(
        PrimitiveStyleBuilder::new()
            .stroke_width(1)
            .stroke_color(Rgb565::RED)
            .fill_color(Rgb565::BLACK)
            .build(),
    );
    r.draw(&mut interface).unwrap();

    loop {}
}
