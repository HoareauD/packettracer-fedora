# Packet Tracer on Fedora

[Français](README.fr.md)

Community installer for Fedora x86_64 with DNF. Packet Tracer 9.0.1 was tested on Fedora 45 with KDE and Wayland. Install Firefox with `sudo dnf install firefox` if needed for Cisco sign-in.

Download the Ubuntu 64-bit `.deb` from [Cisco Networking Academy](https://www.netacad.com/resources/lab-downloads). Review Cisco’s license terms before using the software. The repository contains MIT-licensed scripts and documentation. Obtain Packet Tracer separately from Cisco.

```bash
git clone https://github.com/HoareauD/packettracer-fedora.git
cd packettracer-fedora
bash install.sh ~/Downloads/CiscoPacketTracer_example.deb
bash doctor.sh
bash update.sh ~/Downloads/CiscoPacketTracer_new.deb
bash uninstall.sh
```

Packet Tracer starts automatically on a fresh install from a terminal in your desktop session. If you installed it without an interactive terminal, run the command below for the first launch. Review the Cisco license and choose whether to accept or decline it. Keep Packet Tracer open while signing in through Firefox. You can then launch it from the applications menu.

```bash
"$HOME/.local/share/packettracer-fedora/current/launch"
```

Use the actual filenames from your Downloads folder. Run as your desktop user. DNF may request administrator access to install missing packages. The scripts extract the `opt/pt` payload and add a launcher to the GNOME or KDE applications menu. Wayland sessions use Qt's XCB backend via XWayland by default. Use `bash doctor.sh --qt-debug` to diagnose Qt plugin loading.

Updates keep earlier payloads for any running process. Uninstall removes the managed payloads and menu launcher. DNF packages and your personal saves remain available.
