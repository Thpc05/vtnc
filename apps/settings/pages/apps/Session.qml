import QtQuick
import qs.core
import "../../controls"

// Apps → Session (2026-10-27, from System): the session app's hints.
Page {
    Section {
        title: "App"

        SettingRow {
            label: "Hints"
            description: "Label under the buttons"
            Switch {
                checked: Store.hints.session
                onToggled: c => Store.hints.session = c
            }
        }
    }
}
