import Foundation

// Long-lived observer: listens for the macOS light/dark appearance-change
// notification and runs sync-terminal-profile.sh to switch the Terminal.app profile.

// stdout is a regular file (redirected to observer.log by launchd), which defaults to
// fully-buffered stdio — line-buffer it so log lines show up promptly instead of sitting
// in a buffer for the life of this long-running process.
setvbuf(stdout, nil, _IOLBF, 0)

let syncTerminalProfileScript = ("~/Library/Application Support/macos-terminal-appearance-auto/sync-terminal-profile.sh" as NSString)
    .expandingTildeInPath

func syncTerminalProfile() {
    let p = Process()
    p.executableURL = URL(fileURLWithPath: "/bin/bash")
    p.arguments = [syncTerminalProfileScript]
    try? p.run()
}

let center = DistributedNotificationCenter.default()
center.addObserver(
    forName: NSNotification.Name("AppleInterfaceThemeChangedNotification"),
    object: nil,
    queue: .main
) { _ in
    print("\(Date()) AppleInterfaceThemeChangedNotification received")
    // AppleInterfaceStyle is updated around the time the notification fires;
    // a short delay makes the `defaults read` in sync-terminal-profile.sh reliable
    // for a manual toggle. Automatic (schedule-based) switches have been observed
    // to update the key more slowly, so re-sync again a bit later as a safety net;
    // re-applying the same profile twice is harmless.
    DispatchQueue.main.asyncAfter(deadline: .now() + 0.3, execute: syncTerminalProfile)
    DispatchQueue.main.asyncAfter(deadline: .now() + 2.5, execute: syncTerminalProfile)
}

// Sync once at startup so the profile is correct even if appearance changed
// while the agent wasn't running.
syncTerminalProfile()

RunLoop.main.run()
