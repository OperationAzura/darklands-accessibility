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

Darklands itself is not included. Install your legally obtained game first,
along with the system dependencies listed in the [installation guide](docs/install.md).

```bash
git clone https://github.com/OperationAzura/darklands-accessibility.git
cd darklands-accessibility
./scripts/install.sh
```

Review `~/.config/darklands-accessibility/darklands.env`, set the game and Piper
paths if needed, ensure `~/.local/bin` is on `PATH`, then run:

```bash
darklands
```

In another terminal, start coordinate or quest navigation with:

```bash
darklands-coords
```

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
