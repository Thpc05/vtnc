import QtQuick
import qs.base.services
import qs.base.theme
import ".."

Qwidget {
    title: "Do not disturb"
    symbol: Notifications.silent ? "notifications_off" : "notifications"
    icon: Notifications.silent ? Icons.bellSlash : Icons.bell
    active: Notifications.silent

    function toggle() {
        Notifications.silent = !Notifications.silent;
    }
}
