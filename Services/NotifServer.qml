pragma Singleton
import QtQuick
import Quickshell
import Quickshell.Services.Notifications
import "../Components"

// ═══════════════════════════════════════════
//  NOTIF SERVER — Recebe as notificações do sistema
//  (org.freedesktop.Notifications) e guarda o histórico em dados
//  puros, que sobrevivem à expiração da notificação original.
// ═══════════════════════════════════════════
Singleton {
    id: root

    // Chegou uma nova: o NotifReveal se abre sozinho ao ouvir isto
    signal notified()

    // Histórico (mais recente primeiro)
    readonly property ListModel history: ListModel {}

    // Limpa em cascata, uma por vez, pra ListView animar cada saída
    function clearHistory() {
        clearTimer.start()
    }

    readonly property Timer clearTimer: Timer {
        interval: 50
        repeat: true
        triggeredOnStart: true
        onTriggered: {
            if (root.history.count === 0) {
                stop()
                return
            }
            root.history.remove(0)
        }
    }

    readonly property NotificationServer server: NotificationServer {
        imageSupported: true
        actionsSupported: false
        bodyMarkupSupported: false
        keepOnReload: false

        onNotification: notification => {
            root.history.insert(0, {
                summary: notification.summary,
                body: notification.body,
                appName: notification.appName,
                appIcon: notification.appIcon,
                time: Qt.formatDateTime(new Date(), "HH:mm")
            })
            if (root.history.count > Config.maxNotifHistory)
                root.history.remove(root.history.count - 1)

            root.notified()
        }
    }
}
