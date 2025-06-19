use crate::{
    settings::{rendering::SettingsRenderer, RotorInput, SettingsMenu},
    sight::Sight,
};

pub struct MenuOption<TResult> {
    pub label: &'static str,
    pub action: fn() -> TResult,
}

pub struct NavigationMenu {
    pub options: &'static [MenuOption<SettingsMenu>],
}

pub struct NavigationMenuState {
    pub selected_index: i32,
}

pub enum ClickResult<TResult> {
    Back,
    Navigate(TResult),
    None,
}

impl Menu<NavigationMenuState> for NavigationMenu {
    fn handle_input(&self, state: &mut NavigationMenuState, _: &mut Sight, input: RotorInput) {
        state.selected_index = match input {
            RotorInput::Up => state.selected_index + 1,
            RotorInput::Down => state.selected_index - 1,
        };
        if state.selected_index < 0 {
            state.selected_index = self.options.len() as i32 - 1;
        } else {
            state.selected_index = state.selected_index % (self.options.len()as i32 +1 );
        }
    }
    
    fn handle_click(&self, state: &mut NavigationMenuState, sight: &mut Sight) -> ClickResult<SettingsMenu> {
        if state.selected_index < (self.options.len() as i32) {
            ClickResult::Navigate((self.options[state.selected_index as usize].action)())
        } else {
            ClickResult::Back
        }
    }

    fn draw(&self, state: &NavigationMenuState, display: &mut dyn SettingsRenderer, sight: &Sight)
    {
        for (index, option) in self.options.iter().enumerate() {
            let text_type = if index == state.selected_index as usize {
                crate::settings::rendering::TextType::Highlighted
            } else {
                crate::settings::rendering::TextType::Normal
            };
            display.render_text(option.label, index as u8, text_type);
        }

    }
}

pub trait Menu<TState> {
    fn handle_input(&self, state: &mut TState, sight: &mut Sight, input: RotorInput);
    fn handle_click(&self, state: &mut TState, sight: &mut Sight) -> ClickResult<SettingsMenu>;
    fn draw(&self, state: &TState, display: &mut dyn SettingsRenderer, sight: &Sight);
}

pub trait SubMenuPointer {
    fn handle_input(&mut self, sight: &mut Sight, input: RotorInput);
    fn handle_click(&mut self, sight: &mut Sight) -> ClickResult<SettingsMenu>;
    fn draw(&self, display: &mut dyn SettingsRenderer, sight: &Sight);
}

pub struct SubMenuPointerImpl<TState,TMenu: Menu<TState> + 'static> {
    pub submenu: &'static TMenu,
    pub state: TState
}


impl SubMenuPointer for SubMenuPointerImpl<NavigationMenuState, NavigationMenu> {
    fn handle_input(&mut self, sight: &mut Sight, input: RotorInput) {
        self.submenu.handle_input(&mut self.state, sight, input);
    }

    fn handle_click(&mut self, sight: &mut Sight) -> ClickResult<SettingsMenu> {
        self.submenu.handle_click(&mut self.state, sight)
    }

    fn draw(&self, display: &mut dyn SettingsRenderer, sight: &Sight) {
        self.submenu.draw(&self.state, display, sight);
    }
}