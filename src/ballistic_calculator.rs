use embedded_graphics::prelude::Angle;
use simple_si_units::{
    base::{Distance, Mass, Time},
    mechanical::{Acceleration, AngularVelocity, Density, Energy, Velocity},
};

use crate::physics::{drag_force, magnus_force, EnergyPhysics};

type Float = f64;

const PI: Float = 3.141592653;

#[derive(Debug, Clone, PartialEq, Copy)]
pub struct CalculatorConfiguration {
    pub gravity: Acceleration<Float>,                           // m/s^2
    pub air_density: Density<Float>,                            // kg/m^3
    pub drag_coefficient: Float,                                // dimensionless
    pub magnus_effect_angular_velocity: AngularVelocity<Float>, // rad/s
    pub bb_weight: Mass<f64>,                                   // grams
    pub bb_diameter: Distance<Float>,                           // mm
    pub muzzle_energy: Energy<Float>,                           // Joules
    pub angle_of_elevation: Angle,
    pub simulation_step: Distance<Float>,
}

impl Default for CalculatorConfiguration {
    fn default() -> Self {
        CalculatorConfiguration {
            gravity: Acceleration::from_meters_per_second_squared(9.81), // m/s^2
            air_density: Density::from_kgpm3(1.8),                       // kg/m^3 at sea level
            drag_coefficient: 0.43, // typical for a spinning sphere
            magnus_effect_angular_velocity: AngularVelocity::from_radians_per_second(15.0), // rad/s
            bb_weight: Mass::from_g(0.4), // 177 grams
            bb_diameter: Distance::from_mm(6.0), // 6 mm
            muzzle_energy: Energy::from_J(1.9), // 1.5 Joules
            angle_of_elevation: Angle::from_degrees(0.0),
            simulation_step: Distance::from_meters(1.0), // 10 cm step
        }
    }
}

#[derive(Debug, Clone, PartialEq, Copy)]
pub struct BBDrift {
    pub drift_x: Distance<Float>, // meters
    pub drift_y: Distance<Float>, // meters
}

impl Default for BBDrift {
    fn default() -> Self {
        BBDrift {
            drift_x: Distance::from_meters(0.0),
            drift_y: Distance::from_meters(0.0),
        }
    }
}

impl BBDrift {
    pub fn new(drift_x: Distance<Float>, drift_y: Distance<Float>) -> Self {
        BBDrift { drift_x, drift_y }
    }
}

pub fn calculate_drift(
    config: &CalculatorConfiguration,
    range: Distance<Float>, // meters
) -> BBDrift {
    let mut state = BBStateVector {
        position: Distance::from_meters(0.0),
        time: Time::from_seconds(0.0),
        mass: config.bb_weight,
        kinetic_energy: config.muzzle_energy,
        rotation: config.magnus_effect_angular_velocity,
    };

    let mut drift_x = Distance::from_meters(0.0);
    let mut drift_y = Distance::from_meters(0.0);

    let step = config.simulation_step;
    let mut traveled = Distance::from_meters(0.0);

    while traveled < range && state.kinetic_energy.J > 0.0 {
        let v = state.velocity();
        if v.mps <= 0.0 {
            break;
        }

        // Drag force: Fd = 0.5 * Cd * rho * A * v^2
        let radius = config.bb_diameter / 2.0; // mm to meters
        let area = PI * radius * radius;
        let drag_force = drag_force(v, config.drag_coefficient, config.air_density, area);

        // Magnus force (simplified): Fm = S * v x w, S = 0.5 * rho * A * r
        let magnus_force = magnus_force(state.velocity(), state.rotation, config.air_density, radius);

        // Assume drag acts along -v, Magnus acts perpendicular (in x)
        let dt = (step / v).s.abs();
        let dt_time = Time::from_seconds(dt);

        // Update drift_x (Magnus effect, sideways)
        let accel_x = magnus_force / state.mass;
        drift_x = drift_x + (accel_x * dt_time * dt_time) / 2.0;

        // Update drift_y (gravity, vertical)
        let accel_y = -config.gravity;
        drift_y = drift_y + (accel_y * dt_time * dt_time / 2.0);

        // Update kinetic energy (drag)
        let work_drag = drag_force * step;
        let new_ke = (state.kinetic_energy - work_drag).J.max(0.0);
        state.kinetic_energy = Energy::from_J(new_ke);

        // Advance
        state.position = state.position + step;
        state.time = state.time + dt_time;
        traveled = traveled + step;
    }

    BBDrift::new(drift_x, drift_y)
}

struct BBStateVector {
    position: Distance<Float>, // meters
    time: Time<Float>,
    mass: Mass<Float>,
    kinetic_energy: Energy<Float>,
    rotation: AngularVelocity<Float>, // rad/s
}

impl BBStateVector {
    pub fn velocity(&self) -> Velocity<Float> {
        self.kinetic_energy.velocity_from_kinetic_energy(self.mass)
    }
}
