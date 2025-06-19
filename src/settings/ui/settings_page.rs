use embedded_graphics::prelude::Point;

use crate::settings::{
    rendering::{SettingsRenderer, TextType},
    ui::{ClickResult, Menu},
    SettingsMenu,
};

pub enum SettingsPageClickResult {
    LoseFocus,
    GainFocus,
    Exit,
    Navigate(SettingsMenu),
    None,
}

pub trait SettingsPage {
    fn controls(&self) -> [Option<& dyn SettingsPageControl>;6];
}

pub struct NavigationButton {
    pub label: &'static str,
    pub action: fn() -> SettingsPageClickResult,
}

impl SettingsPageControl for NavigationButton {
    fn handle_input(&self, _sight: &mut crate::sight::Sight, _input: crate::settings::RotorInput) {
        // Handle input for the navigation button
    }

    fn handle_click(&self, _sight: &mut crate::sight::Sight) -> SettingsPageClickResult {
        // Execute the action associated with the button
        (self.action)()
    }

    fn draw(
        &self,
        display: &mut dyn SettingsRenderer,
        _sight: &crate::sight::Sight,
        row: u8,
        active: bool,
    ) {
        display.render_text(self.label, row, {
            if active {
                TextType::Highlighted
            } else {
                TextType::Normal
            }
        });
    }
}

pub trait SettingsPageControl {
    fn handle_input(&self, _sight: &mut crate::sight::Sight, _input: crate::settings::RotorInput);

    fn handle_click(&self, _sight: &mut crate::sight::Sight) -> SettingsPageClickResult;

    fn draw(
        &self,
        _display: &mut dyn crate::settings::rendering::SettingsRenderer,
        _sight: &crate::sight::Sight,
        row: u8,
        active: bool,
    );
}

pub struct SettingsPageState {
    pub active_control: usize,
    pub focused: bool,
}
impl SettingsPageState {
    pub(crate) fn new() -> Self {
        Self {
            active_control: 0,
            focused: false,
        }
    }
}

impl<T: SettingsPage> Menu for T {
    type TState = SettingsPageState;

    fn handle_input(
        &self,
        _state: &mut Self::TState,
        _sight: &mut crate::sight::Sight,
        _input: crate::settings::RotorInput,
    ) {
        // Handle input for the settings page
    }

    fn handle_click(
        &self,
        _state: &mut Self::TState,
        _sight: &mut crate::sight::Sight,
    ) -> crate::settings::ui::ClickResult<crate::settings::SettingsMenu> {
        // Handle click events for the settings page
        crate::settings::ui::ClickResult::None
    }

    fn draw(
        &self,
        _state: &Self::TState,
        _display: &mut dyn crate::settings::rendering::SettingsRenderer,
        _sight: &crate::sight::Sight,
    ) {
        let controls = self.controls();
        for (index, control) in controls.iter().enumerate() {
            let active = index == _state.active_control;
            if let Some(control) = control {
                control.draw(_display, _sight, index as u8, active);
            }
        }
    }
}
