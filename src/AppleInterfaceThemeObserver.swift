import AppKit
import Foundation

// Long-lived observer: listens for the macOS light/dark appearance-change
// notification and runs sync-terminal-profile.sh to switch the Terminal.app profile.

// stdout is a regular file (redirected to observer.log by launchd), which defaults to
// fully-buffered stdio — line-buffer it so log lines show up promptly instead of sitting
// in a buffer for the life of this long-running process.
setvbuf(stdout, nil, _IOLBF, 0)

let syncTerminalProfileScript = ("~/Library/Application Support/macos-terminal-appearance-auto/sync-terminal-profile.sh" as NSString)
    .expandingTildeInPath

var activeSync: Process?
var lastSyncedStyle: String?
var pendingForcedSync = false

func syncTerminalProfile(force: Bool = false) {
    guard activeSync == nil else {
        pendingForcedSync = pendingForcedSync || force
        return
    }
    if force {
        lastSyncedStyle = nil
    }

    guard CFPreferencesSynchronize(
        kCFPreferencesAnyApplication, kCFPreferencesCurrentUser, kCFPreferencesAnyHost
    ) else {
        print("\(Date()) could not refresh system appearance preference")
        return
    }
    let preference = CFPreferencesCopyValue(
        "AppleInterfaceStyle" as CFString,
        kCFPreferencesAnyApplication, kCFPreferencesCurrentUser, kCFPreferencesAnyHost
    )
    let style: String
    if let preference = preference {
        guard let value = preference as? String, value == "Dark" else {
            print("\(Date()) unexpected system appearance preference: \(preference)")
            return
        }
        style = "Dark"
    } else {
        style = "Light"
    }
    guard force || style != lastSyncedStyle else { return }

    let p = Process()
    p.executableURL = URL(fileURLWithPath: "/bin/bash")
    p.arguments = [syncTerminalProfileScript, style]
    p.terminationHandler = { process in
        DispatchQueue.main.async {
            if process.terminationStatus == 0 {
                lastSyncedStyle = style
            } else {
                lastSyncedStyle = nil
                print("\(Date()) profile sync failed with exit status \(process.terminationStatus)")
            }
            activeSync = nil
            if pendingForcedSync {
                pendingForcedSync = false
                syncTerminalProfile(force: true)
            }
        }
    }
    do {
        try p.run()
        activeSync = p
    } catch {
        print("\(Date()) could not start profile sync: \(error)")
    }
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
    // unchanged appearance does not trigger another AppleScript call.
    DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) { syncTerminalProfile() }
    DispatchQueue.main.asyncAfter(deadline: .now() + 2.5) { syncTerminalProfile() }
}

// AppleInterfaceThemeChangedNotification is a live, unqueued distributed notification:
// if the scheduled Auto light/dark switch happens while the Mac is asleep (as it often
// does, e.g. overnight), the notification is lost and never redelivered. Catch that up by
// re-syncing on every wake, in addition to the live notification above.
NSWorkspace.shared.notificationCenter.addObserver(
    forName: NSWorkspace.didWakeNotification,
    object: nil,
    queue: .main
) { _ in
    print("\(Date()) system woke from sleep")
    syncTerminalProfile(force: true)
}

// Sync once at startup so the profile is correct even if appearance changed
// while the agent wasn't running.
syncTerminalProfile(force: true)

// Scheduled Auto changes can happen without a distributed notification, even
// while awake. Reconcile periodically instead of relying on notifications alone.
let reconciliationTimer = Timer(timeInterval: 30, repeats: true) { _ in
    syncTerminalProfile()
}
reconciliationTimer.tolerance = 3
RunLoop.main.add(reconciliationTimer, forMode: .common)

RunLoop.main.run()
