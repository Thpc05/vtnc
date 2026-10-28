pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Io

// Session actions, shared by the session app and the IPC `session` target.
Singleton {
    id: root

    readonly property var commands: ({
            lock: "hyprlock",
            suspend: "systemctl suspend",
            hibernate: "systemctl hibernate",
            logout: "hyprctl dispatch 'hl.dsp.exit()'",
            reboot: "systemctl reboot",
            poweroff: "systemctl poweroff"
        })

    // lock needs a locker (vtnc doesn't ship a lockscreen yet)
    property bool hasLocker: false

    function run(action: string) {
        const cmd = commands[action];
        if (!cmd || (action === "lock" && !hasLocker))
            return;
        Quickshell.execDetached(["sh", "-c", cmd]);
    }

    Process {
        running: true
        command: ["sh", "-c", "command -v hyprlock"]
        onExited: code => root.hasLocker = code === 0
    }
}
