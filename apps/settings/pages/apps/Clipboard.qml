import QtQuick
import qs.core
import "../../controls"

// Apps → Clipboard: the history kept by cliphist (services/Clipboard.qml).
Page {
    id: root

    readonly property var cfg: Store.appOptions.clipboard

    Section {
        title: "History"

        SettingRow {
            label: "History size"
            description: "How many entries cliphist keeps"
            Stepper {
                value: root.cfg.maxItems
                from: 50
                to: 2000
                step: 50
                onEdited: v => root.cfg.maxItems = v
            }
        }
        SettingRow {
            label: "Keep images"
            description: "Copied images go to the history too"
            Switch {
                checked: root.cfg.images
                onToggled: c => root.cfg.images = c
            }
        }
        SettingRow {
            label: "Preview lines"
            Segmented {
                options: [1, 2].map(n => ({
                            value: n,
                            label: String(n)
                        }))
                value: root.cfg.previewLines
                onSelected: v => root.cfg.previewLines = v
            }
        }
    }
}
