//! Text rendering for `FONT_4X6`.
//!
//! `embedded_graphics`'s `MonoTextStyle`/`Text` glyph-layout path miscompiles on
//! this AVR target (every character comes out as the same wrong glyph), while the
//! plain `Image`/`SubImage` blit path renders correctly. So we lay the string out
//! ourselves and blit each glyph as an `Image`, converting the font's 1bpp pixels
//! to `Rgb565` through [`GlyphSink`] (on -> foreground, off -> background).

use core::fmt::Debug;

use embedded_graphics::{
    draw_target::DrawTarget,
    geometry::{Dimensions, OriginDimensions, Point, Size},
    image::{Image, ImageDrawableExt},
    mono_font::ascii::FONT_4X6,
    pixelcolor::{BinaryColor, Rgb565},
    primitives::Rectangle,
    Drawable, Pixel,
};

/// Draw `text` with `FONT_4X6`, with its top-left corner at `position`.
///
/// Each glyph cell is opaque: "on" pixels are drawn in `foreground`, "off" pixels
/// in `background`. Pass the surrounding background colour for `background` so the
/// cells blend in.
pub fn draw_text<T>(
    target: &mut T,
    text: &str,
    position: Point,
    foreground: Rgb565,
    background: Rgb565,
) where
    T: DrawTarget<Color = Rgb565, Error: Debug>,
{
    let cw = FONT_4X6.character_size.width;
    let ch = FONT_4X6.character_size.height;
    let glyphs_per_row = FONT_4X6.image.size().width / cw;
    let advance = cw as i32 + FONT_4X6.character_spacing as i32;

    let mut sink = GlyphSink {
        target,
        foreground,
        background,
    };

    let mut x = position.x;
    for c in text.chars() {
        let glyph_index = FONT_4X6.glyph_mapping.index(c) as u32;
        let row = glyph_index / glyphs_per_row;
        let char_x = (glyph_index - row * glyphs_per_row) * cw;
        let char_y = row * ch;

        let glyph = FONT_4X6.image.sub_image(&Rectangle::new(
            Point::new(char_x as i32, char_y as i32),
            Size::new(cw, ch),
        ));
        Image::new(&glyph, Point::new(x, position.y))
            .draw(&mut sink)
            .unwrap();
        x += advance;
    }
}

/// `DrawTarget` adapter mapping a glyph's `BinaryColor` pixels onto an `Rgb565`
/// target. It mirrors `color_converted` (delegating `fill_contiguous` to the
/// parent) rather than the `MonoFontDrawTarget` path, which is the variant proven
/// to render correctly on this target.
struct GlyphSink<'a, T> {
    target: &'a mut T,
    foreground: Rgb565,
    background: Rgb565,
}

impl<T> GlyphSink<'_, T> {
    #[inline]
    fn convert(&self, color: BinaryColor) -> Rgb565 {
        if color.is_on() {
            self.foreground
        } else {
            self.background
        }
    }
}

impl<T> Dimensions for GlyphSink<'_, T>
where
    T: DrawTarget<Color = Rgb565>,
{
    fn bounding_box(&self) -> Rectangle {
        self.target.bounding_box()
    }
}

impl<T> DrawTarget for GlyphSink<'_, T>
where
    T: DrawTarget<Color = Rgb565>,
{
    type Color = BinaryColor;
    type Error = T::Error;

    fn draw_iter<I>(&mut self, pixels: I) -> Result<(), Self::Error>
    where
        I: IntoIterator<Item = Pixel<BinaryColor>>,
    {
        let (fg, bg) = (self.foreground, self.background);
        self.target.draw_iter(
            pixels
                .into_iter()
                .map(move |Pixel(p, c)| Pixel(p, if c.is_on() { fg } else { bg })),
        )
    }

    fn fill_contiguous<I>(&mut self, area: &Rectangle, colors: I) -> Result<(), Self::Error>
    where
        I: IntoIterator<Item = BinaryColor>,
    {
        let (fg, bg) = (self.foreground, self.background);
        self.target.fill_contiguous(
            area,
            colors
                .into_iter()
                .map(move |c| if c.is_on() { fg } else { bg }),
        )
    }

    fn fill_solid(&mut self, area: &Rectangle, color: BinaryColor) -> Result<(), Self::Error> {
        self.target.fill_solid(area, self.convert(color))
    }
}
