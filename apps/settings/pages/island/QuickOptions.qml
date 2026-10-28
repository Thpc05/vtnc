import QtQuick
import qs.core
import qs.components
import qs.theme
import "../../controls"
import "../dashboard"

// The Quick configs Iwidget's options (island.quick), shown in the Layout detail panel: the gap and
// the icons' weight, then which Qwidgets it shows (the dashboard's ItemsOptions, with `island`: no
// panel-only Qwidgets).
Column {
    id: root

    required property var catalog
    required property var entries
    readonly property var options: Store.island.quick

    spacing: 0

    StyledText {
        bottomPadding: Tokens.spacing.xs
        text: "Quick configs"
        font.pixelSize: Tokens.font.small
        font.weight: Font.Bold
        color: Colors.primary
    }
    SettingRow {
        label: "Color"
        description: "Two tones and Tone: the on marks in it, the off icons a weak tone of it"
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
        label: "Gap"
        description: "Space between the toggles"
        Stepper {
            value: root.options.gap
            from: 0
            to: 16
            suffix: " px"
            onEdited: v => root.options.gap = v
        }
    }
    SettingRow {
        label: "Icon weight"
        description: "Default: Shapes 400, Two tones 700. Material Symbols end at 700; heavier is drawn bolder by hand"
        Stepper {
            value: root.options.weight
            from: 0
            to: 1500
            step: 100
            firstValue: 300
            specialValueText: "Default"
            onEdited: v => root.options.weight = v
        }
    }
    ItemsOptions {
        width: root.width
        entry: ({
                options: {
                    items: root.options.items
                }
            })
        catalog: root.catalog
        entries: root.entries
        island: true
        heading: "Qwidgets"
        hint: "What it shows: drag to reorder, click one to remove it or pick its app. They may repeat (panels stay on the dashboard)"
        onEdited: o => root.options.items = o.items
    }
}
