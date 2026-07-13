import Foundation

// Long-lived observer: listens for the macOS light/dark appearance-change
// notification and runs sync-terminal-profile.sh to switch the Terminal.app profile.

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
    // AppleInterfaceStyle is updated around the time the notification fires;
    // a short delay makes the `defaults read` in sync-terminal-profile.sh reliable.
    DispatchQueue.main.asyncAfter(deadline: .now() + 0.3, execute: syncTerminalProfile)
}

// Sync once at startup so the profile is correct even if appearance changed
// while the agent wasn't running.
syncTerminalProfile()

RunLoop.main.run()
