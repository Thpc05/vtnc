import QtQuick
import qs.core
import qs.components
import qs.theme
import "../../controls"

// The workspaces Iwidget's options (island.workspaces), shown in the Layout detail panel: a General card
// (Two tones / Tone: the label, the focus and how many windows; Pagination takes none), then a card per island mode
// (how many workspaces it shows, fixed or dynamic, and the windows after each).
Column {
    id: root

    readonly property var options: Store.island.workspaces

    spacing: Tokens.spacing.s

    StyledText {
        text: "Workspaces"
        font.pixelSize: Tokens.font.small
        font.weight: Font.Bold
        color: Colors.primary
    }

    OptionsCard {
        width: root.width
        title: "General"

        SettingRow {
            label: "Label"
            description: "Two tones / Tone: each workspace as a dot, its number, a roman numeral or a Japanese numeral"
            Segmented {
                options: [
                    {
                        value: "dot",
                        label: "Dot"
                    },
                    {
                        value: "number",
                        label: "1 2 3"
                    },
                    {
                        value: "roman",
                        label: "I II III"
                    },
                    {
                        value: "japanese",
                        label: "一 二 三"
                    }
                ]
                value: root.options.label
                onSelected: v => root.options.label = v
            }
        }
        SettingRow {
            label: "Focus"
            description: "Two tones / Tone: the focused workspace on a pill (its label and windows) or on a shape under its label only, a new one at each change"
            Segmented {
                options: [
                    {
                        value: "pill",
                        label: "Pill"
                    },
                    {
                        value: "shape",
                        label: "Shape"
                    }
                ]
                value: root.options.focus
                onSelected: v => root.options.focus = v
            }
        }
        SettingRow {
            label: "Windows per workspace"
            description: "Two tones / Tone: at most this many window icons after each workspace"
            Stepper {
                value: root.options.windows.max
                from: 0
                to: 9
                firstValue: 1
                specialValueText: "All"
                onEdited: v => root.options.windows.max = v
            }
        }
    }

    Row {
        id: columns
        width: root.width
        spacing: Tokens.spacing.s

        Repeater {
            model: [
                {
                    key: "compactCount",
                    mode: "compact",
                    title: "Compact"
                },
                {
                    key: "expandedCount",
                    mode: "expanded",
                    title: "Expanded"
                }
            ]

            OptionsCard {
                required property var modelData
                width: (columns.width - columns.spacing) / 2
                title: modelData.title

                SettingRow {
                    label: "Shown"
                    description: "Dynamic: only the occupied ones and the active one; a number: 1 to N always, plus any occupied or active one beyond"
                    Stepper {
                        value: root.options[modelData.key]
                        from: 0
                        to: 20
                        firstValue: 3
                        specialValueText: "Dynamic"
                        onEdited: v => root.options[modelData.key] = v
                    }
                }
                SettingRow {
                    label: "Windows"
                    description: "Two tones / Tone: the windows after each workspace, as the app's kind (a symbol) or its icon"
                    Segmented {
                        options: [
                            {
                                value: "icons",
                                label: "Icons"
                            },
                            {
                                value: "apps",
                                label: "App icons"
                            },
                            {
                                value: "off",
                                label: "None"
                            }
                        ]
                        value: root.options.windows[modelData.mode]
                        onSelected: v => root.options.windows[modelData.mode] = v
                    }
                }
            }
        }
    }
}
