# GameTank BASIC SDK

Write games for the [GameTank](https://gametank.zone) console in BASIC. Compiles to native 6502 for GameTank ROM cartridges.

## Quick Start

**Requirements:** GNU Make, a [GameTank Emulator](https://github.com/clydeshaffer/GameTankEmulator)

- **Windows:** `winget install GnuWin32.Make` (use `.\make` which finds it automatically)
- **macOS:** included with Xcode Command Line Tools (`xcode-select --install`)
- **Linux:** `sudo apt install make` (or equivalent)

### Emulator Setup

If `gte` or `GameTankEmulator` is on your PATH, the SDK finds it automatically:

```bash
make build FILE=examples/hello.bas
```

Otherwise, set the `GAMETANK_EMULATOR` environment variable to point to your emulator:

```bash
# One-time (Linux/macOS)
export GAMETANK_EMULATOR=/path/to/GameTankEmulator

# One-time (Windows)
set GAMETANK_EMULATOR=C:\path\to\GameTankEmulator.exe

# Or pass it directly
make build FILE=examples/hello.bas GAMETANK_EMULATOR=/path/to/GameTankEmulator
```

Run `make help` to check whether the emulator was detected.

### Usage

```bash
make compile FILE=examples/hello.bas    # Compile .bas to .gtr
make run FILE=examples/hello.gtr        # Run .gtr in emulator
make build FILE=examples/hello.bas      # Compile + run in one step
make clean FILE=examples/hello          # Remove build artifacts
```

### Visual Studio Code

The SDK includes VS Code task definitions for one-key build & run.

1. Install the [XC=BASIC 3 extension](https://marketplace.visualstudio.com/items?itemName=realorlof.orlof-xcbasic3) for syntax highlighting
2. Open the `gametank_basic_sdk` folder in VS Code
3. Open any `.bas` file and press **Ctrl+Shift+B** (Windows/Linux) or **Cmd+Shift+B** (macOS) to compile and launch in the emulator

The emulator is found the same way as the Makefile: `GAMETANK_EMULATOR` env var first, then `gte` or `GameTankEmulator` on PATH.

## SDK Reference

### Core (`gametank.bas`)

| Function | Description |
|----------|-------------|
| `gt_vsync()` | Wait for VBlank |
| `gt_flip()` | Swap display buffers |
| `gt_show()` | vsync + flip combined |
| `gt_cls(color)` | Clear screen |
| `gt_border(color)` | Fill overscan border with color (typically 0) |
| `gt_box(x,y,w,h,color)` | Filled rectangle |
| `gt_pset(x,y,color)` | Plot single pixel |
| `gt_direct_start()` | Begin batch pixel mode |
| `gt_plot(x,y,color)` | Fast pixel plot (batch mode only) |
| `gt_direct_end()` | End batch pixel mode |
| `gt_read_pad()` | Read gamepads |
| `gt_set_gram(page)` | Select GRAM page (0-7) |
| `gt_load_sprite(src,gx,gy,w,h)` | Load sprite ROM→GRAM |
| `gt_load_sprite_banked(bank,src,gx,gy,w,h)` | Load from banked ROM |
| `gt_draw_sprite(gx,gy,vx,vy,w,h,opaque)` | Draw from GRAM |
| `gt_gram_poke(x,y,color)` | Write single pixel to GRAM |
| `gt_gram_fill(x,y,w,h,color)` | Fill rectangle in GRAM |
| `gt_rom_bank(n)` | Switch ROM bank (0-127) |
| `gt_push_rom_bank()` | Push current bank to stack |
| `gt_pop_rom_bank()` | Restore previous bank from stack |

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
| `gt_audio_init()` | Initialize audio coprocessor (loads firmware from bank 0) |
| `gt_beep(note,frames)` | Quick note on ch 0 for N frames |
| `gt_song_tick()` | Advance song + update envelopes (call each frame when playing songs) |
| `gt_audio_tick()` | Update envelopes only (call each frame when using notes/SFX without songs) |
| `gt_audio_stop()` | Stop beep on channel 0 |
| `gt_audio_param(param,value)` | Queue raw coprocessor parameter |
| `gt_audio_flush()` | Send queued params to coprocessor |
| `gt_sfx_blip()` | UI blip sound effect |
| `gt_sfx_shoot()` | Shoot sound effect |
| `gt_sfx_explode()` | Explosion sound effect |
| `gt_sfx_pickup()` | Pickup/coin sound effect |
| `gt_load_instrument(ch,instr_id)` | Load instrument preset into channel (0-3) |
| `gt_note_on(ch,note)` | Start note on channel (MIDI 0-107, 60=middle C) |
| `gt_note_off(ch)` | Stop note on channel |
| `gt_silence_all()` | Silence all channels immediately |
| `gt_song_play(addr,loop)` | Play song from MIDI .bin (1=loop, 0=once) |
| `gt_song_stop()` | Stop current song |

**Instrument constants** for `gt_load_instrument`:

| Constant | ID |
|----------|-----|
| `GT_INSTR_PIANO` | 1 |
| `GT_INSTR_GUITAR` | 2 |
| `GT_INSTR_GUITAR2` | 3 |
| `GT_INSTR_SLAPBASS` | 4 |
| `GT_INSTR_SNARE` | 5 |
| `GT_INSTR_SITAR` | 6 |
| `GT_INSTR_HORN` | 7 |

## Examples

The `examples/` folder contains working programs covering text, sprites, input, audio, banking, and more. Start with `hello.bas` and work up from there.

## Links

- [GameTank Wiki](https://wiki.gametank.zone/)
- [XC-BASIC Docs](https://xc-basic.net/)
- [GameTank Emulator](https://github.com/clydeshaffer/GameTankEmulator)
