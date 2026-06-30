//! Interactive BB trajectory visualizer.
//!
//! Plots BB drop vs. downrange distance (0-100 m) for a shot fired parallel to
//! the ground, with live-adjustable parameters. Two curves are overlaid:
//!   * an accurate host-side `f64` forward-Euler simulation, and
//!   * the embedded `ballistic_calculator` (`f32` math) that actually runs on the
//!     device.
//! The divergence between them shows how well the embedded approximation holds up.

use ballistic_calculator::{calculate_drift, CalculatorConfiguration, Float};
use eframe::egui;
use egui_plot::{Legend, Line, Plot, PlotPoints};

/// 6 mm BB.
const BB_RADIUS_M: f64 = 0.003;
const GRAVITY: f64 = 9.81;
/// Muzzle height above the ground (shooter holding the gun), metres.
const START_HEIGHT_M: f64 = 1.8;

/// Adjustable inputs. Elevation is fixed at 0 (fired parallel to the ground).
struct Params {
    bb_weight_g: f64,       // grams
    muzzle_energy_j: f64,   // Joules
    magnus_spin_rad_s: f64, // hop-up backspin (rad/s)
    air_density: f64,       // kg/m^3
    drag_cd: f64,           // dimensionless
}

impl Default for Params {
    fn default() -> Self {
        // Mirrors CalculatorConfiguration::default(): 0.4 g BB, 1.9 J, 15 rad/s,
        // air density 1.8, drag 0.43.
        Self {
            bb_weight_g: 0.40,
            muzzle_energy_j: 1.9,
            magnus_spin_rad_s: 15.0,
            air_density: 1.8,
            drag_cd: 0.43,
        }
    }
}

impl Params {
    fn mass_kg(&self) -> f64 {
        (self.bb_weight_g / 1000.0).max(1e-6)
    }

    fn muzzle_velocity(&self) -> f64 {
        (2.0 * self.muzzle_energy_j / self.mass_kg()).sqrt()
    }
}

struct SimResult {
    /// `[range_m, height_m]` trajectory samples.
    pts: Vec<[f64; 2]>,
    /// `[range_m, time_ms]` time-of-flight samples (same cadence as `pts`).
    tof: Vec<[f64; 2]>,
}

/// Accurate trajectory: forward-Euler integration in the vertical plane.
fn simulate_f64(p: &Params) -> SimResult {
    let r = BB_RADIUS_M;
    let area = std::f64::consts::PI * r * r;
    let m = p.mass_kg();

    let mut x = 0.0_f64;
    let mut y = START_HEIGHT_M;
    let mut vx = p.muzzle_velocity();
    let mut vy = 0.0_f64;

    // Integration step in milliseconds; physics equations use dt_s (seconds).
    let dt_ms = 0.5_f64;
    let dt_s = dt_ms * 1e-3;
    let mut t_ms = 0.0_f64;
    let sample_step = 0.5_f64;
    let mut next_sample = sample_step;

    let mut pts = vec![[0.0, START_HEIGHT_M]];
    let mut tof = vec![[0.0, 0.0_f64]];
    while x < 100.0 && t_ms < 30_000.0 {
        let v = (vx * vx + vy * vy).sqrt().max(1e-9);

        // Drag: Fd = 0.5 * Cd * rho * A * v^2, opposing the velocity vector.
        let drag_accel = 0.5 * p.drag_cd * p.air_density * area * v * v / m;
        let ax_drag = -drag_accel * vx / v;
        let ay_drag = -drag_accel * vy / v;

        // Magnus (mirrors the crate's form 0.5 * rho * r^3 * v * omega), acting
        // perpendicular to velocity; backspin lifts the BB (+y for +x motion).
        let magnus_accel = 0.5 * p.air_density * r * r * r * v * p.magnus_spin_rad_s / m;
        let ax_mag = magnus_accel * (-vy / v);
        let ay_mag = magnus_accel * (vx / v);

        vx += (ax_drag + ax_mag) * dt_s;
        vy += (ay_drag + ay_mag - GRAVITY) * dt_s;
        x += vx * dt_s;
        y += vy * dt_s;
        t_ms += dt_ms;

        if x >= next_sample {
            pts.push([x, y]);
            tof.push([x, t_ms]);
            next_sample += sample_step;
        }
        // Stop once the BB has hit the ground.
        if y < 0.0 {
            break;
        }
    }
    SimResult { pts, tof }
}

struct EmbeddedSimResult {
    pts: Vec<[f64; 2]>,
    /// `[range_m, time_ms]` from the embedded calculator.
    tof: Vec<[f64; 2]>,
}

/// The embedded calculator's view of the trajectory: call `calculate_drift` for
/// each whole-metre range and read back the cumulative vertical drift and TOF.
fn simulate_embedded(p: &Params) -> EmbeddedSimResult {
    let config = CalculatorConfiguration {
        magnus_effect_angular_velocity: p.magnus_spin_rad_s as Float,
        bb_weight: p.mass_kg() as Float,
        muzzle_energy: p.muzzle_energy_j as Float,
        angle_of_elevation: 0.0,
        air_density: p.air_density as Float,
        drag_coefficient: p.drag_cd as Float,
    };

    let mut pts = vec![[0.0, START_HEIGHT_M]];
    let mut tof = vec![[0.0, 0.0_f64]];
    for range in 1..=100 {
        let drift = calculate_drift(&config, range as Float);
        pts.push([range as f64, START_HEIGHT_M + drift.drift_y as f64]);
        tof.push([range as f64, drift.time_of_flight as f64]);
    }
    EmbeddedSimResult { pts, tof }
}

struct App {
    params: Params,
}

impl Default for App {
    fn default() -> Self {
        Self {
            params: Params::default(),
        }
    }
}

impl eframe::App for App {
    fn update(&mut self, ctx: &egui::Context, _frame: &mut eframe::Frame) {
        egui::SidePanel::left("params")
            .resizable(false)
            .default_width(260.0)
            .show(ctx, |ui| {
                ui.heading("Parameters");
                ui.label(format!(
                    "Fired parallel to the ground (elevation = 0) from {START_HEIGHT_M} m."
                ));
                ui.separator();

                ui.add(
                    egui::Slider::new(&mut self.params.bb_weight_g, 0.12..=0.50)
                        .text("BB weight (g)"),
                );

                ui.add(
                    egui::Slider::new(&mut self.params.muzzle_energy_j, 0.1..=5.0)
                        .text("Muzzle energy (J)"),
                );
                let m = self.params.mass_kg();
                let mut vel = (2.0 * self.params.muzzle_energy_j / m).sqrt();
                if ui
                    .add(
                        egui::DragValue::new(&mut vel)
                            .speed(1.0)
                            .range(1.0..=300.0)
                            .suffix(" m/s"),
                    )
                    .changed()
                {
                    self.params.muzzle_energy_j = 0.5 * m * vel * vel;
                }
                ui.label(format!(
                    "muzzle velocity ≈ {:.0} m/s ({:.0} fps)",
                    self.params.muzzle_velocity(),
                    self.params.muzzle_velocity() * 3.281
                ));

                ui.separator();
                ui.add(
                    egui::Slider::new(&mut self.params.magnus_spin_rad_s, 0.0..=300.0)
                        .text("Hop-up spin (rad/s)"),
                );

                ui.separator();
                ui.label("Environment");
                ui.add(
                    egui::Slider::new(&mut self.params.air_density, 0.5..=3.0)
                        .text("Air density (kg/m³)"),
                );
                ui.add(egui::Slider::new(&mut self.params.drag_cd, 0.1..=1.0).text("Drag Cd"));

                ui.separator();
                if ui.button("Reset to defaults").clicked() {
                    self.params = Params::default();
                }
            });

        egui::CentralPanel::default().show(ctx, |ui| {
            let sim = simulate_f64(&self.params);
            let emb = simulate_embedded(&self.params);

            let available = ui.available_height();
            let traj_height = available * 0.65;
            let tof_height = available * 0.30;

            ui.heading("BB trajectory — height above ground vs. range");
            Plot::new("trajectory")
                .legend(Legend::default())
                .x_axis_label("range (m)")
                .y_axis_label("height (m, 0 = ground)")
                .include_x(0.0)
                .include_x(100.0)
                .include_y(0.0)
                .height(traj_height)
                .show(ui, |plot_ui| {
                    plot_ui.line(Line::new(PlotPoints::from(sim.pts)).name("f64 reference"));
                    plot_ui.line(Line::new(PlotPoints::from(emb.pts)).name("embedded f32"));
                });

            ui.heading("Time of flight vs. range");
            Plot::new("tof")
                .legend(Legend::default())
                .x_axis_label("range (m)")
                .y_axis_label("time of flight (ms)")
                .include_x(0.0)
                .include_x(100.0)
                .include_y(0.0)
                .height(tof_height)
                .show(ui, |plot_ui| {
                    plot_ui.line(Line::new(PlotPoints::from(sim.tof)).name("TOF f64 reference"));
                    plot_ui.line(Line::new(PlotPoints::from(emb.tof)).name("TOF embedded f32"));
                });
        });
    }
}

fn main() -> eframe::Result<()> {
    let native_options = eframe::NativeOptions::default();
    eframe::run_native(
        "Exacto — BB Trajectory Visualizer",
        native_options,
        Box::new(|_cc| Ok(Box::new(App::default()))),
    )
}
