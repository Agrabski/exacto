use embedded_graphics::prelude::Point;
use simple_si_units::base::Distance;

use crate::ballistic_calculator::{calculate_drift, BBDrift, CalculatorConfiguration};

#[derive(PartialEq, Clone, Copy)]
pub struct Sight {
    pub x_zero: i16,
    pub y_zero: i16,
    pub battery_power: u8,
    pub range: u8,
    pub last_range: u8,
    pub configuration: CalculatorConfiguration,
    pub drift: BBDrift,
}

impl Sight {
    pub fn point_of_aim(&self) -> Point {
        Point::new(
            (128 / 2 + self.x_zero) as i32,
            (96 / 2 + self.y_zero) as i32,
        )
    }

    pub fn calculated_point_of_impact(&self) -> Point {
        self.point_of_aim() + Point::new(to_pixels(self.range, self.drift.drift_x, 128), to_pixels(self.range, self.drift.drift_y, 96))
    }

    pub fn update(&mut self) {
        if self.range == self.last_range {
            return;
        }
        self.drift = calculate_drift(
            &self.configuration,
            Distance::from_meters(self.range.into()),
        );
        self.last_range = self.range;
    }
}

fn to_pixels(range: u8, drift: Distance<f64>, axis_size :u8) -> i32 {
    (drift.to_meters() * axis_size as f64/ (3.14* (range as f64) /4.0)) as i32
}
