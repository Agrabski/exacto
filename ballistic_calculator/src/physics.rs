use crate::Float;

pub fn velocity_from_kinetic_energy(energy: Float, mass: Float) -> Float {
    libm::sqrtf(2.0 * energy / mass)
}

pub fn drag_force(
    velocity: Float,
    drag_coefficient: Float,
    air_density: Float,
    area: Float,
) -> Float {
    // Drag force formula: Fd = 0.5 * Cd * rho * A * v^2
    let v_squared = velocity * velocity;
    0.5 * drag_coefficient * air_density * area * v_squared
}

pub fn magnus_force(
    velocity: Float,
    angular_velocity: Float,
    air_density: Float,
    radius: Float,
) -> Float {
    0.5 * air_density * (radius * radius * radius) * velocity * angular_velocity
}
