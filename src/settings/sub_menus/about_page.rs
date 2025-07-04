use crate::settings::ui::{
    settings_page::{NavigationButton, SettingsPage, SettingsPageClickResult, SettingsPageControl, TextLine},
    Menu,
};
use const_format::formatcp;

pub struct AboutPage {
    version: TextLine,
    author: TextLine,
    exit: NavigationButton,
}

impl SettingsPage for AboutPage {
    fn controls(&self) -> [Option<&dyn SettingsPageControl>; 4] {
        [
            Some(&self.version),
            Some(&self.author),
            Some(&self.exit),
            None
        ]
    }
}
pub const ABOUT_PAGE: AboutPage = AboutPage {
    version: TextLine {
        text: formatcp!("Firmware Version: {}", env!("CARGO_PKG_VERSION")),
    },
    author: TextLine { text: "Author: Adam Grabski" },
    exit: NavigationButton { label: "Exit", action: || SettingsPageClickResult::Exit },
};
