import QtQuick
import qs.core
import qs.components
import qs.theme
import "../../controls"

// The volume Iwidget's options (island.volume), shown in the Layout detail panel: the wave with music and,
// in a card per island mode, the icon and the percent around the slider.
Column {
    id: root

    readonly property var options: Store.island.volume

    spacing: Tokens.spacing.s

    StyledText {
        text: "Volume"
        font.pixelSize: Tokens.font.small
        font.weight: Font.Bold
        color: Colors.primary
    }
    SettingRow {
        label: "Wave with music"
        description: "The slider waves while music plays"
        Switch {
            checked: root.options.wavy
            onToggled: c => root.options.wavy = c
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
                    label: "Icon"
                    description: "The speaker before the slider (a click mutes)"
                    Switch {
                        checked: card.options.icon
                        onToggled: c => card.options.icon = c
                    }
                }
                SettingRow {
                    label: "Percentage"
                    description: "The level after the slider"
                    Switch {
                        checked: card.options.percent
                        onToggled: c => card.options.percent = c
                    }
                }
            }
        }
    }
}
