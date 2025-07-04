use core::{f32, ops::{Div, Mul}};

pub trait Float: Copy + PartialOrd + From<f32> + Mul<Output = Self> + Div<Output = Self> + Sized {
    fn sqrt(self) -> Self;
}

impl Float for f32 {
    fn sqrt(self) -> Self {
        if self < 0.0 {
            return f32::NAN; // no sqrt for negative numbers in real numbers
        }
        if self == 0.0 {
            return 0.0;
        }

        // Initial guess (good enough for most ranges)
        let mut x = self * 0.5;

        // Perform 5 iterations of Newton-Raphson
        for _ in 0..5 {
            x = 0.5 * (x + self / x);
        }

        x
    }
}

impl Float for f64 {
    fn sqrt(self) -> Self {
        if self < 0.0 {
            return 0.0; // no sqrt for negative numbers in real numbers
        }
        if self == 0.0 {
            return 0.0;
        }

        // Initial guess (good enough for most ranges)
        let mut x = self * 0.5;

        // Perform 5 iterations of Newton-Raphson
        for _ in 0..5 {
            x = 0.5 * (x + self / x);
        }

        x
    }
}

pub fn velocity_from_kinetic_energy<TNumber: Float>(energy: TNumber, mass: TNumber) -> TNumber {
    let velocity_mps = (TNumber::from(2.0) * energy / mass).sqrt();
    velocity_mps
}

pub fn drag_force<TNumber: Float>(
    velocity: TNumber,
    drag_coefficient: TNumber,
    air_density: TNumber,
    area: TNumber,
) -> TNumber {
    // Drag force formula: Fd = 0.5 * Cd * rho * A * v^2
    let v_squared = velocity * velocity;
    
        TNumber::from(0.5) * drag_coefficient * air_density * area * v_squared
    
}

pub fn magnus_force<TNumber: Float>(
    velocity: TNumber,
    angular_velocity: TNumber,
    air_density: TNumber,
    radius: TNumber,
) -> TNumber {
    
        TNumber::from(0.5)
            * air_density
            * (radius * radius * radius)
            * velocity
            * angular_velocity
}
