use ballistic_calculator::{calculate_drift, CalculatorConfiguration, Float, PI};
use embedded_graphics::prelude::Point;

#[derive(PartialEq, Clone)]
pub struct Sight {
    pub x_zero: i8,
    pub y_zero: i8,
    pub battery_power: u8,
    pub range: u8,
    pub last_range: u8,
    pub configuration: CalculatorConfiguration,
    pub drift: Point,
    pub time_of_flight_ms: u16,
}

impl Sight {
    pub fn point_of_aim(&self) -> Point {
        Point::new((64 + self.x_zero) as i32, (96 / 2 + self.y_zero) as i32)
    }

    pub fn calculated_point_of_impact(&self) -> Point {
        self.point_of_aim() + self.drift
    }

    pub fn update(&mut self) {
        if self.range == self.last_range {
            return;
        }
        let drift = calculate_drift(&self.configuration, self.range as Float);
        self.drift = Point::new(
            to_pixels(self.range, drift.drift_x, 128),
            to_pixels(self.range, -drift.drift_y, 96),
        );
        self.time_of_flight_ms = drift.time_of_flight as u16;
        self.last_range = self.range;
    }
}

fn to_pixels(range: u8, drift: Float, axis_size: u8) -> i32 {
    (drift * axis_size as Float / (PI * range as Float / 4.0)) as i32
}
