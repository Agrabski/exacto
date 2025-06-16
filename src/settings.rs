mod rendering;

use crate::{encoder::RotaryEncoder, settings::rendering::SettingsRenderer};
use core::fmt::Debug;
use embedded_graphics::{
    mono_font::{ascii::FONT_6X10, MonoTextStyle},
    pixelcolor::Rgb565,
    prelude::{DrawTarget, Point, RgbColor},
    text::{renderer, Text},
};
use embedded_graphics_core::Drawable;
use embedded_hal::digital::InputPin;

pub struct SettingsState {
    current_menu: Option<SettingsMenu>,
    rotor_position: i32,
}

enum RotorInput {
    Up,
    Down,
}

enum SettingsMenu {
    MainMenu(MainSubMenu),
}

struct MainSubMenu {
    selected_option: i8,
}

impl MainSubMenu {
    pub fn new() -> Self {
        Self { selected_option: 0 }
    }
}

impl SubMenu for MainSubMenu {
    fn handle_input(&mut self, input: RotorInput) {
        self.selected_option = match input {
            RotorInput::Up => self.selected_option + 1,
            RotorInput::Down => self.selected_option - 1,
        };
        if self.selected_option < 0 {
            self.selected_option = 3;
        } else {
            self.selected_option = self.selected_option % 4;
        }
    }

    fn handle_click(&mut self) -> Option<SettingsMenu> {
        // Handle click and return next menu if applicable
        None
    }

    fn draw<DI>(&self, display: &mut DI)
    where
        DI: SettingsRenderer,
    {
        let pick_option = |index: i8| {
            if index == self.selected_option {
                rendering::TextType::Highlighted
            } else {
                rendering::TextType::Normal
            }
        };
        display.render_text("Main Menu", 0, rendering::TextType::Normal);
        display.render_text("Option 1", 1, pick_option(0));
        display.render_text("Option 2", 2, pick_option(1));

        display.render_text("Option 3", 3, pick_option(2));

        display.render_text("Option 4", 4, pick_option(3));
    }
}

trait SubMenu {
    fn draw<DI>(&self, display: &mut DI)
    where
        DI: SettingsRenderer;
    fn handle_input(&mut self, input: RotorInput);
    fn handle_click(&mut self) -> Option<SettingsMenu>;
}

impl SettingsMenu {
    fn handle_input(&mut self, _input: RotorInput) {
        match self {
            SettingsMenu::MainMenu(sub_menu) => sub_menu.handle_input(_input),
        }
    }

    fn handle_click(&mut self) -> Option<SettingsMenu> {
        // Handle click and return next menu if applicable
        None
    }
}

impl SettingsState {
    pub fn new() -> Self {
        Self {
            current_menu: None,
            rotor_position: 0,
        }
    }

    pub fn is_open(&self) -> bool {
        self.current_menu.is_some()
    }

    pub fn update<A, B, SW>(&mut self, encoder: &mut RotaryEncoder<A, B, SW>) -> bool
    where
        A: InputPin,
        B: InputPin,
        SW: InputPin,
    {
        if encoder.is_pressed().is_ok_and(|pressed| pressed) {
            self.rotor_position = encoder.position();
            self.handle_press()
        } else {
            let position = encoder.position();
            let change = match (self.rotor_position, position) {
                (a, b) if a > b => RotorInput::Up,
                (a, b) if a < b => RotorInput::Down,
                _ => return false,
            };
            self.rotor_position = position;
            self.handle_rotation(change)
        }
    }

    pub fn draw<DI>(&self, display: &mut DI)
    where
        DI: DrawTarget<Color = Rgb565, Error: Debug>,
    {
        if let Some(menu) = &self.current_menu {
            let mut renderer = rendering::DefaultSettingsRenderer { display };
            match menu {
                SettingsMenu::MainMenu(sub_menu) => {
                    sub_menu.draw(&mut renderer);
                }
            }
        }
    }

    fn handle_rotation(&mut self, change: RotorInput) -> bool {
        if let Some(menu) = self.current_menu.as_mut() {
            menu.handle_input(change);
            true
        } else {
            false
        }
    }

    fn handle_press(&mut self) -> bool {
        if let Some(menu) = self.current_menu.as_mut() {
            if let Some(next_menu) = menu.handle_click() {
                self.current_menu = Some(next_menu);
            } else {
                self.current_menu = None;
            }
        } else {
            self.current_menu = Some(SettingsMenu::MainMenu(MainSubMenu::new()));
        }
        true
    }
}
