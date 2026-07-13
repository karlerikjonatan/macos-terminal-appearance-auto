# macos-terminal-appearance-auto

Automatically switch **Terminal.app** between a dark and a light profile when
macOS switches between Dark and Light appearance.

Terminal.app has no built-in way to follow the system appearance. This is a
tiny background observer that does: it listens for the system's
appearance-change notification and re-applies the matching Terminal profile to
your open windows within a fraction of a second.

## Requirements

- macOS
- Xcode Command Line Tools (for `swiftc` — run `xcode-select --install` if needed)
- Two Terminal profiles you want to switch between (one dark, one light),
  already imported into **Terminal → Settings → Profiles**

## Quick start

1. Import your two profiles into Terminal (Terminal → Settings → Profiles → ⚙️ → Import…).
2. Configure the profile names:
   ```sh
   cp config.example.sh config.sh
   # edit config.sh so DARK_PROFILE / LIGHT_PROFILE match your profile names
   ```
3. Install:
   ```sh
   ./install.sh
   ```
4. Toggle **System Settings → Appearance** between Light and Dark — open
   Terminal windows follow automatically.

## How it works

macOS does not expose a `launchd` trigger for appearance changes, so a small
resident observer is needed:

- **`src/AppleInterfaceThemeObserver.swift`** — compiled to a binary that subscribes to the
  `AppleInterfaceThemeChangedNotification` distributed notification. On each
  change (and once at startup) it runs `sync-terminal-profile.sh`.
- **`src/sync-terminal-profile.sh`** — reads the current appearance (`AppleInterfaceStyle`) and
  applies the matching profile to every open Terminal window via AppleScript.
  It only acts if Terminal is already running, so it never launches Terminal on
  its own.
- **`templates/launch-agent.plist.template`** — rendered per-user by
  `install.sh` into `~/Library/LaunchAgents/<label>.plist` with `RunAtLoad` +
  `KeepAlive`, so the observer is always running across logins. (launchd requires
  absolute paths, so the plist is generated at install time rather than shipped.)

Installed files live under `~/Library/Application Support/macos-terminal-appearance-auto/`
(`AppleInterfaceThemeObserver`, `sync-terminal-profile.sh`, `config`, `observer.log`).

## Customising

- **Profile names / label**: edit `config.sh` and re-run `./install.sh`.
- **Switching logic**: edit `src/sync-terminal-profile.sh` and re-run `./install.sh`.
- **Observer behaviour**: edit `src/AppleInterfaceThemeObserver.swift` and re-run `./install.sh`
  (it recompiles).

## Uninstall

```sh
./uninstall.sh
```

This unloads the agent and removes the installed files. The Terminal profiles
you imported are left in place — delete them in Terminal → Settings → Profiles
if you no longer want them.

## Limitations

- Terminal.app only; iTerm2, Ghostty, WezTerm and Kitty have native
  appearance-following and don't need this.
- Profiles must be imported once and named to match `config.sh`.
- Existing windows and new ones both follow (new windows via Terminal's
  "default settings", which the switcher updates on each change).

## License

[MIT](LICENSE)
