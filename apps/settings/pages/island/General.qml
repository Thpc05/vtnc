import QtQuick
import qs.core
import qs.theme
import "../../controls"

// Island → General: shape (and the Iwidgets' card colour, Kit.islandCard), hover expansion and
// automatic expansion.
Page {
    Columns {
        Section {
            title: "Shape"

            SettingRow {
                label: "Style"
                description: "Notch is attached to the top edge; island floats below it"
                Segmented {
                    options: [
                        {
                            value: "notch",
                            label: "Notch"
                        },
                        {
                            value: "island",
                            label: "Island"
                        }
                    ]
                    value: Store.island.style
                    onSelected: v => Store.island.style = v
                }
            }
            SettingRow {
                label: "Rounding"
                description: "The island's corners, over the theme's (Appearance → General → Scale → Rounding); Theme follows it"
                Stepper {
                    value: (Store.island.rounding ?? -1) < 0 ? -5 : Math.round(Store.island.rounding * 100)
                    from: -5
                    to: 200
                    step: 5
                    suffix: " %"
                    specialValueText: "Theme"
                    firstValue: 0
                    onEdited: v => Store.island.rounding = v < 0 ? -1 : v / 100
                }
            }
            SettingRow {
                label: "Width (compact)"
                description: "Minimum width in compact mode; grows with the widgets"
                Stepper {
                    value: Store.island.minWidth
                    from: 30
                    to: 1200
                    step: 10
                    suffix: " px"
                    onEdited: v => Store.island.minWidth = v
                }
            }
            SettingRow {
                label: "Width (expanded)"
                description: "Minimum width while expanded"
                Stepper {
                    value: Store.island.minWidthExpanded
                    from: 100
                    to: 1600
                    step: 10
                    suffix: " px"
                    onEdited: v => Store.island.minWidthExpanded = v
                }
            }
            SettingRow {
                label: "Height (compact)"
                description: "Height in compact mode"
                Stepper {
                    value: Store.island.height
                    from: 24
                    to: 80
                    step: 2
                    suffix: " px"
                    onEdited: v => Store.island.height = v
                }
            }
            SettingRow {
                label: "Height (expanded)"
                description: "Minimum height while expanded"
                Stepper {
                    value: Store.island.heightExpanded
                    from: 24
                    to: 120
                    step: 2
                    suffix: " px"
                    onEdited: v => Store.island.heightExpanded = v
                }
            }
            SettingRow {
                label: "Side padding"
                Stepper {
                    value: Store.island.padding
                    from: 0
                    to: 40
                    step: 2
                    suffix: " px"
                    onEdited: v => Store.island.padding = v
                }
            }
            SettingRow {
                label: "Gap from the edge"
                description: "Island style only"
                opacity: Store.island.style === "island" ? 1 : 0.5
                Stepper {
                    value: Store.island.margin
                    from: 0
                    to: 30
                    step: 1
                    suffix: " px"
                    onEdited: v => Store.island.margin = v
                }
            }
            SettingRow {
                label: "Reserve space"
                description: "Keep windows from going under the island (exclusive zone)"
                Switch {
                    checked: Store.island.reserveSpace
                    onToggled: c => Store.island.reserveSpace = c
                }
            }
        }

        Column {
            spacing: Tokens.spacing.l

            Section {
                title: "Expansion"

                SettingRow {
                    label: "Expand on hover"
                    description: "Also available through IPC: toggleExpand"
                    Switch {
                        checked: Store.island.expandOnHover
                        onToggled: c => Store.island.expandOnHover = c
                    }
                }
                SettingRow {
                    label: "Hover delay"
                    Stepper {
                        value: Store.island.hoverDelay
                        from: 0
                        to: 2000
                        step: 20
                        suffix: " ms"
                        onEdited: v => Store.island.hoverDelay = v
                    }
                }
                SettingRow {
                    label: "Collapse delay"
                    Stepper {
                        value: Store.island.collapseDelay
                        from: 0
                        to: 5000
                        step: 50
                        suffix: " ms"
                        onEdited: v => Store.island.collapseDelay = v
                    }
                }
            }

            Section {
                title: "Automatic expansion"

                SettingRow {
                    label: "Media"
                    description: "Briefly show the new track"
                    Switch {
                        checked: Store.island.flash.media
                        onToggled: c => Store.island.flash.media = c
                    }
                }
                SettingRow {
                    label: "Media duration"
                    Stepper {
                        value: Store.island.flash.duration
                        from: 500
                        to: 10000
                        step: 250
                        suffix: " ms"
                        onEdited: v => Store.island.flash.duration = v
                    }
                }
            }
        }
    }
}
