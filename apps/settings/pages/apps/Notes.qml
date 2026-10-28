import QtQuick
import qs.core
import "../../controls"

// Apps → Notes: the notes' format, the editor and their folder (apps/notes).
Page {
    id: root

    readonly property var cfg: Store.appOptions.notes

    Section {
        title: "Notes"

        SettingRow {
            label: "Format"
            description: "Markdown: a Preview button renders the note · Plain: plain text, never rendered"
            Segmented {
                options: [
                    {
                        value: "markdown",
                        label: "Markdown"
                    },
                    {
                        value: "plain",
                        label: "Plain"
                    }
                ]
                value: root.cfg.format
                onSelected: v => root.cfg.format = v
            }
        }
        SettingRow {
            label: "Open on the preview"
            opacity: root.cfg.format === "markdown" ? 1 : 0.5
            Switch {
                checked: root.cfg.openPreview
                onToggled: c => root.cfg.openPreview = c
            }
        }
        SettingRow {
            label: "Notes folder"
            TextField {
                value: root.cfg.dir
                mono: true
                onEdited: v => root.cfg.dir = v
            }
        }
    }

    Section {
        title: "Editor"

        SettingRow {
            label: "Font"
            Segmented {
                options: [
                    {
                        value: "ui",
                        label: "Interface"
                    },
                    {
                        value: "mono",
                        label: "Monospace"
                    }
                ]
                value: root.cfg.font
                onSelected: v => root.cfg.font = v
            }
        }
        SettingRow {
            label: "Font size"
            Stepper {
                value: root.cfg.fontSize
                from: 10
                to: 24
                step: 1
                suffix: " px"
                onEdited: v => root.cfg.fontSize = v
            }
        }
    }
}
