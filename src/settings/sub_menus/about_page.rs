use crate::settings::ui::{
    settings_page::{NavigationButton, SettingsPage, SettingsPageClickResult, SettingsPageControl, TextLine},
    Menu,
};
use const_format::formatcp;

pub struct AboutPage {
    name: TextLine,
    version: TextLine,
    author: TextLine,
    exit: NavigationButton,
}

impl SettingsPage for AboutPage {
    fn controls(&self) -> [Option<&dyn SettingsPageControl>; 6] {
        [
            Some(&self.name),
            Some(&self.version),
            Some(&self.author),
            Some(&self.exit),
            None,
            None,
        ]
    }
}
pub const ABOUT_PAGE: AboutPage = AboutPage {
    name: TextLine {
        text: "Name: Exacto",
    },
    version: TextLine {
        text: formatcp!("Firmware Version: {}", env!("CARGO_PKG_VERSION")),
    },
    author: TextLine { text: "Author: Adam Grabski" },
    exit: NavigationButton { label: "Exit", action: || SettingsPageClickResult::Exit },
};
