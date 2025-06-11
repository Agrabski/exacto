#![no_std]
#![no_main]

use core::fmt::{self, Write};

use arduino_hal::{
    hal::{
        self,
        delay::Delay,
        port::{self, PB2},
        usart::Usart0,
    },
    pac::SPI,
    spi::{ChipSelectPin, DataOrder, SerialClockRate, SpiOps},
    Peripherals, Spi,
};
use byte_slice_cast::AsByteSlice;
use display_interface::{DataFormat, DisplayError, WriteOnlyDataCommand};
use display_interface_spi::SPIInterface;
use embedded_graphics::Drawable;
use embedded_graphics::{
    pixelcolor::Rgb565,
    prelude::{Point, Primitive, RgbColor},
    primitives::{PrimitiveStyle, PrimitiveStyleBuilder},
};
use embedded_graphics_core::{prelude::Size, primitives::Rectangle};
use embedded_hal::{
    delay::DelayNs,
    spi::{SpiBus, SpiDevice, MODE_0},
};
use panic_halt as _;
use ssd1351::{
    builder::Builder,
    mode::GraphicsMode,
    properties::{DisplayRotation, DisplaySize},
};

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
struct SpiWrapper<CSPIN>
where
    CSPIN: port::PinOps,
{
    spi: (Spi, ChipSelectPin<CSPIN>),
    dc: arduino_hal::port::Pin<arduino_hal::port::mode::Output>,
}
const BUFFER_SIZE: usize = 64;

impl<CSPIN> WriteOnlyDataCommand for SpiWrapper<CSPIN>
where
    CSPIN: port::PinOps,
{
    fn send_commands(
        &mut self,
        commands: display_interface::DataFormat,
    ) -> Result<(), display_interface::DisplayError> {
        // Implement the logic to send commands over SPI
        self.dc.set_low();
        send_u8(&mut self.spi.0, commands)
            .map_err(|_| display_interface::DisplayError::BusWriteError)
    }

    fn send_data(
        &mut self,
        data: display_interface::DataFormat,
    ) -> Result<(), display_interface::DisplayError> {
        // Implement the logic to send data over SPI
        self.dc.set_high();

        // Send words over SPI
        send_u8(&mut self.spi.0, data).map_err(|_| display_interface::DisplayError::BusWriteError)
    }
}

fn send_u8(spi: &mut Spi, words: DataFormat<'_>) -> Result<(), DisplayError> {
    match words {
        DataFormat::U8(slice) => spi.write(slice).map_err(|_| DisplayError::BusWriteError),
        DataFormat::U16(slice) => spi
            .write(slice.as_byte_slice())
            .map_err(|_| DisplayError::BusWriteError),
        DataFormat::U16LE(slice) => {
            for v in slice.as_mut() {
                *v = v.to_le();
            }
            spi.write(slice.as_byte_slice())
                .map_err(|_| DisplayError::BusWriteError)
        }
        DataFormat::U16BE(slice) => {
            for v in slice.as_mut() {
                *v = v.to_be();
            }
            spi.write(slice.as_byte_slice())
                .map_err(|_| DisplayError::BusWriteError)
        }
        DataFormat::U8Iter(iter) => {
            let mut buf = [0; BUFFER_SIZE];
            let mut i = 0;

            for v in iter.into_iter() {
                buf[i] = v;
                i += 1;

                if i == buf.len() {
                    spi.write(&buf).map_err(|_| DisplayError::BusWriteError)?;
                    i = 0;
                }
            }

            if i > 0 {
                spi.write(&buf[..i])
                    .map_err(|_| DisplayError::BusWriteError)?;
            }

            Ok(())
        }
        DataFormat::U16LEIter(iter) => {
            let mut buf = [0; BUFFER_SIZE];
            let mut i = 0;

            for v in iter.map(u16::to_le) {
                buf[i] = v;
                i += 1;

                if i == buf.len() {
                    spi.write(buf.as_byte_slice())
                        .map_err(|_| DisplayError::BusWriteError)?;
                    i = 0;
                }
            }

            if i > 0 {
                spi.write(buf[..i].as_byte_slice())
                    .map_err(|_| DisplayError::BusWriteError)?;
            }

            Ok(())
        }
        DataFormat::U16BEIter(iter) => {
            let mut buf = [0; BUFFER_SIZE];
            let mut i = 0;
            let len = buf.len();

            for v in iter.map(u16::to_be) {
                buf[i] = v;
                i += 1;

                if i == len {
                    spi.write(buf.as_byte_slice())
                        .map_err(|_| DisplayError::BusWriteError)?;
                    i = 0;
                }
            }

            if i > 0 {
                spi.write(buf[..i].as_byte_slice())
                    .map_err(|_| DisplayError::BusWriteError)?;
            }

            Ok(())
        }
        _ => Err(DisplayError::DataFormatNotImplemented),
    }
}

struct DelayShim<WriteFn>
where
    WriteFn: FnMut(u32),
{
    delay: arduino_hal::hal::delay::Delay<hal::clock::MHz24>,
    log: WriteFn,
}
impl<WriteFn> DelayNs for DelayShim<WriteFn>
where
    WriteFn: FnMut(u32),
{
    fn delay_ns(&mut self, ns: u32) {
        (self.log)(ns);
        arduino_hal::delay_ns(ns);
    }
}

fn create_display(spi: SPI, pins: arduino_hal::Pins) -> GraphicsMode<SpiWrapper<PB2>> {
    let mut cs = pins.d10.into_output();
    let mut clk = pins.d13.into_output();
    let mut din = pins.d11.into_output();
    let mut rst = pins.d2.downgrade().into_output();
    let mut dc = pins.d3.downgrade().into_output();
    let mut miso = pins.d12.into_pull_up_input();

    cs.set_low();
    dc.set_low();
    rst.set_low();
    let mut spi = arduino_hal::spi::Spi::new(
        spi,
        clk,  // or SCK/ SCLK
        din,  // or MOSI
        miso, //miso
        cs,
        arduino_hal::spi::Settings {
            data_order: DataOrder::MostSignificantFirst,
            clock: SerialClockRate::OscfOver2,
            mode: MODE_0,
        },
    );
    let mut interface: GraphicsMode<_> = Builder::new()
        .with_rotation(DisplayRotation::Rotate0)
        .with_size(DisplaySize::Display128x96)
        .connect_interface(SpiWrapper { spi, dc })
        .into();
    interface
        .reset(
            &mut rst,
            &mut DelayShim {
                delay: arduino_hal::hal::delay::Delay::<hal::clock::MHz24>::new(),
                log: |_| {},
            },
        )
        .unwrap();

    interface.init().unwrap();
    return interface;
}
