import QtQuick
import qs.core
import qs.components
import qs.theme
import "../../controls"

// The tray Iwidget's options (island.tray), shown in the Layout detail panel: the tint style's colour and,
// in a card per island mode, Compact (the icons folded behind a chevron).
Column {
    id: root

    readonly property var options: Store.island.tray

    spacing: Tokens.spacing.s

    StyledText {
        bottomPadding: Tokens.spacing.xs
        text: "Tray"
        font.pixelSize: Tokens.font.small
        font.weight: Font.Bold
        color: Colors.primary
    }

    SettingRow {
        label: "Tint color"
        description: "The color the Tint style tints the icons with (keeping their shading) (the hovered one turns primary, or the text color when it's primary)"
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
            value: root.options.tintColor
            onSelected: v => root.options.tintColor = v
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
                    label: "Compact"
                    description: "The icons folded behind a small chevron, opening to the side it points (<: left, >: right); a click unfolds them, they fold back when the island collapses"
                    Segmented {
                        options: [
                            {
                                value: "off",
                                label: "Off"
                            },
                            {
                                value: "left",
                                label: "<"
                            },
                            {
                                value: "right",
                                label: ">"
                            }
                        ]
                        value: card.options.fold
                        onSelected: v => card.options.fold = v
                    }
                }
            }
        }
    }
}
