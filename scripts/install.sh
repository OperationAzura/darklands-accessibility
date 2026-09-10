#!/usr/bin/env bash
set -Eeuo pipefail

build_dosbox=1
install_system_deps=1
assume_yes=0

usage()
{
    cat <<'EOF'
Usage: ./scripts/install.sh [--skip-system-deps] [--skip-dosbox-build] [--yes]

Set up the Darklands accessibility toolkit. On Debian/Ubuntu systems the
installer can install required system packages with apt, then clone/update the
component repositories, build DOSBox Staging, install the Python tools in a
virtual environment, and place commands in ~/.local/bin.

Options:
  --skip-system-deps   Do not offer to install Debian/Ubuntu apt dependencies
  --skip-dosbox-build  Install/refresh Python tools and launcher without DOSBox
  -y, --yes            Install missing system dependencies without prompting
  -h, --help           Show this help
EOF
}

while (($#)); do
    case "$1" in
        --skip-system-deps)
            install_system_deps=0
            ;;
        --skip-dosbox-build)
            build_dosbox=0
            ;;
        -y|--yes)
            assume_yes=1
            ;;
        -h|--help)
            usage
            exit 0
            ;;
        *)
            echo "Unknown argument: $1" >&2
            usage >&2
            exit 2
            ;;
    esac
    shift
done

script_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
project_dir="$(cd "$script_dir/.." && pwd)"
install_root="${DARKLANDS_INSTALL_ROOT:-$HOME/.local/share/darklands-accessibility}"
source_root="$install_root/src"
venv="$install_root/venv"
bin_dir="${DARKLANDS_BIN_DIR:-$HOME/.local/bin}"
config_home="${DARKLANDS_CONFIG_HOME:-${XDG_CONFIG_HOME:-$HOME/.config}/darklands-accessibility}"
config_file="$config_home/darklands.env"

dosbox_dir="$source_root/dosbox-staging-accessibility"
darktext_dir="$source_root/darktext"
coords_dir="$source_root/darklands-coords"
dosbox_url="${DARKLANDS_DOSBOX_REPO_URL:-https://github.com/OperationAzura/dosboxStagingAccess.git}"
darktext_url="${DARKLANDS_DARKTEXT_REPO_URL:-https://github.com/OperationAzura/darktext.git}"
coords_url="${DARKLANDS_COORDS_REPO_URL:-https://github.com/OperationAzura/darklands-coords.git}"

run_as_root()
{
    if [[ ${EUID:-$(id -u)} -eq 0 ]]; then
        "$@"
    elif command -v sudo >/dev/null 2>&1; then
        sudo "$@"
    else
        echo "Root privileges are required to install system packages." >&2
        echo "Install sudo, run this installer as root, or use --skip-system-deps." >&2
        return 1
    fi
}

install_debian_dependencies()
{
    [[ -r /etc/os-release ]] || return 0

    # shellcheck disable=SC1091
    . /etc/os-release
    local distro_id="${ID:-}"
    local distro_like=" ${ID_LIKE:-} "
    if [[ "$distro_id" != "debian" && "$distro_id" != "ubuntu" && "$distro_like" != *" debian "* ]]; then
        echo "System package auto-install is currently supported on Debian/Ubuntu only."
        return 0
    fi

    local packages=(
        ccache
        build-essential
        meson
        ninja-build
        git
        curl
        python3
        python3-venv
        python3-pip
        alsa-utils
        libasound2-dev
        libatomic1
        libpng-dev
        libsdl2-dev
        libasio-dev
        libopusfile-dev
        libfluidsynth-dev
        libslirp-dev
        libspeexdsp-dev
        libxi-dev
    )

    local missing=()
    local package
    if command -v dpkg-query >/dev/null 2>&1; then
        for package in "${packages[@]}"; do
            if ! dpkg-query -W -f='${Status}' "$package" 2>/dev/null | grep -q '^install ok installed$'; then
                missing+=("$package")
            fi
        done
    else
        missing=("${packages[@]}")
    fi

    if ((${#missing[@]} == 0)); then
        echo "System dependencies already installed."
        return 0
    fi

    echo "Missing Debian/Ubuntu packages: ${missing[*]}"
    if ((assume_yes == 0)); then
        if [[ -t 0 ]]; then
            read -r -p "Install them now with apt? [Y/n] " answer
            case "${answer:-Y}" in
                y|Y|yes|YES|Yes) ;;
                *)
                    echo "Skipping system package installation."
                    return 0
                    ;;
            esac
        else
            echo "Non-interactive session detected; installing missing packages automatically."
        fi
    fi

    run_as_root apt-get update
    run_as_root env DEBIAN_FRONTEND=noninteractive apt-get install -y "${missing[@]}"
}

if ((install_system_deps)); then
    install_debian_dependencies
fi

for command in git python3 curl; do
    if ! command -v "$command" >/dev/null 2>&1; then
        echo "Required command not found: $command" >&2
        echo "Install the dependencies in docs/install.md or rerun without --skip-system-deps on Debian/Ubuntu." >&2
        exit 1
    fi
done

if ((build_dosbox)); then
    for command in meson ninja; do
        if ! command -v "$command" >/dev/null 2>&1; then
            echo "Required DOSBox build command not found: $command" >&2
            echo "Install the dependencies in docs/install.md or use --skip-dosbox-build." >&2
            exit 1
        fi
    done
fi

mkdir -p "$source_root" "$bin_dir" "$config_home"

sync_repo()
{
    local url="$1"
    local branch="$2"
    local destination="$3"

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

sync_repo \
    "$dosbox_url" \
    darklands-accessibility \
    "$dosbox_dir"
sync_repo \
    "$darktext_url" \
    main \
    "$darktext_dir"
sync_repo \
    "$coords_url" \
    main \
    "$coords_dir"

if ! git -C "$dosbox_dir" remote get-url upstream >/dev/null 2>&1; then
    git -C "$dosbox_dir" remote add upstream \
        https://github.com/dosbox-staging/dosbox-staging.git
fi

if ((build_dosbox)); then
    if [[ -f "$dosbox_dir/build/build.ninja" ]]; then
        meson setup --reconfigure "$dosbox_dir/build" "$dosbox_dir" \
            --buildtype=release
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

ln -sfn "$venv/bin/darktext" "$bin_dir/darktext"
ln -sfn "$venv/bin/darklands-coords" "$bin_dir/darklands-coords"
ln -sfn "$project_dir/bin/darklands" "$bin_dir/darklands"

if [[ ! -f "$config_file" ]]; then
    cp "$project_dir/config/darklands.env.example" "$config_file"
    echo "Created configuration: $config_file"
else
    echo "Kept existing configuration: $config_file"
fi

echo
echo "Darklands Accessibility installed."
echo "Commands: $bin_dir/darklands, $bin_dir/darktext, $bin_dir/darklands-coords"
if [[ ":$PATH:" != *":$bin_dir:"* ]]; then
    echo "Add $bin_dir to PATH before using the commands."
fi
echo "Review configuration: $config_file"
