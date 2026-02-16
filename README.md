# GameTank BASIC SDK

Write games for the [GameTank](https://gametank.zone) console in BASIC. Compiles to native 6502 for GameTank ROM cartridges.

## Quick Start

**Requirements:** GNU Make, a [GameTank Emulator](https://github.com/clydeshaffer/GameTankEmulator)

- **Windows:** `winget install GnuWin32.Make` (use `.\make` which finds it automatically)
- **macOS:** included with Xcode Command Line Tools (`xcode-select --install`)
- **Linux:** `sudo apt install make` (or equivalent)

Set the `GAMETANK_EMULATOR` environment variable to your emulator path, then:

```bash
make build FILE=examples/hello.bas
```

This compiles and runs in one step. You can also `make compile` and `make run` separately.

## SDK Reference

### Core (`gametank.bas`)

| Function | Description |
|----------|-------------|
| `gt_vsync()` | Wait for VBlank |
| `gt_flip()` | Swap display buffers |
| `gt_show()` | vsync + flip combined |
| `gt_cls(color)` | Clear screen |
| `gt_box(x,y,w,h,color)` | Filled rectangle |
| `gt_read_pad()` | Read gamepads |
| `gt_set_gram(page)` | Select GRAM page (0-7) |
| `gt_load_sprite(src,gx,gy,w,h)` | Load sprite ROM→GRAM |
| `gt_draw_sprite(gx,gy,vx,vy,w,h,opaque)` | Draw from GRAM |
| `gt_rom_bank(n)` | Switch ROM bank (0-127) |
| `gt_load_sprite_banked(bank,src,gx,gy,w,h)` | Load from banked ROM |

### Text (`gametank_text.bas`)

| Function | Description |
|----------|-------------|
| `gt_text_init()` | Initialize font in GRAM |
| `gt_text_color(c)` | Set font color (before init) |
| `gt_locate(col,row)` | Position cursor on grid |
| `gt_locate_px(x,y)` | Position cursor in pixels |
| `gt_print_str(addr)` | Print string |
| `gt_print_byte(n)` | Print 0-255 |
| `gt_print_word(n)` | Print 0-65535 |
| `gt_putchar(c)` | Print one ASCII character |

### Audio (`gametank_audio.bas`)

| Function | Description |
|----------|-------------|
| `gt_audio_init()` | Load audio firmware |
| `gt_beep(note,frames)` | Play MIDI note (36-96) |
| `gt_audio_tick()` | Update audio (call each frame) |
| `gt_sfx_blip()` | UI blip |
| `gt_sfx_shoot()` | Shoot sound |
| `gt_sfx_explode()` | Explosion |
| `gt_sfx_pickup()` | Pickup/coin |

## Examples

The `examples/` folder contains working programs covering text, sprites, input, audio, banking, and more. Start with `hello.bas` and work up from there.

## Links

- [GameTank Wiki](https://wiki.gametank.zone/)
- [XC-BASIC Docs](https://xc-basic.net/)
- [GameTank Emulator](https://github.com/clydeshaffer/GameTankEmulator)
