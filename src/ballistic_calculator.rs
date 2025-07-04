use crate::physics::{drag_force, magnus_force, velocity_from_kinetic_energy};

type Float = f64;

const PI: Float = 3.141592653;

#[derive(Debug, Clone, PartialEq, Copy)]
pub struct CalculatorConfiguration {
    pub gravity: Float,                        // m/s^2
    pub air_density: Float,                    // kg/m^3
    pub drag_coefficient: Float,               // dimensionless
    pub magnus_effect_angular_velocity: Float, // rad/s
    pub bb_weight: Float,                      // grams
    pub bb_diameter: Float,                    // mm
    pub muzzle_energy: Float,                  // Joules
    pub angle_of_elevation: Float,
    pub simulation_step: Float,
}

impl Default for CalculatorConfiguration {
    fn default() -> Self {
        CalculatorConfiguration {
            gravity: (9.81),                        // m/s^2
            air_density: (1.8),                     // kg/m^3 at sea level
            drag_coefficient: 0.43,                 // typical for a spinning sphere
            magnus_effect_angular_velocity: (15.0), // rad/s
            bb_weight: (0.4 / 1000.0),
            bb_diameter: (6.0) / 1000.0, // 6 mm
            muzzle_energy: (1.9),        // 1.5 Joules
            angle_of_elevation: 0.0,
            simulation_step: (1.0), // 10 cm step
        }
    }
}

#[derive(Debug, Clone, PartialEq, Copy)]
pub struct BBDrift {
    pub drift_x: Float, // meters
    pub drift_y: Float, // meters
}

impl Default for BBDrift {
    fn default() -> Self {
        BBDrift {
            drift_x: (0.0),
            drift_y: (0.0),
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
        position: (0.0),
        time: (0.0),
        mass: config.bb_weight,
        kinetic_energy: config.muzzle_energy,
        rotation: config.magnus_effect_angular_velocity,
    };

    let mut drift_x = (0.0);
    let mut drift_y = (0.0);

    let step = config.simulation_step;
    let mut traveled = (0.0);

    while traveled < range && state.kinetic_energy > 0.0 {
        let v = state.velocity();
        if v <= 0.0 {
            break;
        }

        // Drag force: Fd = 0.5 * Cd * rho * A * v^2
        let radius = config.bb_diameter / 2.0; // mm to meters
        let area = PI * radius * radius;
        let drag_force = drag_force(v, config.drag_coefficient, config.air_density, area);

        // Magnus force (simplified): Fm = S * v x w, S = 0.5 * rho * A * r
        let magnus_force =
            magnus_force(state.velocity(), state.rotation, config.air_density, radius);

        // Assume drag acts along -v, Magnus acts perpendicular (in x)
        let dt = (step / v).abs();
        let dt_time = dt;

        // Update drift_x (Magnus effect, sideways)
        let accel_x = magnus_force / state.mass;
        drift_x = drift_x + (accel_x * dt_time * dt_time) / 2.0;

        // Update drift_y (gravity, vertical)
        let accel_y = -config.gravity;
        drift_y = drift_y + (accel_y * dt_time * dt_time / 2.0);

        // Update kinetic energy (drag)
        let work_drag = drag_force * step;
        let new_ke = (state.kinetic_energy - work_drag).max(0.0);
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
