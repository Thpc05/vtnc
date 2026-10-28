import QtQuick
import qs.core
import "../../controls"

// Apps → Notifications: the history the Notifications app shows (services/Notifications.qml). How the
// popup looks stays in Appearance → Popups; do not disturb in the app and the bell.
Page {
    id: root

    readonly property var cfg: Store.appOptions.notifications

    Section {
        title: "History"

        SettingRow {
            label: "History size"
            description: "How many notifications it keeps; the oldest go first"
            Stepper {
                value: root.cfg.historySize
                from: 10
                to: 500
                step: 10
                onEdited: v => root.cfg.historySize = v
            }
        }
        SettingRow {
            label: "Keep after a restart"
            description: "Saved as text only (no images or actions)"
            Switch {
                checked: root.cfg.persist
                onToggled: c => root.cfg.persist = c
            }
        }
        SettingRow {
            label: "Keep for"
            Segmented {
                options: [
                    {
                        value: 1,
                        label: "1 day"
                    },
                    {
                        value: 7,
                        label: "7 days"
                    },
                    {
                        value: 30,
                        label: "30 days"
                    },
                    {
                        value: 0,
                        label: "Forever"
                    }
                ]
                value: root.cfg.maxAgeDays
                onSelected: v => root.cfg.maxAgeDays = v
            }
        }
        SettingRow {
            label: "Group by app"
            Switch {
                checked: root.cfg.groupByApp
                onToggled: c => root.cfg.groupByApp = c
            }
        }
    }
}
