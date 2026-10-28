pragma Singleton

import QtQuick
import Quickshell
import qs.core

// Compat Visibilities: module switching maps to vtnc's apps.
Singleton {
    id: root

    // module name → vtnc app id
    readonly property var moduleToApp: ({
            "launcher": "launcher",
            "dashboard": "dashboard",
            "powermenu": "session",
            "tools": "tools"
        })

    readonly property string currentActiveModule: Object.keys(moduleToApp).find(m => moduleToApp[m] === Runtime.activeApp) ?? ""

    property bool playerMenuOpen: false

    function setActiveModule(name) {
        if (!name)
            Runtime.closeApp();
        else if (moduleToApp[name])
            Runtime.openApp(moduleToApp[name], {});
    }
}
