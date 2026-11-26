#!/usr/bin/env bash
set -euo pipefail
# shellcheck disable=SC1091
source /etc/os-release
printf 'OS: %s\nArchitecture: %s\nSession: %s\nDISPLAY: %s\n' \
    "${PRETTY_NAME:-unknown}" "$(uname -m)" "${XDG_SESSION_TYPE:-unknown}" "${DISPLAY:-unset}"
base="$HOME/.local/share/packettracer-fedora/current"
[[ -x $base/launch ]] || { echo 'Packet Tracer is not installed by these scripts.' >&2; exit 1; }
app="$base/opt/pt"
printf 'Packet Tracer: %s\n' "$(cat "$base/version")"
export LD_LIBRARY_PATH="$app/lib"
plugin=$(find "$app" -name libqxcb.so -print -quit)
if [[ -n $plugin ]]; then
    printf 'Qt XCB plugin: %s\n' "$plugin"
    binaries=("$app/bin/PacketTracer" "$plugin")
else
    echo 'Qt XCB plugin not found in the bundle.'
    binaries=("$app/bin/PacketTracer")
fi
for binary in "${binaries[@]}"; do
    printf '\n%s\n' "$binary"
    ldd "$binary"
done
if [[ ${1:-} == --qt-debug ]]; then
    QT_DEBUG_PLUGINS=1 exec "$base/launch"
fi
