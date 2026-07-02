use core::fmt::Debug;
use embedded_graphics::{
    pixelcolor::BinaryColor,
    prelude::{DrawTarget, Point},
};

use crate::draw_reticle;
use crate::text::draw_text;

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
    TGraphicsInterface: DrawTarget<Color = BinaryColor, Error: Debug>,
{
    pub display: &'a mut TGraphicsInterface,
}

impl<'a, TGraphicsInterface> SettingsRenderer for DefaultSettingsRenderer<'a, TGraphicsInterface>
where
    TGraphicsInterface: DrawTarget<Color = BinaryColor, Error: Debug>,
{
    fn render_text(&mut self, text: &str, row: u8, text_type: TextType) {
        self.render_text_inner(
            text,
            Point::new(0, ((row + 1) * 6) as i32),
            text.len() as u8,
            text_type,
        );
    }

    fn render_aditional_text(&mut self, text: &str, row: u8, text_type: TextType, length: u8) {
        self.render_text_inner(
            text,
            Point::new(
                (self.display.bounding_box().size.width as u8 - length * 4) as i32,
                ((row + 1) * 6) as i32,
            ),
            length,
            text_type,
        );
    }

    fn render_sight_preview(&mut self, sight: &crate::sight::Sight) {
        draw_reticle(self.display, sight);
    }
}

impl<'a, TGraphicsInterface> DefaultSettingsRenderer<'a, TGraphicsInterface>
where
    TGraphicsInterface: DrawTarget<Color = BinaryColor, Error: Debug>,
{
    fn render_text_inner(&mut self, text: &str, position: Point, _length: u8, text_type: TextType) {
        let (foreground, background) = pick_text_colors(text_type);
        draw_text(self.display, text, position, foreground, background);
    }
}

/// (foreground, background) colours for a given text type. The display is
/// monochrome, so `Highlighted`/`Selected` both render as inverted
/// (filled-background) text to stand out from `Normal`.
fn pick_text_colors(text_type: TextType) -> (BinaryColor, BinaryColor) {
    match text_type {
        TextType::Normal => (BinaryColor::On, BinaryColor::Off),
        TextType::Highlighted => (BinaryColor::Off, BinaryColor::On),
        TextType::Selected => (BinaryColor::Off, BinaryColor::On),
    }
}
