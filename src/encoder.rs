#![allow(dead_code)]

use embedded_hal::digital::InputPin;


/// A simple rotary encoder with optional push button.
pub struct RotaryEncoder<A, B, SW>
where
    A: InputPin,
    B: InputPin,
    SW: InputPin,
{
    pin_a: A,
    pin_b: B,
    pin_sw: SW,
    last_a: bool,
    position: i32,
}

impl<A, B, SW> RotaryEncoder<A, B, SW>
where
    A: InputPin,
    B: InputPin,
    SW: InputPin,
{
    pub fn new(mut pin_a: A, pin_b: B, pin_sw: SW) -> Result<Self, A::Error> {
        let initial_a = pin_a.is_high()?;
        Ok(Self {
            pin_a,
            pin_b,
            pin_sw,
            last_a: initial_a,
            position: 0,
        })
    }

    /// Call regularly to process rotary encoder rotation.
    pub fn update(&mut self) -> Result<(), A::Error> {
        let current_a = self.pin_a.is_high()?;

        if current_a != self.last_a {
            if current_a {
                let b = self.pin_b.is_high().unwrap();
                if b {
                    self.position -= 1;
                } else {
                    self.position += 1;
                }
            }
            self.last_a = current_a;
        }

        Ok(())
    }

    /// Returns the current position counter.
    pub fn position(&self) -> i32 {
        self.position
    }

    /// Resets the position counter to 0.
    pub fn reset(&mut self) {
        self.position = 0;
    }

    /// Returns true if the button is pressed.
    pub fn is_pressed(&mut self) -> Result<bool, SW::Error> {
        self.pin_sw.is_low()
    }
}
