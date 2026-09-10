# Installation and updates

## Supported environment

The current installation flow targets Linux with Python 3.11 or newer, Git,
Meson, Ninja, a C++20 compiler, ALSA `aplay`, and curl.

The installer is self-contained for project files, but it also behaves like a
complete installer: on Debian/Ubuntu it checks required system packages and, if
anything is missing, lists the packages and asks whether to install them. It
still does not write commands into `~/.local/bin` unless that is explicitly
requested.

## Default layout

From an umbrella checkout:

```bash
git clone https://github.com/OperationAzura/darklands-accessibility.git
cd darklands-accessibility
./scripts/install.sh
```

The default install root is the git-ignored `./local` directory inside that
checkout:

```text
local/
  bin/       project-local launch commands
  config/    generated configuration
  data/      DarkText logs, debug captures, and speech cache
  src/       component repository checkouts
  venv/      Python environment, including Piper by default
  voices/    Piper ONNX voice models
```

Darklands itself stays wherever the user installed it. The installer only keeps
its path in configuration; it never copies, patches, or deletes the game.

The installer prints its resolved plan before cloning or building, including the
game path, install root, selected branches, voice directory, user-command mode,
and system-dependency behavior.

## Configuration and branches

On first run, the installer creates:

```text
./local/config/darklands.env
```

Edit that file to select component branches or paths. Relevant branch settings
are:

```bash
DARKLANDS_DOSBOX_BRANCH="darklands-accessibility"
DARKLANDS_DARKTEXT_BRANCH="main"
DARKLANDS_COORDS_BRANCH="main"
```

For example, to test an experimental DarkText branch without changing the other
components:

```bash
DARKLANDS_DARKTEXT_BRANCH="auto-text-region"
```

Then rerun:

```bash
./scripts/install.sh
```

A different configuration file can be selected with:

```bash
./scripts/install.sh --config /path/to/darklands.env
```

Exported environment variables can also override values from the generated
configuration.

## Piper and voices

By default, Piper is installed into `./local/venv` and exposed through
`./local/bin/piper`. The default voice directory is `./local/voices`.

If that directory already contains one or more `.onnx` models, the installer
keeps and uses them instead of forcing the default voice download. A custom
Piper executable or voice directory can be configured with:

```bash
DARKTEXT_PIPER_BIN="/path/to/piper"
DARKTEXT_VOICE_DIR="/path/to/voices"
```

If no ONNX model exists in the selected voice directory, the installer downloads
`DARKLANDS_PIPER_VOICE` (default `en_US-amy-medium`).

## System dependencies

On Debian/Ubuntu, the default installer checks the required apt packages. If
anything is missing, it prints the complete missing-package list and asks:

```text
Install these missing dependencies with apt? [Y/n]
```

Press Enter or answer yes to install them. The installer uses `sudo` when
needed.

For unattended installation, use:

```bash
./scripts/install.sh --yes
```

In a non-interactive session, missing dependencies are also installed
automatically unless dependency handling was explicitly disabled.

If system packages are being managed separately, skip that entire step with:

```bash
./scripts/install.sh --skip-system-deps
```

`--install-system-deps` is also accepted, but dependency checking and prompting
are already the default.

Use `--skip-dosbox-build` when only the Python components and launch wrappers
should be refreshed.

## Commands

The normal self-contained commands are:

```bash
./local/bin/darklands
./local/bin/darktext
./local/bin/darklands-coords
./local/bin/piper
```

The installer also places the built DOSBox executable at:

```text
./local/bin/dosbox-staging
```

Nothing under `~/.local/bin` is touched by default.

If PATH-level convenience commands are wanted, explicitly request them:

```bash
./scripts/install.sh --install-user-commands
```

That creates or updates symlinks in the configured `DARKLANDS_USER_BIN_DIR`
(default `~/.local/bin`) pointing back to the project-local commands. Use
`--no-user-commands` to explicitly disable that behavior even when enabled in a
configuration file.

## Update

From the umbrella checkout:

```bash
./scripts/update.sh
```

The update script fast-forwards the umbrella repository, then reuses the same
installer and generated configuration. Each component is switched to and
fast-forwarded on its configured branch before editable Python installs and the
DOSBox build are refreshed.

## Run

After setting the game path if necessary:

```bash
./local/bin/darklands
```

The launcher prefers the project-local DOSBox and DarkText commands, starts the
loopback accessibility API, and starts DarkText automatically. Run
`./local/bin/darklands-coords` separately for coordinate, quest, teleport, or
navigation tools.
