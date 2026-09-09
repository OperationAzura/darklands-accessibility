#!/usr/bin/env bash
set -Eeuo pipefail

script_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
project_dir="$(cd "$script_dir/.." && pwd)"

if [[ -d "$project_dir/.git" ]]; then
    git -C "$project_dir" pull --ff-only
fi

exec "$script_dir/install.sh" "$@"
