# Installation and updates

## Supported environment

The current installation flow targets Linux with Python 3.11 or newer, Meson,
Ninja, a C++20 compiler, ALSA `aplay`, curl, and Git. Piper and at least one
Piper `.onnx` voice are needed for speech.

On Debian or Ubuntu, start with the dependencies from DOSBox Staging's current
Linux build guide plus the Python/runtime tools:

```bash
sudo apt install ccache build-essential meson ninja-build git curl \
  python3 python3-venv alsa-utils libasound2-dev libatomic1 libpng-dev \
  libsdl2-dev libasio-dev libopusfile-dev libfluidsynth-dev libslirp-dev \
  libspeexdsp-dev libxi-dev
```

Package names differ on other distributions. See the DOSBox fork's
`docs/build-linux.md` for its authoritative build requirements.

## Install all components

```bash
git clone https://github.com/OperationAzura/darklands-accessibility.git
cd darklands-accessibility
./scripts/install.sh
```

The installer:

1. clones or updates all three component repositories beneath
   `~/.local/share/darklands-accessibility/src`;
2. checks out the DOSBox fork's `darklands-accessibility` branch and records the
   official project as its `upstream` remote;
3. builds DOSBox with Meson;
4. creates a Python virtual environment and installs DarkText and Darklands
   Coords in editable mode;
5. installs symlinks for `dosbox-staging`, `darktext`, `darklands-coords`, and
   the `darklands` launcher in `~/.local/bin`;
6. creates a user-editable configuration file without overwriting an existing one.

Use `./scripts/install.sh --skip-dosbox-build` when you only want to install or
refresh the Python tools and launcher.

Override installation locations with `DARKLANDS_INSTALL_ROOT`,
`DARKLANDS_BIN_DIR`, or `DARKLANDS_CONFIG_HOME`.

## Update

From the umbrella checkout:

```bash
./scripts/update.sh
```

This fast-forwards each configured component branch, refreshes the editable
Python installations, and rebuilds DOSBox. Pass `--skip-dosbox-build` to avoid
the rebuild.

## Run

Edit the generated configuration, then:

```bash
darklands
```

The launcher starts DOSBox and DarkText together. Run `darklands-coords`
separately when you want coordinate, quest, teleport, or navigation tools.
