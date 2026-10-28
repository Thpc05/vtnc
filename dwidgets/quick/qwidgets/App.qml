import QtQuick
import qs.core
import ".."

// Opens a launch target (core/launch.js): the instance's `config.target` (the App Qwidget, picked in
// the settings), or a fixed `target` (the Settings Qwidget). Its title and icon are the target's.
Qwidget {
    id: root

    property string target: config?.target ?? ""
    readonly property var info: Launch.describe(target)

    title: info.title
    symbol: info.symbol
    image: info.image
    icon: ""
    status: target === "" ? "Pick an app" : "Open"
    available: Launch.valid(target)

    function toggle() {
        Launch.run(root.target);
    }
}
