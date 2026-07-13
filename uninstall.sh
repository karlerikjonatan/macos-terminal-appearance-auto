#!/bin/bash
# Removes the Terminal.app appearance auto-switcher: unloads the launchd agent
# and deletes the installed files. Imported Terminal profiles are left alone.

set -euo pipefail

REPO_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
INSTALL_DIR="$HOME/Library/Application Support/macos-terminal-appearance-auto"
LAUNCH_AGENTS_DIR="$HOME/Library/LaunchAgents"

# Resolve the label the same way install.sh does.
if [ -f "$REPO_DIR/config.sh" ]; then
    # shellcheck source=/dev/null
    source "$REPO_DIR/config.sh"
fi
: "${LABEL:=com.$(id -un).macos-terminal-appearance-auto}"

PLIST="$LAUNCH_AGENTS_DIR/$LABEL.plist"

echo "Uninstalling '$LABEL'"

launchctl bootout "gui/$(id -u)/$LABEL" 2>/dev/null || true
rm -f "$PLIST"
rm -rf "$INSTALL_DIR"

echo "Removed the agent and installed files."
echo "Note: the Terminal profiles you imported are still in Terminal >"
echo "Settings > Profiles — remove them there if you no longer want them."
