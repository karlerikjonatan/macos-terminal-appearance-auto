# Copy this file to config.sh and edit the values to match your setup.
#   cp config.example.sh config.sh
#
# config.sh is git-ignored so your personal settings never get committed.

# Names of the two Terminal.app profiles to switch between. These must match
# profiles you have already imported into Terminal (Terminal > Settings > Profiles).
DARK_PROFILE="Clear Dark"
LIGHT_PROFILE="Clear Light"

# Reverse-DNS label for the launchd agent. The default derives a unique label
# from your username; override only if you want a specific identifier.
LABEL="com.$(id -un).macos-terminal-appearance-auto"
