use core::fmt::Debug;
use embedded_graphics::{
    mono_font::{ascii::FONT_4X6, MonoTextStyle},
    pixelcolor::Rgb565,
    prelude::{DrawTarget, Point, RgbColor},
    text::{renderer::CharacterStyle, Text},
};
use embedded_graphics_core::Drawable;

use crate::draw_reticle;

pub enum TextType {
    Normal,
    Highlighted,
    Selected,
}

pub trait SettingsRenderer {
    fn render_text(&mut self, text: &str, row: u8, text_type: TextType);
    fn render_aditional_text(&mut self, text: &str, row: u8, text_type: TextType, length: u8);
    fn render_sight_preview(&mut self, sight: &crate::sight::Sight);
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
        let style = pick_text_style(text_type);
        Text::new(text, Point::new(0, ((row + 1) * 6)as i32), style)
            .draw(self.display)
            .unwrap();
    }
    fn render_aditional_text(&mut self, text: &str, row: u8, text_type: TextType, length: u8) {
        let style = pick_text_style(text_type);
        Text::new(
            text,
            Point::new(
                (self.display.bounding_box().size.width as u8 - length* 4) as i32,
                ((row + 1) * 6) as i32,
            ),
            style,
        )
        .draw(self.display)
        .unwrap();
    }

    fn render_sight_preview(&mut self, sight: &crate::sight::Sight) {
        draw_reticle(self.display, sight);
    }
}

fn pick_text_style(text_type: TextType) -> MonoTextStyle<'static, Rgb565> {
    let style = match text_type {
        TextType::Normal => MonoTextStyle::new(&FONT_4X6, Rgb565::WHITE),
        TextType::Highlighted => {
            let mut style = MonoTextStyle::new(&FONT_4X6, Rgb565::RED);
            style.set_background_color(Some(Rgb565::GREEN));
            style
        }
        TextType::Selected => {
            let mut style = MonoTextStyle::new(&FONT_4X6, Rgb565::GREEN);
            style.set_background_color(Some(Rgb565::RED));
            style
        }
    };
    style
}

