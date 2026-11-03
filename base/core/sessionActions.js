.pragma library

// The session actions (2026-10-11), shared by the Session app (apps/session/View.qml) and the Session
// Qwidgets (one per action, dwidgets/quick/qwidgets.js). `icon` is a property name of theme/Icons.qml;
// `variant: "error"` = it ends the session (a Qwidget asks for a second click). services/Session.qml
// runs them (core/Actions.qml `runSession(id)`).
var ACTIONS = [
    { id: "lock", icon: "lock", label: "Lock" },
    { id: "suspend", icon: "suspend", label: "Suspend" },
    { id: "hibernate", icon: "hibernate", label: "Hibernate" },
    { id: "logout", icon: "logout", label: "Exit Hyprland", short: "Log out", variant: "error" },
    { id: "reboot", icon: "reboot", label: "Reboot", variant: "error" },
    { id: "poweroff", icon: "shutdown", label: "Power off", variant: "error" }
];

function find(id) {
    for (var i = 0; i < ACTIONS.length; i++)
        if (ACTIONS[i].id === id)
            return ACTIONS[i];
    return null;
}
