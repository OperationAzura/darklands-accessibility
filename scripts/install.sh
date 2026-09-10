#!/usr/bin/env bash
set -Eeuo pipefail

build_dosbox=1
install_system_deps=0
assume_yes=0
user_commands_override=""
config_override=""

usage()
{
    cat <<'EOF'
Usage: ./scripts/install.sh [options]

Install the Darklands accessibility stack into this checkout's ./local tree by
default. No commands in ~/.local/bin and no system packages are changed unless
you explicitly opt in.

Options:
  --config FILE             Use a specific shell configuration file
  --install-system-deps     Offer/install missing Debian/Ubuntu apt packages
  --skip-system-deps        Never install system packages (default)
  --skip-dosbox-build       Do not build DOSBox Staging
  --install-user-commands   Link project-local commands into ~/.local/bin
  --no-user-commands        Do not create/update ~/.local/bin links (default)
  -y, --yes                 Answer yes to requested dependency installation
  -h, --help                Show this help

The configuration controls the Darklands game path, repository URLs/branches,
Piper/voice locations, install root, API settings, and user-command opt-in.
EOF
}

while (($#)); do
    case "$1" in
        --config)
            shift
            [[ $# -gt 0 ]] || { echo "--config requires a file" >&2; exit 2; }
            config_override="$1"
            ;;
        --install-system-deps) install_system_deps=1 ;;
        --skip-system-deps) install_system_deps=0 ;;
        --skip-dosbox-build) build_dosbox=0 ;;
        --install-user-commands) user_commands_override=1 ;;
        --no-user-commands) user_commands_override=0 ;;
        -y|--yes) assume_yes=1 ;;
        -h|--help) usage; exit 0 ;;
        *) echo "Unknown argument: $1" >&2; usage >&2; exit 2 ;;
    esac
    shift
done

script_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
project_dir="$(cd "$script_dir/.." && pwd)"
export DARKLANDS_PROJECT_DIR="$project_dir"

initial_root="${DARKLANDS_INSTALL_ROOT:-$project_dir/local}"
config_file="${config_override:-${DARKLANDS_CONFIG_FILE:-$initial_root/config/darklands.env}}"
mkdir -p "$(dirname "$config_file")"

if [[ ! -f "$config_file" ]]; then
    cp "$project_dir/config/darklands.env.example" "$config_file"
    echo "Created configuration: $config_file"
fi

# Export values loaded from the shell config so child launchers inherit them.
set -a
# shellcheck source=/dev/null
source "$config_file"
set +a

install_root="${DARKLANDS_INSTALL_ROOT:-$project_dir/local}"
source_root="$install_root/src"
venv="$install_root/venv"
bin_dir="$install_root/bin"
config_dir="$install_root/config"
data_dir="${DARKTEXT_DATA_DIR:-$install_root/data}"
voice_dir="${DARKTEXT_VOICE_DIR:-$install_root/voices}"
user_bin_dir="${DARKLANDS_USER_BIN_DIR:-$HOME/.local/bin}"
install_user_commands="${DARKLANDS_INSTALL_USER_COMMANDS:-0}"
[[ -n "$user_commands_override" ]] && install_user_commands="$user_commands_override"

piper_package="${DARKLANDS_PIPER_PACKAGE:-piper-tts==1.4.2}"
piper_voice="${DARKLANDS_PIPER_VOICE:-en_US-amy-medium}"

dosbox_dir="$source_root/dosbox-staging-accessibility"
darktext_dir="$source_root/darktext"
coords_dir="$source_root/darklands-coords"
dosbox_url="${DARKLANDS_DOSBOX_REPO_URL:-https://github.com/OperationAzura/dosboxStagingAccess.git}"
darktext_url="${DARKLANDS_DARKTEXT_REPO_URL:-https://github.com/OperationAzura/darktext.git}"
coords_url="${DARKLANDS_COORDS_REPO_URL:-https://github.com/OperationAzura/darklands-coords.git}"
dosbox_branch="${DARKLANDS_DOSBOX_BRANCH:-darklands-accessibility}"
darktext_branch="${DARKLANDS_DARKTEXT_BRANCH:-main}"
coords_branch="${DARKLANDS_COORDS_BRANCH:-main}"
game_exe="${DARKLANDS_GAME_EXE:-${DARKLANDS_GAME_DIR:-$HOME/dosGames/darklands}/darkland.exe}"

mkdir -p "$source_root" "$bin_dir" "$config_dir" "$data_dir" "$voice_dir"

cat <<EOF

Darklands Accessibility install plan
  Project:       $project_dir
  Install root:  $install_root
  Config:        $config_file
  Game:          $game_exe
  DOSBox branch: $dosbox_branch
  DarkText:      $darktext_branch
  Coords:        $coords_branch
  Voices:        $voice_dir
  User commands: $([[ "$install_user_commands" == "1" ]] && echo YES || echo NO)
  System deps:   $([[ "$install_system_deps" == "1" ]] && echo REQUESTED || echo UNTOUCHED)

EOF

run_as_root()
{
    if [[ ${EUID:-$(id -u)} -eq 0 ]]; then
        "$@"
    elif command -v sudo >/dev/null 2>&1; then
        sudo "$@"
    else
        echo "Root privileges are required for system package installation." >&2
        return 1
    fi
}

missing_debian_dependencies()
{
    local packages=(
        ccache build-essential meson ninja-build git curl python3 python3-venv
        python3-pip alsa-utils libasound2-dev libatomic1 libpng-dev libsdl2-dev
        libasio-dev libopusfile-dev libfluidsynth-dev libslirp-dev
        libspeexdsp-dev libxi-dev
    )
    local missing=() package
    if command -v dpkg-query >/dev/null 2>&1; then
        for package in "${packages[@]}"; do
            dpkg-query -W -f='${Status}' "$package" 2>/dev/null | grep -q '^install ok installed$' || missing+=("$package")
        done
    fi
    printf '%s\n' "${missing[@]}"
}

if ((install_system_deps)); then
    if [[ -r /etc/os-release ]]; then
        # shellcheck disable=SC1091
        . /etc/os-release
        if [[ "${ID:-}" == "debian" || "${ID:-}" == "ubuntu" || " ${ID_LIKE:-} " == *" debian "* ]]; then
            mapfile -t missing < <(missing_debian_dependencies)
            if ((${#missing[@]})); then
                echo "Missing system packages: ${missing[*]}"
                do_install=$assume_yes
                if ((assume_yes == 0)) && [[ -t 0 ]]; then
                    read -r -p "Install them with apt? [y/N] " answer
                    [[ "${answer:-N}" =~ ^[Yy]([Ee][Ss])?$ ]] && do_install=1
                fi
                if ((do_install)); then
                    run_as_root apt-get update
                    run_as_root env DEBIAN_FRONTEND=noninteractive apt-get install -y "${missing[@]}"
                else
                    echo "System packages left unchanged."
                fi
            fi
        else
            echo "Automatic system dependency installation is supported only on Debian/Ubuntu."
        fi
    fi
fi

for command in git python3 curl; do
    command -v "$command" >/dev/null 2>&1 || { echo "Required command not found: $command" >&2; exit 1; }
done
if ((build_dosbox)); then
    for command in meson ninja; do
        command -v "$command" >/dev/null 2>&1 || {
            echo "Required DOSBox build command not found: $command" >&2
            echo "Install build dependencies or rerun with --install-system-deps." >&2
            exit 1
        }
    done
fi

sync_repo()
{
    local url="$1" branch="$2" destination="$3"
    if [[ -d "$destination/.git" ]]; then
        git -C "$destination" fetch origin "$branch"
        git -C "$destination" switch "$branch"
        git -C "$destination" merge --ff-only "origin/$branch"
    elif [[ -e "$destination" ]]; then
        echo "Refusing to overwrite non-Git path: $destination" >&2
        exit 1
    else
        git clone --branch "$branch" "$url" "$destination"
    fi
}

sync_repo "$dosbox_url" "$dosbox_branch" "$dosbox_dir"
sync_repo "$darktext_url" "$darktext_branch" "$darktext_dir"
sync_repo "$coords_url" "$coords_branch" "$coords_dir"

if ! git -C "$dosbox_dir" remote get-url upstream >/dev/null 2>&1; then
    git -C "$dosbox_dir" remote add upstream https://github.com/dosbox-staging/dosbox-staging.git
fi

if ((build_dosbox)); then
    if [[ -f "$dosbox_dir/build/build.ninja" ]]; then
        meson setup --reconfigure "$dosbox_dir/build" "$dosbox_dir" --buildtype=release
    else
        meson setup "$dosbox_dir/build" "$dosbox_dir" --buildtype=release
    fi
    meson compile -C "$dosbox_dir/build"
    ln -sfn "$dosbox_dir/build/dosbox" "$bin_dir/dosbox-staging"
fi

if [[ ! -x "$venv/bin/python" ]]; then
    python3 -m venv "$venv"
fi
"$venv/bin/python" -m pip install --upgrade pip
"$venv/bin/python" -m pip install -e "$darktext_dir" -e "$coords_dir"

# A custom Piper executable can be configured. Otherwise keep Piper inside the
# project venv and expose it only through ./local/bin/piper.
configured_piper="${DARKTEXT_PIPER_BIN:-$bin_dir/piper}"
if [[ "$configured_piper" != "$bin_dir/piper" && -x "$configured_piper" ]]; then
    cat > "$bin_dir/piper" <<EOF
#!/usr/bin/env bash
exec "$configured_piper" "\$@"
EOF
else
    if ! "$venv/bin/python" -c 'import piper' >/dev/null 2>&1; then
        echo "Installing Piper TTS into project venv ($piper_package)..."
        "$venv/bin/python" -m pip install "$piper_package"
    fi
    cat > "$bin_dir/piper" <<EOF
#!/usr/bin/env bash
exec "$venv/bin/python" -m piper "\$@"
EOF
fi
chmod +x "$bin_dir/piper"

# Respect an existing custom ONNX collection. Download the configured default
# only when the selected voice directory contains no models at all.
if ! compgen -G "$voice_dir/*.onnx" >/dev/null; then
    if ! "$venv/bin/python" -c 'import piper' >/dev/null 2>&1; then
        "$venv/bin/python" -m pip install "$piper_package"
    fi
    echo "No ONNX voices found; downloading Piper voice: $piper_voice"
    "$venv/bin/python" -m piper.download_voices --data-dir "$voice_dir" "$piper_voice"
else
    echo "Using existing ONNX voice models in: $voice_dir"
fi

write_tool_wrapper()
{
    local name="$1" target="$2"
    cat > "$bin_dir/$name" <<EOF
#!/usr/bin/env bash
set -a
source "$config_file"
set +a
exec "$target" "\$@"
EOF
    chmod +x "$bin_dir/$name"
}

write_tool_wrapper darktext "$venv/bin/darktext"
write_tool_wrapper darklands-coords "$venv/bin/darklands-coords"

cat > "$bin_dir/darklands" <<EOF
#!/usr/bin/env bash
export DARKLANDS_PROJECT_DIR="$project_dir"
export DARKLANDS_INSTALL_ROOT="$install_root"
export DARKLANDS_CONFIG_FILE="$config_file"
export PATH="$bin_dir:\$PATH"
exec "$project_dir/bin/darklands" "\$@"
EOF
chmod +x "$bin_dir/darklands"

if [[ "$install_user_commands" == "1" ]]; then
    mkdir -p "$user_bin_dir"
    for name in darklands darktext darklands-coords piper; do
        ln -sfn "$bin_dir/$name" "$user_bin_dir/$name"
    done
    if [[ -e "$bin_dir/dosbox-staging" ]]; then
        ln -sfn "$bin_dir/dosbox-staging" "$user_bin_dir/dosbox-staging"
    fi
    echo "User command links installed in: $user_bin_dir"
else
    echo "User command directory left untouched: $user_bin_dir"
fi

cat <<EOF

Darklands Accessibility is ready.
Project-local commands:
  $bin_dir/darklands
  $bin_dir/darktext
  $bin_dir/darklands-coords
  $bin_dir/piper

Configuration:
  $config_file

Nothing in ~/.local/bin was changed unless user-command installation was enabled.
EOF
