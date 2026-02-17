#!/usr/bin/env bash
# Launch GameTank emulator with a .gtr ROM file
# Checks GAMETANK_EMULATOR env var first, then PATH

if [ -n "$GAMETANK_EMULATOR" ]; then
    emu="$GAMETANK_EMULATOR"
elif command -v gte >/dev/null 2>&1; then
    emu="gte"
elif command -v GameTankEmulator >/dev/null 2>&1; then
    emu="GameTankEmulator"
else
    echo "ERROR: Emulator not found. Set GAMETANK_EMULATOR or add gte to PATH." >&2
    exit 1
fi

"$emu" "$1"
