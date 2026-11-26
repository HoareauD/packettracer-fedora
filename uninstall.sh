#!/usr/bin/env bash
set -euo pipefail
(( EUID != 0 )) || { echo 'Run as your desktop user.' >&2; exit 1; }
base="$HOME/.local/share/packettracer-fedora"
if [[ -d $base ]]; then
    exec 9>"$base/.lock"
    flock -x 9
    rm -f -- "$base/current"
    find "$base" -mindepth 1 -maxdepth 1 -type d -name 'build.*' -exec rm -rf -- {} +
fi
rm -f -- "$HOME/.local/share/applications/packettracer-fedora.desktop"
