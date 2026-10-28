import QtQuick
import qs.core
import qs.components
import qs.theme
import "../../controls"

// The battery Iwidget's options (island.battery), shown in the Layout detail panel: the tone (Shapes /
// Two tones / Tone / Ring / Arc), the level it hides above and, in a card per island mode, what it shows.
Column {
    id: root

    readonly property var options: Store.island.battery

    spacing: Tokens.spacing.s

    StyledText {
        text: "Battery"
        font.pixelSize: Tokens.font.small
        font.weight: Font.Bold
        color: Colors.primary
    }
    SettingRow {
        label: "Color"
        description: "Two tones, Tone, Ring and Arc: the mark, the number and the ring in it (error when low)"
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
            value: root.options.color
            onSelected: v => root.options.color = v
        }
    }
    SettingRow {
        label: "Hide above"
        description: "It goes away while the battery is above this level"
        Stepper {
            value: root.options.hideAbove
            from: 0
            to: 95
            step: 5
            firstValue: 50
            specialValueText: "Never"
            suffix: " %"
            onEdited: v => root.options.hideAbove = v
        }
    }

    Row {
        id: columns
        width: root.width
        spacing: Tokens.spacing.s

        Repeater {
            model: [
                {
                    mode: "compact",
                    title: "Compact"
                },
                {
                    mode: "expanded",
                    title: "Expanded"
                }
            ]

            OptionsCard {
                id: card
                required property var modelData
                readonly property var options: root.options[modelData.mode]
                width: (columns.width - columns.spacing) / 2
                title: modelData.title

                SettingRow {
                    label: "Show"
                    description: "The battery's mark (Ring and Arc: the ring), its number, or both"
                    Segmented {
                        options: [
                            {
                                value: "both",
                                label: "Both"
                            },
                            {
                                value: "icon",
                                label: "Icon"
                            },
                            {
                                value: "text",
                                label: "Text"
                            }
                        ]
                        value: card.options.show
                        onSelected: v => card.options.show = v
                    }
                }
            }
        }
    }
}
