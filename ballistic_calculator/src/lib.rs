#![cfg_attr(not(test), no_std)]
pub mod physics;

use crate::physics::{drag_force, magnus_force, velocity_from_kinetic_energy};

pub type Float = f32;

pub const PI: Float = core::f32::consts::PI;
const BB_DIAMETER: Float = 0.006;
const SIMULATION_STEP: Float = 1.0;
const GRAVITY: Float = 9.81;
const AIR_DENSITY: Float = 1.8;
const DRAG_COEFFICIENT: Float = 0.43;

#[derive(Debug, Clone, PartialEq)]
pub struct CalculatorConfiguration {
    pub magnus_effect_angular_velocity: Float, // rad/s
    pub bb_weight: Float,                      // grams
    pub muzzle_energy: Float,                  // Joules
    pub angle_of_elevation: Float,
    pub air_density: Float,      // kg/m^3
    pub drag_coefficient: Float, // dimensionless
}

impl Default for CalculatorConfiguration {
    fn default() -> Self {
        CalculatorConfiguration {
            magnus_effect_angular_velocity: 15.0, // rad/s
            bb_weight: 0.00040,
            muzzle_energy: 1.9, // Joules
            angle_of_elevation: 0.0,
            air_density: AIR_DENSITY,
            drag_coefficient: DRAG_COEFFICIENT,
        }
    }
}

#[derive(Debug, Clone, PartialEq)]
pub struct BBDrift {
    pub drift_x: Float,        // meters
    pub drift_y: Float,        // meters
    pub time_of_flight: Float, // milliseconds
}

impl Default for BBDrift {
    fn default() -> Self {
        BBDrift {
            drift_x: 0.0,
            drift_y: 0.0,
            time_of_flight: 0.0,
        }
    }
}

impl BBDrift {
    pub fn new(drift_x: Float, drift_y: Float, time_of_flight: Float) -> Self {
        BBDrift {
            drift_x,
            drift_y,
            time_of_flight,
        }
    }
}

pub fn calculate_drift(
    config: &CalculatorConfiguration,
    range: Float, // meters
) -> BBDrift {
    let mut state = BBStateVector {
        position: 0.0,
        time: 0.0,
        mass: config.bb_weight,
        kinetic_energy: config.muzzle_energy,
        rotation: config.magnus_effect_angular_velocity,
    };

    let mut drift_x = 0.0;
    let mut drift_y = 0.0;

    let step = SIMULATION_STEP;
    let mut traveled = 0.0;

    while traveled < range && state.kinetic_energy > 0.0 {
        let v = state.velocity();
        if v <= 0.0 {
            break;
        }

        // Drag force: Fd = 0.5 * Cd * rho * A * v^2
        let radius = BB_DIAMETER / 2.0; // mm to meters
        let area = PI * radius * radius;
        let drag_force = drag_force(v, config.drag_coefficient, config.air_density, area);

        // Magnus force (simplified): Fm = S * v x w, S = 0.5 * rho * A * r
        let magnus_force =
            magnus_force(state.velocity(), state.rotation, config.air_density, radius);

        // Assume drag acts along -v, Magnus acts perpendicular (in x)
        let dt_s = libm::fabsf(step / v); // seconds, used for physics
        let dt_ms = dt_s * 1000.0;        // milliseconds, used for time tracking

        //todo: wind, tilt
        let accel_x = 0.0;
        drift_x = drift_x + (accel_x * dt_s * dt_s) / 2.0;

        // Update drift_y (gravity, vertical)
        let accel_y = (magnus_force / state.mass) - GRAVITY;
        drift_y = drift_y + (accel_y * dt_s * dt_s / 2.0);

        // Update kinetic energy (drag)
        let work_drag = drag_force * step;
        let new_ke = (state.kinetic_energy - work_drag).max(0.0);
        state.kinetic_energy = new_ke;

        // Advance
        state.position = state.position + step;
        state.time = state.time + dt_ms;
        traveled = traveled + step;
    }

    BBDrift::new(drift_x, drift_y, state.time)
}

struct BBStateVector {
    position: Float, // meters
    time: Float,
    mass: Float,
    kinetic_energy: Float,
    rotation: Float, // rad/s
}

impl BBStateVector {
    pub fn velocity(&self) -> Float {
        velocity_from_kinetic_energy(self.kinetic_energy, self.mass)
    }
}

#[cfg(test)]
mod tests {
    use super::*;

    fn make_config() -> CalculatorConfiguration {
        CalculatorConfiguration {
            magnus_effect_angular_velocity: 10.0,
            bb_weight: 0.0004,
            muzzle_energy: 1.5,
            angle_of_elevation: 0.0,
            air_density: AIR_DENSITY,
            drag_coefficient: DRAG_COEFFICIENT,
        }
    }

    #[test]
    fn test_calculate_drift_basic() {
        let config = make_config();
        let _drift = calculate_drift(&config, 10.0);
    }

    #[test]
    fn test_zero_range() {
        let config = make_config();
        let drift = calculate_drift(&config, 0.0);
        assert_eq!(drift, BBDrift::default());
    }

    #[test]
    fn test_zero_energy() {
        let mut config = make_config();
        config.muzzle_energy = 0.0;
        let drift = calculate_drift(&config, 10.0);
        assert_eq!(drift, BBDrift::default());
    }

    #[test]
    fn test_negative_range() {
        let config = make_config();
        let drift = calculate_drift(&config, -5.0);
        assert_eq!(drift, BBDrift::default());
    }

    #[test]
    fn test_large_range() {
        let config = make_config();
        let _drift = calculate_drift(&config, 1000.0);
        // Should not panic and should return a BBDrift
    }

    #[test]
    fn test_extreme_magnus() {
        let mut config = make_config();
        config.magnus_effect_angular_velocity = 10000.0;
        let _drift = calculate_drift(&config, 10.0);
    }

    #[test]
    fn test_default_config() {
        let config = CalculatorConfiguration::default();
        let _drift = calculate_drift(&config, 10.0);
    }

    #[test]
    fn test_default_config_range_1() {
        let config = CalculatorConfiguration::default();
        let drift = calculate_drift(&config, 1.0);
        let _value_x = drift.drift_x;
        let value_y = drift.drift_y;
        assert!(value_y.abs() < 10.0);
    }

    #[test]
    fn test_default_config_range_2() {
        let config = CalculatorConfiguration::default();
        let drift = calculate_drift(&config, 2.0);
        let _value_x = drift.drift_x;
        let value_y = drift.drift_y;
        assert!(value_y.abs() < 10.0);
    }

    #[test]
    fn test_no_panic_various_inputs() {
        let configs = [
            CalculatorConfiguration::default(),
            CalculatorConfiguration {
                magnus_effect_angular_velocity: 0.0,
                bb_weight: 1.0,
                muzzle_energy: 1.0,
                angle_of_elevation: 0.0,
                ..CalculatorConfiguration::default()
            },
            CalculatorConfiguration {
                magnus_effect_angular_velocity: -10.0,
                bb_weight: 1.0,
                muzzle_energy: 1.0,
                angle_of_elevation: 0.0,
                ..CalculatorConfiguration::default()
            },
        ];
        let ranges = [0.0, 1.0, 100.0, -1.0];
        for config in configs.iter() {
            for range in ranges.iter() {
                let _ = calculate_drift(config, *range);
            }
        }
    }
}
