# macos-terminal-appearance-auto

Automatically switch **Terminal.app** between a dark and a light profile when
macOS switches between Dark and Light appearance.

Terminal.app has no built-in way to follow the system appearance. This is a
tiny background observer that does: it listens for the system's
appearance-change notification and re-applies the matching Terminal profile to
your open windows. Notification-driven changes normally apply within a fraction
of a second; scheduled Auto changes are also caught by an appearance check every
30 seconds (with up to 3 seconds of timer tolerance).

## Requirements

- macOS
- Xcode Command Line Tools (for `swiftc` — run `xcode-select --install` if needed)
- Two Terminal profiles you want to switch between (one dark, one light) that already exist in **Terminal.app** (built-in or imported in **Terminal → Settings → Profiles**)

## Quick start

1. Ensure your two target profiles already exist in Terminal (built-in or imported via Terminal → Settings → Profiles → ⚙️ → Import…).
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
  notification and every 30 seconds it checks `AppleInterfaceStyle` in-process.
  It runs `sync-terminal-profile.sh` only when appearance differs from the last
  successful sync, and forces a sync at startup and on wake. Failed syncs are
  retried at the next check. The periodic check catches scheduled Auto changes
  that macOS may not announce without launching subprocesses when appearance is
  unchanged. Checks do not wake a sleeping Mac; timer tolerance lets macOS
  coalesce wakeups. Manually selected tab profiles remain until appearance
  changes or a startup/wake sync occurs.
- **`src/sync-terminal-profile.sh`** — accepts the detected appearance from the
  observer (or reads `AppleInterfaceStyle` when run without an argument) and
  applies the matching profile to every open Terminal window via AppleScript.
  It only acts if Terminal is already running, so it never launches Terminal on
  its own.
- **`templates/launch-agent.plist.template`** — rendered per-user by
  `install.sh` into `~/Library/LaunchAgents/<label>.plist` with `RunAtLoad` +
  `KeepAlive`, so the observer is always running across logins. (launchd requires
  absolute paths, so the plist is generated at install time rather than shipped.)

Installed files live under `~/Library/Application Support/macos-terminal-appearance-auto/`
(`AppleInterfaceThemeObserver`, `sync-terminal-profile.sh`, `config`, `observer.log`).

## Troubleshooting

If Terminal stays on the opposite appearance after a scheduled Auto change,
update the source and re-run `./install.sh` to rebuild and reload the observer.
Keep your profile names in `config.sh`; if it is missing, recover them from
`~/Library/Application Support/macos-terminal-appearance-auto/config` before
installing, otherwise the example profile names will be used.

The periodic check should catch up in about 30 seconds once macOS updates its
appearance preference. Check `observer.log` in the installed directory for the
detected `AppleInterfaceStyle`, selected profile, and any AppleScript errors.
If the selected profile is correct but Terminal does not change, confirm that
the profile exists and check **System Settings → Privacy & Security → Automation**
for denied Terminal or System Events access.

## Uninstall

```sh
./uninstall.sh
```

This unloads the agent and removes the installed files.

## License

[MIT](LICENSE)
