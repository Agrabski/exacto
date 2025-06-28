use embedded_graphics::prelude::Point;

#[derive(PartialEq, Clone, Copy)]
pub struct Sight {
    pub x_zero: i16,
    pub y_zero: i16,
    pub battery_power: u8,
    pub range: u8
}

impl Sight {
    pub fn point_of_aim(&self) -> Point {
        Point::new((128/2+ self.x_zero) as i32, (96/2+ self.y_zero) as i32)
    }

    pub fn calculated_point_of_impact(&self)-> Point {
      self.point_of_aim() + Point::new(0, self.range as i32 / 2)
    }
}
