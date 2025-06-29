use core::{f32, ops::Mul};

use arduino_hal::pac::TC2;
use simple_si_units::{
    base::Mass, geometry::Area, mechanical::{Density, Energy, Force, Velocity}, NumLike
};

pub trait Float:
    NumLike + Copy + PartialOrd + From<f32> + Mul<Output = Self> + Sized
{
    fn sqrt(self) -> Self;
}


impl Float for f32 {
    fn sqrt(self) -> Self {
        libm::sqrt(self.into()) as f32
    }
}

impl Float for f64 {
    fn sqrt(self) -> Self {
       libm::sqrt(self)
    }
}


pub trait EnergyPhysics<TNumber: Float> {
    fn velocity_from_kinetic_energy(&self, mass: Mass<TNumber>) -> Velocity<TNumber>;
}

impl<TNumber: Float> EnergyPhysics<TNumber> for Energy<TNumber> {
    fn velocity_from_kinetic_energy(&self, mass: Mass<TNumber>) -> Velocity<TNumber> {
        // Kinetic energy formula: KE = 0.5 * m * v^2
        // Rearranged to find velocity: v = sqrt(2 * KE / m)
        let velocity_mps = (TNumber::from(2.0) * self.to_J() / mass.kg).sqrt();
        Velocity::from_mps(velocity_mps)
    }
}


pub fn drag_force<TNumber : Float>(
    velocity: Velocity<TNumber>,
    drag_coefficient: TNumber,
    air_density: Density<TNumber>,
    area: Area<TNumber>,
) -> Force<TNumber> {
    // Drag force formula: Fd = 0.5 * Cd * rho * A * v^2
    let v_squared = velocity.mps * velocity.mps;
    0.5 * drag_coefficient * air_density * area * v_squared
}
