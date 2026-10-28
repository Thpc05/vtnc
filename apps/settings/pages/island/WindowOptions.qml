import QtQuick
import qs.core
import qs.components
import qs.theme
import "../../controls"

// The active window Iwidget's options (island.window), shown in the Layout detail panel: what it shows with
// no window focused (island.window.idle), then a card per island mode side by side, like the previews
// (icon, text, max width, weight).
Column {
    id: root

    spacing: Tokens.spacing.s

    StyledText {
        text: "Active window"
        font.pixelSize: Tokens.font.small
        font.weight: Font.Bold
        color: Colors.primary
    }

    SettingRow {
        label: "With no window"
        description: "Text: the text below, with the image as its mark · Media: the current track with a note (the text when nothing plays)"
        Segmented {
            options: [
                {
                    value: "text",
                    label: "Text"
                },
                {
                    value: "media",
                    label: "Media"
                }
            ]
            value: Store.island.window.idle.show
            onSelected: v => Store.island.window.idle.show = v
        }
    }
    SettingRow {
        label: "Text"
        description: "Shown with no window focused (empty: only the mark)"
        TextField {
            value: Store.island.window.idle.text
            placeholder: "Desktop"
            onEdited: v => Store.island.window.idle.text = v
        }
    }
    SettingRow {
        label: "Image"
        description: "A picture as the text's mark (a path, ~/ works; your avatar, ~/.face, by default); empty or missing: the desktop symbol"
        TextField {
            value: Store.island.window.idle.image
            placeholder: "~/.face"
            mono: true
            onEdited: v => Store.island.window.idle.image = v.trim()
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
                readonly property var options: Store.island.window[modelData.mode]
                width: (columns.width - columns.spacing) / 2
                title: modelData.title

                SettingRow {
                    label: "Icon"
                    description: "The app's icon or symbol before the text"
                    Switch {
                        checked: card.options.showIcon
                        onToggled: c => card.options.showIcon = c
                    }
                }
                SettingRow {
                    label: "Text"
                    description: "The title's parts around its last dash (\"Page — App\"): first, second, all of it (Two tones: the two parts in two tones), or none"
                    Segmented {
                        options: [
                            {
                                value: "first",
                                label: "First"
                            },
                            {
                                value: "second",
                                label: "Second"
                            },
                            {
                                value: "both",
                                label: "Both"
                            },
                            {
                                value: "none",
                                label: "None"
                            }
                        ]
                        value: card.options.text
                        onSelected: v => card.options.text = v
                    }
                }
                SettingRow {
                    label: "Max width"
                    description: "The title shortens past it"
                    Stepper {
                        value: card.options.maxWidth
                        from: 60
                        to: 600
                        step: 20
                        suffix: " px"
                        onEdited: v => card.options.maxWidth = v
                    }
                }
                SettingRow {
                    label: "Weight"
                    description: "The title's (Two tones: at least 700)"
                    Stepper {
                        value: card.options.weight
                        from: 100
                        to: 900
                        step: 100
                        onEdited: v => card.options.weight = v
                    }
                }
            }
        }
    }
}
