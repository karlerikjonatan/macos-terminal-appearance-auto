#!/bin/bash
# Installs the Terminal.app appearance auto-switcher: compiles the observer,
# installs the runtime files, renders the launchd agent, and loads it.
# Idempotent — safe to re-run after changing config or updating the source.

set -euo pipefail

REPO_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
INSTALL_DIR="$HOME/Library/Application Support/macos-terminal-appearance-auto"
LAUNCH_AGENTS_DIR="$HOME/Library/LaunchAgents"

# ---- 1. Load config -------------------------------------------------------
if [ -f "$REPO_DIR/config.sh" ]; then
    CONFIG_FILE="$REPO_DIR/config.sh"
else
    CONFIG_FILE="$REPO_DIR/config.example.sh"
    echo "note: config.sh not found; using defaults from config.example.sh"
    echo "      (copy it to config.sh and edit to customise)"
fi
# shellcheck source=/dev/null
source "$CONFIG_FILE"

: "${DARK_PROFILE:?DARK_PROFILE must be set in config}"
: "${LIGHT_PROFILE:?LIGHT_PROFILE must be set in config}"
: "${LABEL:=com.$(id -un).macos-terminal-appearance-auto}"

PROGRAM="$INSTALL_DIR/AppleInterfaceThemeObserver"
LOG="$INSTALL_DIR/observer.log"
PLIST="$LAUNCH_AGENTS_DIR/$LABEL.plist"

echo "Installing '$LABEL'"
echo "  dark profile:  $DARK_PROFILE"
echo "  light profile: $LIGHT_PROFILE"

# ---- 2. Runtime config + sync-terminal-profile.sh ----------------------------------------
mkdir -p "$INSTALL_DIR" "$LAUNCH_AGENTS_DIR"

cat > "$INSTALL_DIR/config" <<EOF
DARK_PROFILE="$DARK_PROFILE"
LIGHT_PROFILE="$LIGHT_PROFILE"
EOF

cp "$REPO_DIR/src/sync-terminal-profile.sh" "$INSTALL_DIR/sync-terminal-profile.sh"
chmod +x "$INSTALL_DIR/sync-terminal-profile.sh"

# ---- 3. Compile the observer ----------------------------------------------
echo "Compiling observer..."
swiftc -O "$REPO_DIR/src/AppleInterfaceThemeObserver.swift" -o "$PROGRAM"

# ---- 4. Render the launchd plist -----------------------------------------
sed -e "s|__LABEL__|$LABEL|g" \
    -e "s|__PROGRAM__|$PROGRAM|g" \
    -e "s|__LOG__|$LOG|g" \
    "$REPO_DIR/templates/launch-agent.plist.template" > "$PLIST"
plutil -lint "$PLIST" >/dev/null

# ---- 5. (Re)load the agent -----------------------------------------------
launchctl bootout "gui/$(id -u)/$LABEL" 2>/dev/null || true
launchctl bootstrap "gui/$(id -u)" "$PLIST"

echo
echo "Installed and loaded."
echo "Test it: toggle System Settings > Appearance between Light and Dark."
echo
echo "Reminder: '$DARK_PROFILE' and '$LIGHT_PROFILE' must be imported into"
echo "Terminal (Terminal > Settings > Profiles). Edit config.sh and re-run if"
echo "your profile names differ."
