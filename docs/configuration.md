# Configuration

The default installer creates a single project-local shell configuration file:

```text
./local/config/darklands.env
```

It is used both by the installer and by the project-local launch commands. The
shipped template is [`config/darklands.env.example`](../config/darklands.env.example).

Because the file uses `${NAME:-value}` defaults, exported environment variables
can override its values for one run without editing it.

## Installation settings

| Variable | Purpose |
| --- | --- |
| `DARKLANDS_INSTALL_ROOT` | Self-contained install tree; default `./local` inside the umbrella checkout |
| `DARKLANDS_INSTALL_USER_COMMANDS` | `0` by default; set `1` to create PATH-level symlinks |
| `DARKLANDS_USER_BIN_DIR` | Destination for optional user-command symlinks; default `~/.local/bin` |

## Repository selection

| Variable | Purpose |
| --- | --- |
| `DARKLANDS_DOSBOX_REPO_URL` | DOSBox accessibility fork URL |
| `DARKLANDS_DOSBOX_BRANCH` | DOSBox branch; default `darklands-accessibility` |
| `DARKLANDS_DARKTEXT_REPO_URL` | DarkText repository URL |
| `DARKLANDS_DARKTEXT_BRANCH` | DarkText branch; default `main` |
| `DARKLANDS_COORDS_REPO_URL` | Darklands Coords repository URL |
| `DARKLANDS_COORDS_BRANCH` | Darklands Coords branch; default `main` |

This makes experimental combinations explicit. For example:

```bash
DARKLANDS_DARKTEXT_BRANCH="auto-text-region"
```

keeps DOSBox and Darklands Coords on their normal branches while installing and
updating DarkText from the experimental branch.

## Game settings

| Variable | Purpose |
| --- | --- |
| `DARKLANDS_GAME_DIR` | Directory containing the user's installed game |
| `DARKLANDS_GAME_EXE` | Full path to `darkland.exe` |

The game remains outside the project-local install tree and is never copied or
modified by the installer.

## DarkText and Piper

| Variable | Purpose |
| --- | --- |
| `DARKTEXT_DATA_DIR` | Logs, debug captures, and generated speech cache; default `./local/data` |
| `DARKTEXT_PIPER_BIN` | Piper executable used by DarkText; default `./local/bin/piper` |
| `DARKTEXT_VOICE_DIR` | Directory containing Piper `.onnx` voices; default `./local/voices` |
| `DARKLANDS_PIPER_PACKAGE` | Python Piper package installed into the local venv when needed |
| `DARKLANDS_PIPER_VOICE` | Voice downloaded only when the selected voice directory has no ONNX models |
| `DARKLANDS_PIPER_BIN` | Piper executable override used by Darklands Coords |
| `DARKLANDS_VOICE_DIR` | Piper voices used by Darklands Coords |
| `DARKLANDS_COORDS_CONFIG` | Coords calibration/config file; default under `./local/config` |

A custom existing Piper setup can be used without replacing it:

```bash
DARKTEXT_PIPER_BIN="/path/to/existing/piper"
DARKTEXT_VOICE_DIR="/path/to/existing/voices"
```

## DOSBox API

| Variable | Purpose |
| --- | --- |
| `DOSBOX_WEBSERVER_BIND` | Loopback bind address; normally `127.0.0.1` |
| `DOSBOX_WEBSERVER_PORT` | Accessibility API port; normally `8086` |
| `DOSBOX_API_URL` | URL used by DarkText and related tools |

The launcher refuses a non-loopback bind address because the DOSBox accessibility
API exposes privileged emulator capabilities.

## Runtime layout

No generated runtime data belongs in Git. The entire default `./local` tree is
git-ignored. This includes component checkouts, the Python environment, built
DOSBox binary, Piper wrapper, voices, logs, debug images, speech cache, and
configuration.
