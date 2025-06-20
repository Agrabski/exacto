use display_interface::DisplayError;
use crate::embedded_graphics_transform::{ FlipY};
use embedded_hal::delay::DelayNs;
use ssd1351::mode::GraphicsMode;

use arduino_hal::{
    hal::{
        self,
        port::{self, Dynamic, PB2, PB3, PB4, PB5},
    },
    pac::SPI,
    port::{
        mode::{Input, Output, PullUp},
        Pin,
    },
    spi::{ChipSelectPin, DataOrder, SerialClockRate},
    Spi,
};
use byte_slice_cast::AsByteSlice;
use display_interface::{DataFormat, WriteOnlyDataCommand};
use embedded_hal::spi::{SpiBus, MODE_0};
use panic_halt as _;
use ssd1351::{
    builder::Builder,
    properties::{DisplayRotation, DisplaySize},
};
pub struct SpiWrapper<CSPIN>
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

pub fn create_display(
    spi: SPI,
    mut cs: Pin<Output, PB2>,
    clk: Pin<Output, PB5>,
    din: Pin<Output, PB3>,
    mut rst: Pin<Output, Dynamic>,
    mut dc: Pin<Output, Dynamic>,
    miso: Pin<Input<PullUp>, PB4>,
) -> FlipY<GraphicsMode<SpiWrapper<PB2>>> {
    cs.set_low();
    dc.set_low();
    rst.set_low();
    let spi = arduino_hal::spi::Spi::new(
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
    interface.clear();
    return FlipY::new(interface);
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
