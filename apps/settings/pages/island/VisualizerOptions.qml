import QtQuick
import qs.core
import qs.components
import qs.theme
import "../../controls"

// The visualizer Iwidget's options (island.visualizer), shown in the Layout detail panel: a General card
// (colour, source), then a card per island mode side by side, like the previews (bars, max / min
// height, width).
Column {
    id: root

    spacing: Tokens.spacing.s

    StyledText {
        text: "Visualizer"
        font.pixelSize: Tokens.font.small
        font.weight: Font.Bold
        color: Colors.primary
    }

    OptionsCard {
        width: root.width
        title: "General"

        SettingRow {
            label: "Color"
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
                value: Store.island.visualizer.color
                onSelected: v => Store.island.visualizer.color = v
            }
        }
        SettingRow {
            label: "Source"
            description: "Music: the sound itself (cava). Random: a made-up rhythm, only while something plays"
            Segmented {
                options: [
                    {
                        value: "music",
                        label: "Music"
                    },
                    {
                        value: "random",
                        label: "Random"
                    }
                ]
                value: Store.island.visualizer.source
                onSelected: v => Store.island.visualizer.source = v
            }
        }
        SettingRow {
            label: "Dot threshold"
            description: "Dots: the level a dot lights up at (lower: more dots on)"
            Stepper {
                value: Store.island.visualizer.dotThreshold
                from: 5
                to: 95
                step: 5
                suffix: " %"
                onEdited: v => Store.island.visualizer.dotThreshold = v
            }
        }
        SettingRow {
            label: "Shape threshold"
            description: "Shapes: the level it starts moving at (higher: only the loud parts move it)"
            Stepper {
                value: Store.island.visualizer.shapeThreshold
                from: 0
                to: 90
                step: 5
                suffix: " %"
                onEdited: v => Store.island.visualizer.shapeThreshold = v
            }
        }
        SettingRow {
            label: "Always show"
            description: "Never collapses: flat while nothing plays"
            Switch {
                checked: Store.island.visualizer.alwaysShow
                onToggled: c => Store.island.visualizer.alwaysShow = c
            }
        }
        SettingRow {
            label: "Hide after"
            description: "How long it waits without music before it collapses"
            opacity: Store.island.visualizer.alwaysShow ? 0.5 : 1
            Stepper {
                value: Store.island.visualizer.hideDelay
                from: 0
                to: 60
                suffix: " s"
                onEdited: v => Store.island.visualizer.hideDelay = v
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
                readonly property var options: Store.island.visualizer[modelData.mode]
                width: (columns.width - columns.spacing) / 2
                height: Math.max(implicitHeight, columns.tallest)
                title: modelData.title

                SettingRow {
                    label: "Bars"
                    description: "How many levels it draws"
                    Stepper {
                        value: card.options.bars
                        from: 4
                        to: 48
                        step: 2
                        onEdited: v => card.options.bars = v
                    }
                }
                SettingRow {
                    label: "Max height"
                    description: "The tallest a bar gets (Bars)"
                    Stepper {
                        value: card.options.maxHeight
                        from: 6
                        to: 28
                        step: 2
                        suffix: " px"
                        onEdited: v => card.options.maxHeight = v
                    }
                }
                SettingRow {
                    label: "Min height"
                    description: "What a silent bar keeps (Bars; 0: it vanishes)"
                    Stepper {
                        value: card.options.minHeight
                        from: 0
                        to: card.options.maxHeight
                        step: 2
                        suffix: " px"
                        onEdited: v => card.options.minHeight = v
                    }
                }
                SettingRow {
                    label: "Width"
                    description: "Auto: from the bars"
                    Stepper {
                        value: card.options.width
                        from: 0
                        to: 400
                        step: 10
                        firstValue: 40
                        specialValueText: "Auto"
                        suffix: " px"
                        onEdited: v => card.options.width = v
                    }
                }
            }
        }

        // both cards as tall as the taller one
        readonly property real tallest: {
            let h = 0;
            for (const c of children)
                if (c.implicitHeight !== undefined && c.title !== undefined)
                    h = Math.max(h, c.implicitHeight);
            return h;
        }
    }
}
