import QtQuick
import qs.core
import qs.components
import qs.theme
import "../../controls"

// The media Iwidget's options (island.media), shown in the Layout detail panel: when it goes away, then a
// card per island mode side by side, like the previews: what every style shows (art, title, artist,
// wave), the controls after it, the texts' weights and the width.
Column {
    id: root

    spacing: Tokens.spacing.s

    StyledText {
        text: "Media"
        font.pixelSize: Tokens.font.small
        font.weight: Font.Bold
        color: Colors.primary
    }

    SettingRow {
        label: "Visibility"
        description: "Never: a note icon when nothing plays · No media: it goes away without a player · Paused: also while paused"
        Segmented {
            options: [
                {
                    value: "never",
                    label: "Never"
                },
                {
                    value: "noMedia",
                    label: "No media"
                },
                {
                    value: "paused",
                    label: "Paused"
                }
            ]
            value: Store.island.media.visibility
            onSelected: v => Store.island.media.visibility = v
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
                id: column
                required property var modelData
                readonly property var options: Store.island.media[modelData.mode]
                width: (columns.width - columns.spacing) / 2
                title: modelData.title

                Repeater {
                    model: [
                        {
                            key: "showArt",
                            label: "Art",
                            description: "The cover (Disc: a plain disc with play / pause without it)"
                        },
                        {
                            key: "showTitle",
                            label: "Title",
                            description: "The track's name"
                        },
                        {
                            key: "showArtist",
                            label: "Artist",
                            description: "Its author"
                        },
                        {
                            key: "showWave",
                            label: "Wave",
                            description: "A short progress line, wavy while playing"
                        },
                        {
                            key: "controls",
                            label: "Controls",
                            description: "Previous, next, shuffle / repeat and the player after it (right click the player to pick one)"
                        }
                    ]

                    SettingRow {
                        required property var modelData
                        label: modelData.label
                        description: modelData.description
                        Switch {
                            checked: column.options[modelData.key]
                            onToggled: c => column.options[modelData.key] = c
                        }
                    }
                }
                Repeater {
                    model: [
                        {
                            key: "titleWeight",
                            label: "Title weight"
                        },
                        {
                            key: "artistWeight",
                            label: "Artist weight"
                        }
                    ]

                    SettingRow {
                        required property var modelData
                        label: modelData.label
                        Stepper {
                            value: column.options[modelData.key]
                            from: 100
                            to: 900
                            step: 100
                            onEdited: v => column.options[modelData.key] = v
                        }
                    }
                }
                SettingRow {
                    label: "Width"
                    description: "Auto: its content's; else the texts shorten to fit (the controls included)"
                    Stepper {
                        value: column.options.width
                        from: 0
                        to: 480
                        step: 10
                        firstValue: 120
                        specialValueText: "Auto"
                        suffix: " px"
                        onEdited: v => column.options.width = v
                    }
                }
            }
        }
    }
}
