use crate::settings::ui::settings_page::{
    NavigationButton, SettingsPage, SettingsPageClickResult, SettingsPageControl, Slider
};

pub struct SightMenu {
    back_button: NavigationButton,
    x_slider: Slider,
}

impl SettingsPage for SightMenu {
    fn controls(&self) -> [Option<&dyn SettingsPageControl>; 6] {
        [
            Some(&self.x_slider),
            Some(&self.back_button),
            None,
            None,
            None,
            None,
        ]
    }
}

pub const SIGHT_MENU: SightMenu = SightMenu {
    back_button: NavigationButton {
        label: "Back",
        action: || SettingsPageClickResult::Exit,
    },
    x_slider: Slider {
        label: "X Offset",
        min: -50,
        max: 50,
        on_change: |value, sight| {
            sight.x_zero = value;
            SettingsPageClickResult::None
        },
        curr_value: |sight| sight.x_zero,
    },
};
