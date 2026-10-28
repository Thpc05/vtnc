import QtQuick
import Quickshell
import Quickshell.Io
import Quickshell.Services.UPower
import qs.core

// Battery warnings (2026-10-15, user; caelestia's BatteryMonitor logic): a notification each time the
// battery crosses one of `levels` going down on battery power (once per level; plugging the charger in
// re-arms them all). Crossing several at once (waking from sleep) shows only the lowest; the first reading
// only sets where it starts (a reload or a login doesn't warn). Neutral at 20 / 15 / 10 %, then they get
// chattier; from 5 % they're critical (the error colour, they don't expire).
// UPower acts on its own at 2 % here (/etc/UPower/UPower.conf: PercentageAction 2, CriticalPowerAction
// Auto: hybrid sleep / hibernate). On / off: system.json alerts.battery (Appearance → Popups).
// One for the whole shell (shell.qml). Preview one: qs -c vtnc ipc call battery warn <level>.
Scope {
    id: root

    // level (%) → the notification (the title is just the percentage, user); checked from the lowest up
    readonly property var levels: [
        {
            level: 1,
            title: "1%",
            body: "…"
        },
        {
            level: 2,
            title: "2%",
            body: "…"
        },
        {
            level: 3,
            title: "3%",
            body: "Goodbye… — vtnc"
        },
        {
            level: 4,
            title: "4%",
            body: "I'm dying…"
        },
        {
            level: 5,
            title: "5%",
            // neutral and clear it's the system's doing, not vtnc's (user)
            body: "By default, Arch (UPower) hibernates the system at 2%"
        },
        {
            level: 6,
            title: "6%",
            body: ":("
        },
        {
            level: 7,
            title: "7%",
            body: "POV: my PC when you leave Caffeine on"
        },
        {
            level: 8,
            title: "8%",
            body: "Knock knock… anyone there?"
        },
        {
            level: 9,
            title: "9%",
            body: "Did you see the last warning?"
        },
        {
            level: 10,
            title: "10%",
            body: "Battery low. Time to plug in"
        },
        {
            level: 15,
            title: "15%",
            body: "Battery low"
        },
        {
            level: 20,
            title: "20%",
            body: "Battery low"
        }
    ]
    readonly property int criticalFrom: 5

    readonly property var device: UPower.displayDevice
    readonly property bool enabled: Store.alerts?.battery ?? true
    // the level last seen on battery power (100 = re-armed)
    property real last: 100
    property bool primed: false

    function check() {
        if (!device?.ready || !device.isLaptopBattery)
            return;
        const p = device.percentage * 100;
        if (!primed) {
            primed = true;
            last = UPower.onBattery ? p : 100;
            return;
        }
        if (!UPower.onBattery) {
            last = 100;
            return;
        }
        if (enabled) {
            const hit = levels.find(l => p <= l.level && last > l.level);
            if (hit)
                notify(hit);
        }
        last = p;
    }

    function notify(l) {
        const critical = l.level <= criticalFrom;
        // the icon (-n, the app icon; -i is the image in libnotify 0.8), a Material symbol (the card draws
        // "material:<name>"): the standing battery, one bar while it's only low, empty from 9 % (user)
        const icon = l.level >= 10 ? "battery_1_bar" : "battery_0_bar";
        Quickshell.execDetached(["notify-send", "-a", "Battery", "-n", "material:" + icon, "-u", critical ? "critical" : "normal", l.title, l.body]);
    }

    Connections {
        target: root.device
        function onPercentageChanged() {
            root.check();
        }
        function onReadyChanged() {
            root.check();
        }
    }
    Connections {
        target: UPower
        function onOnBatteryChanged() {
            root.check();
        }
    }
    Component.onCompleted: check()

    IpcHandler {
        target: "battery"
        function warn(level: int): void {
            const l = root.levels.find(x => x.level === level);
            if (l)
                root.notify(l);
        }
    }
}
