#!/usr/bin/env bash
set -euo pipefail

fail() { printf '%s\n' "$*" >&2; exit 1; }

[[ $# == 1 && -f $1 ]] || fail "Usage: bash install.sh /path/to/CiscoPacketTracer.deb"
(( EUID != 0 )) || fail "Run as your desktop user. DNF will request sudo if needed."
package=$(realpath -- "$1")
# shellcheck disable=SC1091
source /etc/os-release
[[ ${ID:-} == fedora && $(uname -m) == x86_64 ]] || fail "Fedora x86_64 is required."
printf 'Fedora %s\n' "${VERSION_ID:-unknown}"

if ! command -v dpkg-deb >/dev/null; then
    sudo dnf install /usr/bin/dpkg-deb
fi
name=$(dpkg-deb -f "$package" Package)
[[ $name == packettracer && $(dpkg-deb -f "$package" Architecture) == amd64 ]] ||
    fail "Expected the Cisco Packet Tracer amd64 package."
version=$(dpkg-deb -f "$package" Version)
base="$HOME/.local/share/packettracer-fedora"
apps="$HOME/.local/share/applications"
mkdir -p -- "$base" "$apps"
exec 9>"$base/.lock"
flock -x 9
first_install=false
if [[ ! -x $base/current/launch ]]; then
    first_install=true
fi
stage=$(mktemp -d "$base/build.XXXXXXXX")
trap 'rm -rf -- "$stage"' EXIT

dpkg-deb -x "$package" "$stage"
app="$stage/opt/pt"
[[ -d $app && ! -L $app ]] || fail "Unsupported package layout. Expected opt/pt."
if [[ -f $app/packettracer.AppImage && -x $app/packettracer.AppImage ]]; then
    format=appimage
    mkdir -p -- "$stage/browser"
    cat > "$stage/browser/xdg-open" <<'OPENER'
#!/usr/bin/bash
# Open web links outside the AppImage's bundled Qt and shared libraries.
unset LD_LIBRARY_PATH LD_PRELOAD QT_PLUGIN_PATH QT_QPA_PLATFORM_PLUGIN_PATH
if [[ $# == 1 && ( $1 == https://* || $1 == http://* ) && -x /usr/bin/firefox ]]; then
    exec /usr/bin/firefox "$1"
fi
exec /usr/bin/xdg-open "$@"
OPENER
    chmod +x "$stage/browser/xdg-open"
elif [[ -f $app/bin/PacketTracer && -x $app/bin/PacketTracer ]]; then
    format=legacy
else
    fail "Unsupported package layout. Expected packettracer.AppImage or bin/PacketTracer in opt/pt."
fi

if [[ $format == legacy ]]; then
    # Resolve missing libraries against the extracted Cisco bundle and Fedora.
    export LD_LIBRARY_PATH="$app/lib"
    report=$(ldd "$app/bin/PacketTracer")
    plugin=$(find "$app" -name libqxcb.so -print -quit)
    if [[ -n $plugin ]]; then
        report+=$'\n'$(ldd "$plugin")
    fi
    mapfile -t missing < <(awk '$2 == "=>" && $3 == "not" {print $1}' <<<"$report" | sort -u)
    if (( ${#missing[@]} )); then
        provides=()
        for library in "${missing[@]}"; do
            [[ $library =~ ^[a-zA-Z0-9_.+-]+$ ]] || fail "Invalid library name: $library"
            provides+=("${library}()(64bit)")
        done
        sudo dnf install "${provides[@]}"
    fi
    if [[ ! -x /usr/bin/Xwayland && -n $plugin ]]; then
        sudo dnf install /usr/bin/Xwayland
    fi
fi

slot=${stage##*/}
printf '%s\n' "$version" > "$stage/version"
cat > "$stage/launch" <<'LAUNCH'
#!/usr/bin/env bash
set -euo pipefail
slot="$(dirname -- "$(realpath -- "$0")")"
app="$slot/opt/pt"
if [[ -x $app/packettracer.AppImage ]]; then
    # Run the vendor bundle without requiring a FUSE mount.
    export APPIMAGE_EXTRACT_AND_RUN=1
    if [[ -x /usr/bin/firefox ]]; then
        export PATH="$slot/browser:$PATH"
        export BROWSER="$slot/browser/xdg-open"
        export XDG_CURRENT_DESKTOP=generic
    fi
    exec "$app/packettracer.AppImage" "$@"
fi
export LD_LIBRARY_PATH="$app/lib"
if [[ ${XDG_SESSION_TYPE:-} == wayland && -z ${QT_QPA_PLATFORM:-} ]]; then
    export QT_QPA_PLATFORM=xcb
fi
cd -- "$app"
exec "$app/bin/PacketTracer" "$@"
LAUNCH
chmod +x "$stage/launch"
desktop=$(mktemp "$apps/.packettracer-fedora.XXXXXXXX")
trap 'rm -f -- "$desktop"; rm -rf -- "$stage"' EXIT
cat > "$desktop" <<'DESKTOP'
[Desktop Entry]
Type=Application
Name=Cisco Packet Tracer
Exec=sh -c "exec ~/.local/share/packettracer-fedora/current/launch"
Icon=applications-internet
Categories=Education;Network;
Terminal=false
DESKTOP

# Keep the previous payload so existing processes can still open its resources.
ln -s -- "$slot" "$stage/current"
mv -fT -- "$desktop" "$apps/packettracer-fedora.desktop"
mv -fT -- "$stage/current" "$base/current"
trap - EXIT
printf 'Packet Tracer %s installed.\n' "$version"
if [[ $format == appimage && $first_install == true && -t 0 && -t 1 &&
      ( -n ${DISPLAY:-} || -n ${WAYLAND_DISPLAY:-} ) ]]; then
    printf 'Starting Packet Tracer. Review the Cisco license if prompted.\n'
    exec 9>&-
    exec "$stage/launch"
fi
if [[ $format == appimage && $first_install == true ]]; then
    printf 'First launch: run "%s/current/launch" in your terminal to review the Cisco license.\n' "$base"
else
    printf 'Launch Packet Tracer from your applications menu.\n'
fi
