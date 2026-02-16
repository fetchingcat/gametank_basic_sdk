# GameTank BASIC SDK - Cross-Platform Build System
# =================================================
#
# Prerequisites:
#   Windows: winget install GnuWin32.Make
#   macOS:   make is included with Xcode Command Line Tools
#   Linux:   sudo apt install make (or equivalent)
#
# Usage (Windows - use .\make or make if on PATH):
#   .\make compile FILE=examples/blackjack.bas
#   .\make run FILE=examples/blackjack.gtr
#   .\make build FILE=examples/blackjack.bas    (compile + run)
#   .\make clean FILE=examples/blackjack
#
# Usage (macOS/Linux):
#   make compile FILE=examples/blackjack.bas
#   make run FILE=examples/blackjack.gtr

# ── OS Detection ────────────────────────────────────────────
ifeq ($(OS),Windows_NT)
    PLATFORM := windows
    EXE_EXT  := .exe
    SHELL    := cmd.exe
else
    UNAME_S := $(shell uname -s)
    ifeq ($(UNAME_S),Darwin)
        PLATFORM := macos
    else
        PLATFORM := linux
    endif
    EXE_EXT :=
endif

# ── SDK Root (directory containing this Makefile) ───────────
SDK_ROOT := $(patsubst %/,%,$(dir $(abspath $(lastword $(MAKEFILE_LIST)))))

# ── Version ─────────────────────────────────────────────────
ifeq ($(OS),Windows_NT)
    SDK_VERSION := $(shell type "$(SDK_ROOT)\VERSION")
else
    SDK_VERSION := $(shell cat "$(SDK_ROOT)/VERSION")
endif

# ── Tool Paths ──────────────────────────────────────────────
XCBASIC := $(SDK_ROOT)/bin/$(PLATFORM)/xcbasic3$(EXE_EXT)
DASM    := $(SDK_ROOT)/bin/$(PLATFORM)/dasm$(EXE_EXT)

# ── Emulator (user-configurable via env var or make arg) ────
# Set GAMETANK_EMULATOR to the path of your GameTank Emulator
EMULATOR ?= $(GAMETANK_EMULATOR)

# ── Compiler Flags ──────────────────────────────────────────
XCFLAGS := --target=gametank --output-format=gtr

# ── Derived Paths from FILE ────────────────────────────────
ifdef FILE
    BASENAME := $(basename $(FILE))
    GTRFILE  := $(BASENAME).gtr
    SYMFILE  := $(BASENAME).sym
    MAPFILE  := $(BASENAME).map
endif

# ── Build Output Directory ──────────────────────────────────
BUILD_DIR := $(SDK_ROOT)/build

# ── Windows path helper ─────────────────────────────────────
ifeq ($(OS),Windows_NT)
    FP = $(subst /,\,$(1))
else
    FP = $(1)
endif

# ── Targets ─────────────────────────────────────────────────
.PHONY: help compile run build clean

help:
	@echo --- GameTank BASIC SDK v$(SDK_VERSION) ---
	@echo Usage:
	@echo   make compile FILE=examples/game.bas   Compile .bas to .gtr
	@echo   make run FILE=examples/game.gtr       Run in emulator
	@echo   make build FILE=examples/game.bas     Compile + run
	@echo   make clean FILE=examples/game         Remove build artifacts
	@echo Configuration:
	@echo   GAMETANK_EMULATOR=path/to/emulator    Set emulator path
	@echo Platform: $(PLATFORM)
	@echo Compiler: $(XCBASIC)

# ── Compile ─────────────────────────────────────────────────
compile:
ifndef FILE
	$(error FILE is required. Usage: make compile FILE=examples/game.bas)
endif
ifeq ($(OS),Windows_NT)
	"$(call FP,$(XCBASIC))" "$(call FP,$(FILE))" "$(call FP,$(GTRFILE))" $(XCFLAGS) --dasm="$(call FP,$(DASM))" --symbol="$(call FP,$(SYMFILE))"
	if exist "$(call FP,$(SYMFILE))" powershell -ExecutionPolicy Bypass -File "$(call FP,$(SDK_ROOT)/scripts/convert_symbols.ps1)" "$(call FP,$(SYMFILE))" "$(call FP,$(MAPFILE))"
	if not exist "$(call FP,$(BUILD_DIR))" mkdir "$(call FP,$(BUILD_DIR))"
	if exist "$(call FP,$(MAPFILE))" copy /y "$(call FP,$(MAPFILE))" "$(call FP,$(BUILD_DIR))\out.map" >nul
else
	"$(XCBASIC)" "$(FILE)" "$(GTRFILE)" $(XCFLAGS) --dasm="$(DASM)" --symbol="$(SYMFILE)"
	@if [ -f "$(SYMFILE)" ]; then \
		chmod +x "$(SDK_ROOT)/scripts/convert_symbols.sh"; \
		"$(SDK_ROOT)/scripts/convert_symbols.sh" "$(SYMFILE)" "$(MAPFILE)"; \
		mkdir -p "$(BUILD_DIR)"; \
		cp "$(MAPFILE)" "$(BUILD_DIR)/out.map"; \
	fi
endif
	@echo Compiled: $(GTRFILE)

# ── Run ─────────────────────────────────────────────────────
run:
ifndef FILE
	$(error FILE is required. Usage: make run FILE=examples/game.gtr)
endif
ifndef EMULATOR
	$(error GAMETANK_EMULATOR is not set. Point it to your GameTank Emulator executable.)
endif
ifeq ($(OS),Windows_NT)
	start "" "$(call FP,$(EMULATOR))" "$(call FP,$(abspath $(FILE)))"
else
	"$(EMULATOR)" "$(abspath $(FILE))" &
endif

# ── Build (compile + run) ──────────────────────────────────
build:
ifndef FILE
	$(error FILE is required. Usage: make build FILE=examples/game.bas)
endif
	"$(MAKE)" compile FILE=$(FILE)
	"$(MAKE)" run FILE=$(GTRFILE) EMULATOR="$(EMULATOR)"

# ── Clean ───────────────────────────────────────────────────
clean:
ifndef FILE
	$(error FILE is required. Usage: make clean FILE=examples/game (without extension))
endif
ifeq ($(OS),Windows_NT)
	if exist "$(call FP,$(FILE)).gtr" del /q "$(call FP,$(FILE)).gtr"
	if exist "$(call FP,$(FILE)).sym" del /q "$(call FP,$(FILE)).sym"
	if exist "$(call FP,$(FILE)).map" del /q "$(call FP,$(FILE)).map"
else
	rm -f "$(FILE).gtr" "$(FILE).sym" "$(FILE).map"
endif
	@echo Cleaned: $(FILE).*
