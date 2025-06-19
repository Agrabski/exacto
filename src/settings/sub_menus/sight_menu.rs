use crate::settings::ui::settings_page::{
    NavigationButton, SettingsPage, SettingsPageClickResult, SettingsPageControl,
};

pub struct SightMenu {
    back_button: NavigationButton,
}

impl SettingsPage for SightMenu {
    fn controls(&self) -> [Option<&dyn SettingsPageControl>; 6] {
        [Some(&self.back_button), None, None, None, None, None]
    }
}

pub const SIGHT_MENU: SightMenu = SightMenu {
    back_button: NavigationButton {
        label: "Back",
        action: || SettingsPageClickResult::Exit,
    },
};
