use crate::embedded_graphics_transform::FlipY;

use arduino_hal::{
    hal::port::{Dynamic, PD0, PD1},
    i2c::Direction,
    pac::TWI,
    port::{
        mode::{Input, Output, PullUp},
        Pin,
    },
    I2c,
};
use panic_halt as _;
use ssd1306::{mode::BufferedGraphicsMode, prelude::*, I2CDisplayInterface, Ssd1306};

// Fallback used if the bus scan below finds nothing.
const DEFAULT_DISPLAY_I2C_ADDRESS: u8 = 0x3c;

/// Scans the full 7-bit I2C address space for a responding device, falling
/// back to the most common display address (0x3c) if nothing acknowledges.
/// Progress and the outcome are logged to `serial`.
fn detect_display_address(i2c: &mut I2c, serial: &mut impl ufmt::uWrite) -> u8 {
    ufmt::uwriteln!(serial, "Scanning I2C bus for display...").ok();
    for address in 0..=127u8 {
        if i2c.ping_device(address, Direction::Write).unwrap_or(false) {
            ufmt::uwriteln!(serial, "Display found at address {}", address).ok();
            return address;
        }
    }
    ufmt::uwriteln!(
        serial,
        "No I2C device found, defaulting to address {}",
        DEFAULT_DISPLAY_I2C_ADDRESS
    )
    .ok();
    DEFAULT_DISPLAY_I2C_ADDRESS
}

pub type Display =
    FlipY<Ssd1306<I2CInterface<I2c>, DisplaySize128x64, BufferedGraphicsMode<DisplaySize128x64>>>;

pub fn create_display(
    twi: TWI,
    sda: Pin<Input<PullUp>, PD1>,
    scl: Pin<Input<PullUp>, PD0>,
    mut rst: Pin<Output, Dynamic>,
    serial: &mut impl ufmt::uWrite,
) -> Display {
    let mut i2c = I2c::new(twi, sda, scl, 400_000);
    let address = detect_display_address(&mut i2c, serial);
    let mut delay = arduino_hal::Delay::new();

    let interface = I2CDisplayInterface::new_custom_address(i2c, address);
    let mut display = Ssd1306::new(interface, DisplaySize128x64, DisplayRotation::Rotate0)
        .into_buffered_graphics_mode();
    display.reset(&mut rst, &mut delay).unwrap();
    display.init().unwrap();
    display.clear_buffer();
    display.flush().unwrap();
    FlipY::new(display)
}
