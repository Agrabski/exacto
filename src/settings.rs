mod rendering;
mod sub_menus;
mod ui;

use crate::{
    encoder::RotaryEncoder,
    settings::{
        rendering::SettingsRenderer,
        sub_menus::main_menu::{MainMenuState, MainMenuType, MAIN_MENU},
        ui::{ClickResult, SubMenuPointer, SubMenuPointerImpl},
    },
    sight::Sight,
};
use core::{fmt::Debug, iter::Map, ops::Sub};
use embedded_graphics::{
    mono_font::{ascii::FONT_6X10, MonoTextStyle},
    pixelcolor::Rgb565,
    prelude::{DrawTarget, Point, RgbColor},
    text::{renderer, Text},
};
use embedded_graphics_core::Drawable;
use embedded_hal::digital::InputPin;
use ufmt::derive;

pub struct SettingsState {
    current_menu: Option<SettingsMenu>,
    rotor_position: i32,
    states: SubMenuStates,
}

enum RotorInput {
    Up,
    Down,
}

#[derive(Debug, Clone, Copy)]
enum SettingsMenu {
    MainMenu,
    Sight,
    Settings,
    About,
}


struct SubMenuStates {
    main_menu: SubMenuPointerImpl<MainMenuState, MainMenuType>,
}

impl SubMenuStates {
    pub fn new() -> Self {
        Self {
            main_menu: SubMenuPointerImpl {
                submenu: &MAIN_MENU,
                state: MainMenuState { selected_index: 0 },
            },
        }
    }

    pub fn get_menu<'a>(&'a mut self, menu: SettingsMenu) -> Option<&'a mut dyn SubMenuPointer> {
        match menu {
            SettingsMenu::MainMenu => Some(&mut self.main_menu),
            _ => None,
        }
    }

    pub fn get_menu_const<'a>(&'a self, menu: SettingsMenu) -> Option<&'a dyn SubMenuPointer> {
        match menu {
            SettingsMenu::MainMenu => Some(&self.main_menu),
            _ => None,
        }
    }
}

impl SettingsState {
    pub fn new() -> Self {
        Self {
            current_menu: None,
            rotor_position: 0,
            states: SubMenuStates::new(),
        }
    }

    pub fn is_open(&self) -> bool {
        self.current_menu.is_some()
    }

    pub fn update<A, B, SW>(
        &mut self,
        sight: &mut Sight,
        encoder: &mut RotaryEncoder<A, B, SW>,
    ) -> bool
    where
        A: InputPin,
        B: InputPin,
        SW: InputPin,
    {
        if encoder.is_pressed().is_ok_and(|pressed| pressed) {
            self.rotor_position = encoder.position();
            self.handle_press(sight)
        } else {
            let position = encoder.position();
            let change = match (self.rotor_position, position) {
                (a, b) if a > b => RotorInput::Up,
                (a, b) if a < b => RotorInput::Down,
                _ => return false,
            };
            self.rotor_position = position;
            self.handle_rotation(sight, change)
        }
    }

    pub fn draw<DI>(&self, display: &mut DI, sight: &Sight)
    where
        DI: DrawTarget<Color = Rgb565, Error: Debug>,
    {
        if let Some(menu) = &self.current_menu {
            let mut renderer = rendering::DefaultSettingsRenderer { display };
            let sub_menu = self.states.get_menu_const(*menu).unwrap_or_else(|| {
                panic!("No submenu found for {:?}", *menu);
            });
            sub_menu.draw(&mut renderer, sight);
        }
    }

    fn handle_rotation(&mut self, sight: &mut Sight, change: RotorInput) -> bool {
        if let Some(menu) = self.current_menu.as_mut() {
            let sub_menu = self.states.get_menu(menu.clone()).unwrap_or_else(|| {
                panic!("No submenu found for {:?}", menu);
            });
            sub_menu.handle_input(sight, change);
            true
        } else {
            false
        }
    }

    fn handle_press(&mut self, sight: &mut Sight) -> bool {
        if let Some(menu) = self.current_menu.as_mut() {
            let sub_menu = self.states.get_menu(menu.clone()).unwrap_or_else(|| {
                panic!("No submenu found for {:?}", menu);
            });
            match sub_menu.handle_click(sight) {
                ClickResult::Navigate(next_menu) => {
                    self.current_menu = Some(next_menu);
                }
                ClickResult::Back => {
                    self.current_menu = None;
                }
                ClickResult::None => {}
            }
        } else {
            self.current_menu = Some(SettingsMenu::MainMenu);
        }
        true
    }
}
