use core::fmt::Debug;
use embedded_graphics::{
    mono_font::{ascii::FONT_6X10, MonoTextStyle},
    pixelcolor::Rgb565,
    prelude::{DrawTarget, Point, RgbColor},
    text::Text,
};
use embedded_graphics_core::Drawable;

pub enum TextType {
    Normal,
    Highlighted,
}

pub trait SettingsRenderer {
    fn render_text(&mut self, text: &str, row: u8, text_type: TextType);
}

pub(crate) struct DefaultSettingsRenderer<'a, TGraphicsInterface>
where
    TGraphicsInterface: DrawTarget<Color = Rgb565, Error: Debug>,
{
    pub display: &'a mut TGraphicsInterface,
}

impl<'a, TGraphicsInterface> SettingsRenderer for DefaultSettingsRenderer<'a, TGraphicsInterface>
where
    TGraphicsInterface: DrawTarget<Color = Rgb565, Error: Debug>,
{
    fn render_text(&mut self, text: &str, row: u8, text_type: TextType) {
        let style = match text_type {
            TextType::Normal => MonoTextStyle::new(&FONT_6X10, Rgb565::WHITE),
            TextType::Highlighted => MonoTextStyle::new(&FONT_6X10, Rgb565::YELLOW),
        };
        Text::new(text, Point::new(0, (row + 1) as i32 * 10), style)
            .draw(self.display)
            .unwrap();
    }
}
