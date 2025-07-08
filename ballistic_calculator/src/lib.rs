#![cfg_attr(not(test), no_std)]
pub mod physics;

use crate::physics::{drag_force, magnus_force, velocity_from_kinetic_energy};
use fraction::Fraction;

pub type Float = Fraction<i32>;

pub const PI: Float = Float {
    numerator: 22,
    denominator: 7,
};
const BB_DIAMETER: Float = Float::new(6, 1000);
const SIMULATION_STEP: Float = Float::new(1, 1);
const GRAVITY: Float = Float::new(981, 100);
const AIR_DENSITY: Float = Float::new(18, 10);
const DRAG_COEFFICIENT: Float = Float::new(43, 100);

#[derive(Debug, Clone, PartialEq)]
pub struct CalculatorConfiguration {
    pub magnus_effect_angular_velocity: Float, // rad/s
    pub bb_weight: Float,                      // grams
    pub muzzle_energy: Float,                  // Joules
    pub angle_of_elevation: Float,
}

impl Default for CalculatorConfiguration {
    fn default() -> Self {
        CalculatorConfiguration {
            magnus_effect_angular_velocity: Float::from(15), // rad/s
            bb_weight: Float::new(4, 10000),
            muzzle_energy: Float::new(19, 10), // 1.5 Joules
            angle_of_elevation: Float::zero(),
        }
    }
}

#[derive(Debug, Clone, PartialEq)]
pub struct BBDrift {
    pub drift_x: Float, // meters
    pub drift_y: Float, // meters
}

impl Default for BBDrift {
    fn default() -> Self {
        BBDrift {
            drift_x: Float::zero(),
            drift_y: Float::zero(),
        }
    }
}

impl BBDrift {
    pub fn new(drift_x: Float, drift_y: Float) -> Self {
        BBDrift { drift_x, drift_y }
    }
}

pub fn calculate_drift(
    config: &CalculatorConfiguration,
    range: Float, // meters
) -> BBDrift {
    let mut state = BBStateVector {
        position: Float::from(0),
        time: Float::from(0),
        mass: config.bb_weight,
        kinetic_energy: config.muzzle_energy,
        rotation: config.magnus_effect_angular_velocity,
    };

    let mut drift_x = Float::zero();
    let mut drift_y = Float::zero();

    let step = SIMULATION_STEP;
    let mut traveled = Float::from(0);

    while traveled < range && state.kinetic_energy > Float::zero() {
        let v = state.velocity();
        if v <= Float::zero() {
            break;
        }

        // Drag force: Fd = 0.5 * Cd * rho * A * v^2
        let radius = BB_DIAMETER / 2; // mm to meters
        let area = PI * radius * radius;
        let drag_force = drag_force(v, DRAG_COEFFICIENT, AIR_DENSITY, area);

        // Magnus force (simplified): Fm = S * v x w, S = 0.5 * rho * A * r
        let magnus_force = magnus_force(state.velocity(), state.rotation, AIR_DENSITY, radius);

        // Assume drag acts along -v, Magnus acts perpendicular (in x)
        let dt = (step / v).abs();
        let dt_time = dt;

        // Update drift_x (Magnus effect, sideways)
        let accel_x = magnus_force / state.mass;
        drift_x = drift_x + (accel_x * dt_time * dt_time) / 2;

        // Update drift_y (gravity, vertical)
        let accel_y = -GRAVITY;
        drift_y = drift_y + (accel_y * dt_time * dt_time / 2);

        // Update kinetic energy (drag)
        let work_drag = drag_force * step;
        let new_ke = (state.kinetic_energy - work_drag).max(Float::zero());
        state.kinetic_energy = new_ke;

        // Advance
        state.position = state.position + step;
        state.time = state.time + dt_time;
        traveled = traveled + step;
    }

    BBDrift::new(drift_x, drift_y)
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
            magnus_effect_angular_velocity: Float::from(10),
            bb_weight: Float::new(4, 10000),
            muzzle_energy: Float::new(15, 10),
            angle_of_elevation: Float::zero(),
        }
    }

    #[test]
    fn test_calculate_drift_basic() {
        let config = make_config();
        let drift = calculate_drift(&config, Float::from(10));
    }

    #[test]
    fn test_zero_range() {
        let config = make_config();
        let drift = calculate_drift(&config, Float::zero());
        assert_eq!(drift, BBDrift::default());
    }

    #[test]
    fn test_zero_energy() {
        let mut config = make_config();
        config.muzzle_energy = Float::zero();
        let drift = calculate_drift(&config, Float::from(10));
        assert_eq!(drift, BBDrift::default());
    }


    #[test]
    fn test_negative_range() {
        let config = make_config();
        let drift = calculate_drift(&config, Float::from(-5));
        assert_eq!(drift, BBDrift::default());
    }

    #[test]
    fn test_large_range() {
        let config = make_config();
        let drift = calculate_drift(&config, Float::from(1000));
        // Should not panic and should return a BBDrift
    }

    #[test]
    fn test_extreme_magnus() {
        let mut config = make_config();
        config.magnus_effect_angular_velocity = Float::from(10000);
        let drift = calculate_drift(&config, Float::from(10));
    }

    #[test]
    fn test_default_config() {
        let config = CalculatorConfiguration::default();
        let drift = calculate_drift(&config, Float::from(10));
    }

    #[test]
    fn test_no_panic_various_inputs() {
        let configs = [
            CalculatorConfiguration::default(),
            CalculatorConfiguration {
                magnus_effect_angular_velocity: Float::from(0),
                bb_weight: Float::from(1),
                muzzle_energy: Float::from(1),
                angle_of_elevation: Float::zero(),
            },
            CalculatorConfiguration {
                magnus_effect_angular_velocity: Float::from(-10),
                bb_weight: Float::from(1),
                muzzle_energy: Float::from(1),
                angle_of_elevation: Float::zero(),
            },
        ];
        let ranges = [
            Float::from(0),
            Float::from(1),
            Float::from(100),
            Float::from(-1),
        ];
        for config in configs.iter() {
            for range in ranges.iter() {
                let _ = calculate_drift(config, *range);
            }
        }
    }
}
