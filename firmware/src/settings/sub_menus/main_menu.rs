use crate::settings::{
    ui::{MenuOption, NavigationMenu, NavigationMenuState},
    SettingsMenu,
};

pub const MAIN_MENU: NavigationMenu = NavigationMenu {
    options: &[
        MenuOption {
            label: "Sight",
            action: || SettingsMenu::Sight,
        },
        MenuOption {
            label: "Settings",
            action: || SettingsMenu::Settings,
        },
        MenuOption {
            label: "About",
            action: || SettingsMenu::About,
        },
    ]
};

pub type MainMenuType = NavigationMenu;
pub type MainMenuState = NavigationMenuState;