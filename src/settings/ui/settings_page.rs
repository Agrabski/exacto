use embedded_graphics::prelude::Point;

use crate::{
    format_two_digit, format_two_digit_16,
    settings::{
        rendering::{SettingsRenderer, TextType},
        ui::{ClickResult, Menu},
        RotorInput, SettingsMenu,
    },
};

pub enum SettingsPageClickResult {
    LoseFocus,
    GainFocus,
    Exit,
    Navigate(SettingsMenu),
    None,
}

pub trait SettingsPage {
    fn controls(&self) -> [Option<&dyn SettingsPageControl>; 6];
}

pub struct NavigationButton {
    pub label: &'static str,
    pub action: fn() -> SettingsPageClickResult,
}

pub struct Slider {
    pub label: &'static str,
    pub min: i16,
    pub max: i16,
    pub on_change: fn(new_value: i16, sight: &mut crate::sight::Sight) -> SettingsPageClickResult,
    pub curr_value: fn(sight: &crate::sight::Sight) -> i16,
}

pub struct TextLine {
    pub text: &'static str,
}

impl SettingsPageControl for TextLine {
    fn handle_input(&self, _sight: &mut crate::sight::Sight, _input: crate::settings::RotorInput) {
        // Text lines do not handle input
    }

    fn handle_click(
        &self,
        has_focus: bool,
        _sight: &mut crate::sight::Sight,
    ) -> SettingsPageClickResult {
        SettingsPageClickResult::None
    }

    fn draw(
        &self,
        display: &mut dyn SettingsRenderer,
        _sight: &crate::sight::Sight,
        row: u8,
        active: bool,
        _focused: bool,
    ) {
        display.render_text(self.text, row, if active{ TextType::Highlighted} else { TextType::Normal });
    }
}

impl SettingsPageControl for Slider {
    fn handle_input(&self, sight: &mut crate::sight::Sight, input: crate::settings::RotorInput) {
        let mut current_value = (self.curr_value)(sight);
        // Handle input for the slider
        match input {
            crate::settings::RotorInput::Up => {
                if current_value < self.max {
                    current_value += 1;
                }
            }
            crate::settings::RotorInput::Down => {
                if current_value > self.min {
                    current_value -= 1;
                }
            }
        }
        (self.on_change)(current_value, sight);
    }

    fn handle_click(
        &self,
        has_focus: bool,
        sight: &mut crate::sight::Sight,
    ) -> SettingsPageClickResult {
        if has_focus {
            SettingsPageClickResult::LoseFocus
        } else {
            SettingsPageClickResult::GainFocus
        }
    }

    fn draw(
        &self,
        display: &mut dyn SettingsRenderer,
        sight: &crate::sight::Sight,
        row: u8,
        active: bool,
        focused: bool,
    ) {
        display.render_text(self.label, row, {
            if active {
                if focused {
                    TextType::Selected
                } else {
                    TextType::Highlighted
                }
            } else {
                TextType::Normal
            }
        });
        if active {
            display.render_sight_preview(sight);
            let mut buffer = *b"ABCD";
            format_two_digit_16((self.curr_value)(sight), &mut buffer);
            display.render_aditional_text(
                unsafe { str::from_utf8_unchecked(&buffer) },
                row,
                TextType::Normal,
                4,
            );
        }
    }
}

impl SettingsPageControl for NavigationButton {
    fn handle_input(&self, _sight: &mut crate::sight::Sight, _input: crate::settings::RotorInput) {
        // Handle input for the navigation button
    }

    fn handle_click(
        &self,
        has_focus: bool,
        _sight: &mut crate::sight::Sight,
    ) -> SettingsPageClickResult {
        // Execute the action associated with the button
        (self.action)()
    }

    fn draw(
        &self,
        display: &mut dyn SettingsRenderer,
        _sight: &crate::sight::Sight,
        row: u8,
        active: bool,
        focused: bool,
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

    fn handle_click(
        &self,
        has_focus: bool,
        _sight: &mut crate::sight::Sight,
    ) -> SettingsPageClickResult;

    fn draw(
        &self,
        _display: &mut dyn crate::settings::rendering::SettingsRenderer,
        _sight: &crate::sight::Sight,
        row: u8,
        active: bool,
        focused: bool,
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
        input: crate::settings::RotorInput,
    ) {
        // Handle input events for the settings page
        let controls = self.controls();
        if _state.active_control < controls.len() && _state.focused {
            if let Some(control) = controls[_state.active_control] {
                control.handle_input(_sight, input);
            }
        } else {
            match input {
                RotorInput::Up => {
                    if _state.active_control > 0 {
                        _state.active_control -= 1;
                    }
                }
                RotorInput::Down => {
                    if _state.active_control < controls.len() - 1 {
                        _state.active_control += 1;
                    }
                }
            }
            if _state.active_control >= controls.len() {
                _state.active_control = 0; // Reset to the first control if out of bounds
            }
            if _state.active_control < controls.len() && controls[_state.active_control].is_none() {
                _state.active_control = 0; // Reset to the first control if the current one is None
            }
        }
    }

    fn handle_click(
        &self,
        state: &mut Self::TState,
        sight: &mut crate::sight::Sight,
    ) -> crate::settings::ui::ClickResult<crate::settings::SettingsMenu> {
        // Handle click events for the settings page
        let controls = self.controls();
        if state.active_control < controls.len() {
            if let Some(control) = controls[state.active_control] {
                let result = control.handle_click(state.focused, sight);
                match result {
                    SettingsPageClickResult::LoseFocus => {
                        state.focused = false;
                        ClickResult::None
                    }
                    SettingsPageClickResult::GainFocus => {
                        state.focused = true;
                        ClickResult::None
                    }
                    SettingsPageClickResult::Exit => ClickResult::Back,
                    SettingsPageClickResult::Navigate(menu) => ClickResult::Navigate(menu),
                    SettingsPageClickResult::None => ClickResult::None,
                }
            } else {
                ClickResult::None
            }
        } else {
            ClickResult::None
        }
    }

    fn draw(
        &self,
        state: &Self::TState,
        _display: &mut dyn crate::settings::rendering::SettingsRenderer,
        _sight: &crate::sight::Sight,
    ) {
        let controls = self.controls();
        for (index, control) in controls.iter().enumerate() {
            let active = index == state.active_control;
            if let Some(control) = control {
                control.draw(
                    _display,
                    _sight,
                    index as u8,
                    active,
                    active && state.focused,
                );
            }
        }
    }
}
