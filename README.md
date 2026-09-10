# Darklands Accessibility

An open-source accessibility toolkit for the 1992 DOS role-playing game
**Darklands**. The project combines native emulator access, OCR-driven speech,
and accessible world-map and quest navigation while keeping the proprietary
game completely separate.

## Components

| Repository | Purpose | License |
| --- | --- | --- |
| [dosboxStagingAccess](https://github.com/OperationAzura/dosboxStagingAccess) | DOSBox Staging fork providing a loopback framebuffer, memory, keyboard, and mouse API | GPL-2.0-or-later and other retained upstream licenses |
| [darktext](https://github.com/OperationAzura/darktext) | OCR and Piper speech for story text and highlighted choices | MIT |
| [darklands-coords](https://github.com/OperationAzura/darklands-coords) | Coordinates, quest inspection, save tools, and assisted world-map navigation | MIT |

This umbrella repository contains documentation, configuration examples, and
install/update scripts only. It deliberately does not duplicate the component
repositories and does not use Git submodules.

## What it provides

- Native emulated-frame capture independent of desktop focus
- Spoken story text and rapidly updated highlighted menu choices
- Save-coordinate announcements and directional guidance
- Live-RAM coordinate calibration and verified assisted navigation
- Quest listing and navigation to objectives or reward destinations
- Backup-before-write teleport and add-money save utilities

## Quick start

Darklands itself is not included or modified. Install your legally obtained game
first, then clone this repository and run the installer:

```bash
git clone https://github.com/OperationAzura/darklands-accessibility.git
cd darklands-accessibility
./scripts/install.sh
```

The default installation is intentionally self-contained. It creates a git-ignored
`./local` directory inside this checkout containing component repositories, the
Python virtual environment, built DOSBox binary, Piper, voices, runtime data,
configuration, and launch commands. It does **not** create or replace commands in
`~/.local/bin`, and it does **not** install system packages unless explicitly asked.

After installation, run:

```bash
./local/bin/darklands
```

and, when wanted:

```bash
./local/bin/darklands-coords
./local/bin/darktext once
```

The generated configuration is:

```text
./local/config/darklands.env
```

Edit that one file to choose the Darklands executable, component branches,
Piper/voice locations, API settings, and whether user-level command links should
be installed. For example, an experimental DarkText branch can be selected with:

```bash
DARKLANDS_DARKTEXT_BRANCH="auto-text-region"
```

then rerun `./scripts/install.sh` or `./scripts/update.sh`.

If you explicitly want convenient PATH commands, use:

```bash
./scripts/install.sh --install-user-commands
```

If Debian/Ubuntu build dependencies are missing and you want the installer to
manage them, use:

```bash
./scripts/install.sh --install-system-deps
```

or add `--yes` to make that requested apt step non-interactive.

## Documentation

- [Architecture](docs/architecture.md)
- [Installation and updates](docs/install.md)
- [Configuration](docs/configuration.md)
- [Security and save safety](docs/security.md)
- [Licensing and provenance](docs/licensing.md)
- [Initial publishing audit](docs/publishing-audit.md)

## Project scope

This is an independent community accessibility project. It is not affiliated
with MicroProse, Atari, DOSBox Staging, or the Darklands rights holders.
Darklands binaries, assets, and save files are never distributed here.

## License

The umbrella documentation and scripts are [MIT licensed](LICENSE). Each
component keeps its own license; in particular, the DOSBox Staging fork remains
under its upstream GPL and bundled third-party license terms.
