//! Three-button input (up / down / select) driven by external interrupts.
//!
//! Buttons are active-low with internal pull-ups; a press pulls the pin to
//! ground, producing a falling edge that fires the matching INTx vector:
//!   - up     = d2  (PE4 / INT4)
//!   - down   = d3  (PE5 / INT5)
//!   - select = d18 (PD3 / INT3)

use avr_device::interrupt::Mutex;
use core::cell::Cell;
use ufmt::{uDisplay, Formatter};

#[derive(Clone, Copy, PartialEq, Eq)]
pub enum ButtonEvent {
    Up,
    Down,
    Select,
}

impl uDisplay for ButtonEvent {
    fn fmt<W: ufmt::uWrite>(&self, f: &mut Formatter<'_, W>) -> Result<(), W::Error>
    where
        W: ufmt::uWrite + ?Sized,
    {
        match self {
            ButtonEvent::Up => f.write_str("Up"),
            ButtonEvent::Down => f.write_str("Down"),
            ButtonEvent::Select => f.write_str("Select"),
        }
    }
}

// One pending flag per button. Set in the ISR, consumed in the main loop.
// Boolean-set is idempotent, so contact bounce within one (slow, SPI-bound)
// loop iteration coalesces to a single event — adequate debounce here.
static UP: Mutex<Cell<bool>> = Mutex::new(Cell::new(false));
static DOWN: Mutex<Cell<bool>> = Mutex::new(Cell::new(false));
static SELECT: Mutex<Cell<bool>> = Mutex::new(Cell::new(false));

#[avr_device::interrupt(atmega2560)]
fn INT4() {
    avr_device::interrupt::free(|cs| UP.borrow(cs).set(true));
}

#[avr_device::interrupt(atmega2560)]
fn INT5() {
    avr_device::interrupt::free(|cs| DOWN.borrow(cs).set(true));
}

#[avr_device::interrupt(atmega2560)]
fn INT3() {
    avr_device::interrupt::free(|cs| SELECT.borrow(cs).set(true));
}

/// Consume one pending event (select prioritised). Returns `None` if none pending.
pub fn poll() -> Option<ButtonEvent> {
    avr_device::interrupt::free(|cs| {
        if SELECT.borrow(cs).replace(false) {
            return Some(ButtonEvent::Select);
        }
        if UP.borrow(cs).replace(false) {
            return Some(ButtonEvent::Up);
        }
        if DOWN.borrow(cs).replace(false) {
            return Some(ButtonEvent::Down);
        }
        None
    })
}
