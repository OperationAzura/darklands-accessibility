#!/usr/bin/env bash
set -Eeuo pipefail

build_dosbox=1

usage()
{
    cat <<'EOF'
Usage: ./scripts/install.sh [--skip-dosbox-build]

Clone/update the component repositories, build DOSBox Staging, install the
Python tools in a virtual environment, and place commands in ~/.local/bin.
EOF
}

while (($#)); do
    case "$1" in
        --skip-dosbox-build)
            build_dosbox=0
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

for command in git python3 curl; do
    if ! command -v "$command" >/dev/null 2>&1; then
        echo "Required command not found: $command" >&2
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
