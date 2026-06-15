Exacto
======

Rust project for the _Arduino Nano_, powering a reflex sight for airsoft guns with an integrated ballistic computer.

## Build Instructions
1. Install prerequisites as described in the [`avr-hal` README] (`avr-gcc`, `avr-libc`, `avrdude`, [`ravedude`]).

2. Run `cargo build` to build the firmware.

3. Run `cargo run` to flash the firmware to a connected board.  If `ravedude`
   fails to detect your board, check its documentation at
   <https://crates.io/crates/ravedude>.

4. `ravedude` will open a console session after flashing where you can interact
   with the UART console of your board.

[`avr-hal` README]: https://github.com/Rahix/avr-hal#readme
[`ravedude`]: https://crates.io/crates/ravedude

## License
Licensed under the GNU General Public License, Version 3 or (at your option)
any later version ([LICENSE](LICENSE) or <https://www.gnu.org/licenses/gpl-3.0.html>).

## Contribution
Unless you explicitly state otherwise, any contribution intentionally submitted
for inclusion in the work by you shall be licensed under the GPL-3.0 license,
without any additional terms or conditions.
