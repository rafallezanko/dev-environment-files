#!/usr/bin/env bash
# Kompiluje hotkeys.swift do ~/.local/bin/hotkeys, zapisuje LaunchAgent
# (start przy logowaniu, restart po crashu) i (re)startuje go. Odpalaj po
# każdej zmianie hotkeys.conf albo hotkeys.swift. Log: /tmp/hotkeys.log
set -euo pipefail

dir="$(cd "$(dirname "$0")" && pwd)"
bin="$HOME/.local/bin/hotkeys"
label="pl.rafallezanko.hotkeys"
plist="$HOME/Library/LaunchAgents/$label.plist"

mkdir -p "$(dirname "$bin")" "$(dirname "$plist")"
swiftc -O "$dir/hotkeys.swift" -o "$bin"

cat > "$plist" <<EOF
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
  <key>Label</key><string>$label</string>
  <key>ProgramArguments</key>
  <array>
    <string>$bin</string>
    <string>$HOME/.config/hotkeys/hotkeys.conf</string>
  </array>
  <key>RunAtLoad</key><true/>
  <key>KeepAlive</key><true/>
  <key>ProcessType</key><string>Interactive</string>
  <key>StandardErrorPath</key><string>/tmp/hotkeys.log</string>
</dict>
</plist>
EOF

launchctl bootout "gui/$(id -u)/$label" 2>/dev/null || true
: > /tmp/hotkeys.log
launchctl bootstrap "gui/$(id -u)" "$plist"
sleep 1
cat /tmp/hotkeys.log 2>/dev/null | tail -n 20
