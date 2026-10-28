import QtQuick
import Quickshell
import qs.core
import qs.components
import qs.theme
import "../../controls"

// The clock's or the date's options (island.clock / island.date, `which`), shown in the Widgets detail
// panel when that Iwidget is selected. Each is styled on its own (iwidgets/clock/TextPill.qml).
Column {
    id: root

    // "clock" or "date"
    property string which: "clock"
    readonly property bool isClock: which === "clock"
    readonly property var options: Store.island[which]
    // the format's key in the block
    readonly property string formatKey: isClock ? "timeFormat" : "format"

    // presets for the format cycler; their labels are live examples
    readonly property var presets: isClock ? ["HH:mm", "HH:mm:ss", "h:mm AP", "h:mm:ss AP"] : ["ddd, dd MMM", "dddd, d MMMM", "ddd d", "dd/MM", "MM/dd", "yyyy-MM-dd"]

    function formatOptions(presets: var, current: string): var {
        const list = presets.map(f => ({
                    value: f,
                    label: Qt.formatDateTime(now.date, f)
                }));
        if (!presets.includes(current))
            list.push({
                value: current,
                label: "Custom"
            });
        return list;
    }

    SystemClock {
        id: now
        precision: SystemClock.Seconds
    }

    spacing: 0

    StyledText {
        bottomPadding: Tokens.spacing.xs
        text: root.isClock ? "Clock" : "Date"
        font.pixelSize: Tokens.font.small
        font.weight: Font.Bold
        color: Colors.primary
    }

    SettingRow {
        label: "Format"
        description: root.isClock ? "HH hours (h: 12-hour), mm minutes, ss seconds, AP AM/PM" : "ddd / dddd day name, d / dd day, MMM / MMMM month name, MM month, yyyy year"
        Row {
            spacing: Tokens.spacing.s
            Cycler {
                width: root.isClock ? 130 : 170
                options: root.formatOptions(root.presets, root.options[root.formatKey])
                value: root.options[root.formatKey]
                onSelected: v => root.options[root.formatKey] = v
            }
            TextField {
                width: 120
                mono: true
                value: root.options[root.formatKey]
                placeholder: root.presets[0]
                onEdited: v => root.options[root.formatKey] = v
            }
        }
    }
    SettingRow {
        label: "Font"
        description: root.isClock ? "Default: Rubik, the clock font" : "Default: Google Sans Flex, the shell font"
        FontPicker {
            value: root.options.font
            emptyLabel: root.isClock ? "Default (Rubik)" : "Default (Google Sans Flex)"
            onEdited: v => root.options.font = v
        }
    }
    SettingRow {
        label: "Weight"
        Segmented {
            options: [
                {
                    value: 300,
                    label: "Light"
                },
                {
                    value: 400,
                    label: "Regular"
                },
                {
                    value: 500,
                    label: "Medium"
                },
                {
                    value: 600,
                    label: "DemiBold"
                },
                {
                    value: 700,
                    label: "Bold"
                },
                {
                    value: 900,
                    label: "Black"
                }
            ]
            value: root.options.weight
            onSelected: v => root.options.weight = v
        }
    }
    SettingRow {
        label: "Size"
        description: "Theme follows the Appearance font size"
        Stepper {
            value: root.options.size
            from: 0
            to: 28
            firstValue: 10
            specialValueText: "Theme"
            suffix: " px"
            onEdited: v => root.options.size = v
        }
    }
    SettingRow {
        label: "Letter spacing"
        Stepper {
            value: root.options.letterSpacing
            from: -2
            to: 8
            step: 0.5
            decimals: 1
            suffix: " px"
            onEdited: v => root.options.letterSpacing = v
        }
    }
    SettingRow {
        label: "Roundness"
        description: "The font's rounded corners (fonts with a ROND axis, as Google Sans Flex)"
        Stepper {
            value: root.options.roundness
            from: 0
            to: 100
            step: 5
            onEdited: v => root.options.roundness = v
        }
    }
    SettingRow {
        label: "Color"
        description: "Default: the text color of the background behind it"
        Segmented {
            options: [
                {
                    value: "default",
                    label: "Default"
                },
                {
                    value: "variant",
                    label: "Muted"
                },
                {
                    value: "primary",
                    label: "Primary"
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
            value: root.options.color
            onSelected: v => root.options.color = v
        }
    }
    SettingRow {
        label: "Background"
        Segmented {
            options: [
                {
                    value: "none",
                    label: "None"
                },
                {
                    value: "container",
                    label: "Container"
                },
                {
                    value: "tonal",
                    label: "Tonal"
                },
                {
                    value: "primary",
                    label: "Primary"
                }
            ]
            value: root.options.background
            onSelected: v => root.options.background = v
        }
    }
    SettingRow {
        visible: root.options.background !== "none"
        label: "Background rounding"
        Stepper {
            value: root.options.rounding
            from: -1
            to: 16
            firstValue: 0
            specialValueText: "Pill"
            suffix: " px"
            onEdited: v => root.options.rounding = v
        }
    }
}
