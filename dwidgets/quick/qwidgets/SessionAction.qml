import QtQuick
import qs.services
import qs.core
import qs.theme
import ".."
import "../../../apps/session/actions.js" as SessionActions

// One session action (apps/session/actions.js: `sessionAction` is its id), run like the Session app does
// (core/Actions.qml). The ones that end the session (log out, reboot, power off) arm on the first
// click (on, "Again to confirm") and run on a second within 3 s. Lock needs hyprlock.
Qwidget {
    id: root

    property string sessionAction
    readonly property var info: SessionActions.find(sessionAction) ?? ({})
    readonly property bool confirms: info.variant === "error"
    property bool armed: false

    title: info.short ?? info.label ?? ""
    symbol: Icons[info.icon] ?? ""
    icon: Icons[info.icon] ?? ""
    danger: armed
    status: armed ? "Again to confirm" : ""
    available: sessionAction !== "lock" || Session.hasLocker

    function toggle() {
        if (root.confirms && !root.armed) {
            root.armed = true;
            disarm.restart();
            return;
        }
        root.armed = false;
        Actions.runSession(root.sessionAction);
    }

    readonly property Timer disarm: Timer {
        interval: 3000
        onTriggered: root.armed = false
    }
}
