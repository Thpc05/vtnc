import QtQuick
import qs.core
import qs.components
import qs.theme
import "../../controls"

// Appearance → Popups (2026-10-17, OSD and Notifications in one page; the name may change): what the
// island shows for a moment.
//  - Notifications (island.notifications): replace the island or grow under it, expanded on hover or
//    always, the card's look, colour and width. When it shows (per island mode) and do not disturb stay
//    in the bell's options (Island → Layout). Battery warnings (system.json alerts.battery,
//    services/BatteryWarnings.qml) are here too.
//  - OSD: the island turns into a volume / mic / brightness slider for a moment when they change
//    (island/transient/OsdView.qml), over anything, and then goes back to what it was showing.
Page {
    id: root

    readonly property var cfg: Store.island.notifications
    readonly property bool grows: cfg.presentation === "grow"

    Columns {
        Column {
            spacing: Tokens.spacing.l

            Section {
                title: "Notifications"

                SettingRow {
                    label: "Presentation"
                    description: "Replace: the island becomes the notification · Grow: the island grows down and shows it under its content, as wide as the island"
                    Segmented {
                        options: [
                            {
                                value: "replace",
                                label: "Replace"
                            },
                            {
                                value: "grow",
                                label: "Grow"
                            }
                        ]
                        value: root.grows ? "grow" : "replace"
                        onSelected: v => root.cfg.presentation = v
                    }
                }
                SettingRow {
                    label: "Duration"
                    description: "How long a popup stays (a critical one stays until you dismiss it)"
                    Stepper {
                        value: root.cfg.duration || 5
                        from: 1
                        to: 60
                        step: 1
                        suffix: " s"
                        onEdited: v => root.cfg.duration = v
                    }
                }
                SettingRow {
                    label: "Use the app's timeout"
                    description: "Apps that ask for their own time keep it; off: every popup uses Duration"
                    Switch {
                        checked: root.cfg.useAppTimeout ?? true
                        onToggled: c => root.cfg.useAppTimeout = c
                    }
                }
                SettingRow {
                    label: "Expand"
                    description: "The body, the actions and dismiss: on hover or always; the width stays the same"
                    Segmented {
                        options: [
                            {
                                value: "hover",
                                label: "On hover"
                            },
                            {
                                value: "always",
                                label: "Always"
                            }
                        ]
                        value: root.cfg.expand === "always" ? "always" : "hover"
                        onSelected: v => root.cfg.expand = v
                    }
                }
                SettingRow {
                    label: "Expand animation"
                    description: "Slide: the text moves to its place · Fade: it fades out and back in the new layout; the width never changes"
                    Segmented {
                        options: [
                            {
                                value: "slide",
                                label: "Slide"
                            },
                            {
                                value: "fade",
                                label: "Fade"
                            }
                        ]
                        value: root.cfg.animation === "fade" ? "fade" : "slide"
                        onSelected: v => root.cfg.animation = v
                    }
                }
            }

            Section {
                title: "Alerts"

                SettingRow {
                    label: "Battery warnings"
                    description: "A notification as the battery runs down on battery power: 20, 15 and 10%, then every percent from 9 (critical from 5)"
                    Switch {
                        checked: Store.alerts.battery
                        onToggled: c => Store.alerts.battery = c
                    }
                }
            }

            Section {
                title: "Notification card"

                SettingRow {
                    label: "Look"
                    description: "Shapes (the app's icon on a shape), Two tones (the summary in the color, the body a weak tone) or Tone (all in the color); critical ones turn to the error color"
                    Segmented {
                        options: [
                            {
                                value: "shapes",
                                label: "Shapes"
                            },
                            {
                                value: "tones",
                                label: "Two tones"
                            },
                            {
                                value: "tone",
                                label: "Tone"
                            }
                        ]
                        value: root.cfg.style
                        onSelected: v => root.cfg.style = v
                    }
                }
                SettingRow {
                    label: "Color"
                    description: "The card's color (Shapes: the shape and the dots)"
                    Segmented {
                        options: [
                            {
                                value: "primary",
                                label: "Primary"
                            },
                            {
                                value: "surface",
                                label: "Surface"
                            },
                            {
                                value: "variant",
                                label: "Muted"
                            },
                            {
                                value: "secondary",
                                label: "Secondary"
                            },
                            {
                                value: "tertiary",
                                label: "Tertiary"
                            }
                        ]
                        value: root.cfg.color
                        onSelected: v => root.cfg.color = v
                    }
                }
                SettingRow {
                    label: "Minimum width"
                    description: "Short notifications don't get narrower than this; growing, a narrower island widens to the notification's width"
                    Stepper {
                        value: root.cfg.minWidth
                        from: 100
                        // never past the maximum
                        to: root.cfg.maxWidth
                        step: 20
                        suffix: " px"
                        onEdited: v => root.cfg.minWidth = v
                    }
                }
                SettingRow {
                    label: "Maximum width"
                    description: "The notification grows with its text up to this width (never past 90% of the screen)"
                    Stepper {
                        value: root.cfg.maxWidth
                        // never under the minimum
                        from: root.cfg.minWidth
                        to: 1600
                        step: 20
                        suffix: " px"
                        onEdited: v => root.cfg.maxWidth = v
                    }
                }
            }
        }
        Column {
            spacing: Tokens.spacing.l

            Section {
                title: "On-screen display"

                SettingRow {
                    label: "Volume & brightness OSD"
                    description: "The island becomes a slider for a moment when volume, mic or brightness change"
                    Switch {
                        checked: Store.osd.enabled
                        onToggled: c => Store.osd.enabled = c
                    }
                }
                SettingRow {
                    label: "Volume as its widget"
                    description: "Instead of the slider, the volume Iwidget shows for a moment (Duration), as the media does on a new track. It must be in the island's layout, even if hidden in both compact and expanded"
                    opacity: Store.osd.enabled ? 1 : 0.5
                    Switch {
                        checked: Store.osd.volumeWidget
                        onToggled: c => Store.osd.volumeWidget = c
                    }
                }
                // the warning: on, but no volume widget in a column (the slider shows instead)
                Row {
                    readonly property bool missing: Store.osd.volumeWidget && !(Store.island.widgets ?? []).some(w => w.id === "volume" && w.section !== "off")
                    visible: missing
                    x: Tokens.spacing.s
                    spacing: Tokens.spacing.xs

                    Icon {
                        anchors.verticalCenter: parent.verticalCenter
                        icon: Icons.alert
                        size: 14
                        color: Colors.error
                    }
                    StyledText {
                        anchors.verticalCenter: parent.verticalCenter
                        text: "No volume widget in Island → Layout: the slider shows until one is placed (hidden is fine)"
                        font.pixelSize: Tokens.font.small
                        color: Colors.error
                    }
                }
                SettingRow {
                    label: "Not with the volume widget"
                    description: "No volume OSD while the volume Iwidget shows in the island's current mode (compact or expanded; it already shows the level); mic and brightness still show"
                    opacity: Store.osd.enabled && !Store.osd.volumeWidget ? 1 : 0.5
                    Switch {
                        checked: Store.osd.skipWithVolumeWidget
                        onToggled: c => Store.osd.skipWithVolumeWidget = c
                    }
                }
                SettingRow {
                    label: "Duration"
                    description: "How long it stays after the last change; the pointer over the island keeps it"
                    opacity: Store.osd.enabled ? 1 : 0.5
                    Stepper {
                        value: Store.osd.duration
                        from: 500
                        to: 5000
                        step: 100
                        suffix: " ms"
                        onEdited: v => Store.osd.duration = v
                    }
                }
                SettingRow {
                    label: "Fit the island"
                    description: "At 100% the OSD is exactly as wide as the island was (compact or expanded)"
                    opacity: Store.osd.enabled ? 1 : 0.5
                    Switch {
                        checked: Store.osd.fitIsland
                        onToggled: c => Store.osd.fitIsland = c
                    }
                }
                SettingRow {
                    label: "Bar length"
                    description: "Pixels per 1%: the bar is as long as the level (1.4 → 140 px at 100%), and the island grows around it"
                    opacity: Store.osd.enabled && !Store.osd.fitIsland ? 1 : 0.5
                    Stepper {
                        value: Store.osd.pxPerPercent
                        from: 0.5
                        to: 4
                        step: 0.1
                        decimals: 1
                        suffix: " px"
                        onEdited: v => Store.osd.pxPerPercent = v
                    }
                }
            }
        }
    }
}
