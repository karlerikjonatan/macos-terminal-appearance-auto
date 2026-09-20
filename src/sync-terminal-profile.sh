#!/bin/bash
# Switches Terminal.app to the profile matching the current system appearance.
# Only touches Terminal if it is already running, so it never launches Terminal
# on an appearance change.
#
# Profile names come from the installed config file written by install.sh.

CONFIG="$HOME/Library/Application Support/macos-terminal-appearance-auto/config"
if [ -f "$CONFIG" ]; then
    # shellcheck source=/dev/null
    source "$CONFIG"
fi

: "${DARK_PROFILE:?DARK_PROFILE not set (missing config?)}"
: "${LIGHT_PROFILE:?LIGHT_PROFILE not set (missing config?)}"

STYLE="$(defaults read -g AppleInterfaceStyle 2>/dev/null)"
if [ "$STYLE" = "Dark" ]; then
    PROFILE="$DARK_PROFILE"
else
    PROFILE="$LIGHT_PROFILE"
fi

echo "$(date '+%Y-%m-%d %H:%M:%S.%3N') sync: AppleInterfaceStyle='$STYLE' -> profile='$PROFILE'"

OUT="$(/usr/bin/osascript <<EOF 2>&1
tell application "System Events"
    set isRunning to (exists (processes whose name is "Terminal"))
end tell
if isRunning then
    tell application "Terminal"
        set default settings to settings set "$PROFILE"
        repeat with w in windows
            repeat with t in tabs of w
                set current settings of t to settings set "$PROFILE"
            end repeat
        end repeat
    end tell
end if
EOF
)"
STATUS=$?
if [ -n "$OUT" ] || [ "$STATUS" -ne 0 ]; then
    echo "$(date '+%Y-%m-%d %H:%M:%S.%3N') osascript exit=$STATUS output: $OUT"
fi
