use crate::settings::ui::settings_page::{
    NavigationButton, SettingsPage, SettingsPageClickResult, SettingsPageControl, Slider
};

pub struct SightMenu {
    back_button: NavigationButton,
    x_slider: Slider,
    y_slider: Slider,
}

impl SettingsPage for SightMenu {
    fn controls(&self) -> [Option<&dyn SettingsPageControl>; 4] {
        [
            Some(&self.x_slider),
            Some(&self.y_slider),
            Some(&self.back_button),
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
        label: "X Zero",
        min: -50,
        max: 50,
        on_change: |value, sight| {
            sight.x_zero = value as i8;
            SettingsPageClickResult::None
        },
        curr_value: |sight| sight.x_zero as i16, 
    },
    y_slider: Slider {
        label: "Y Zero",
        min: -50,
        max: 50,
        on_change: |value, sight| {
            sight.y_zero = value as i8;
            SettingsPageClickResult::None
        },
        curr_value: |sight| sight.y_zero as i16,
    },
};
