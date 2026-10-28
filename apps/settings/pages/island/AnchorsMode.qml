import QtQuick
import qs.core
import "../../controls"

// One island mode's anchors (island.anchors.<mode>), a Section of Island → Anchors (Anchors.qml).
Section {
    id: modeSection

    property string mode
    readonly property var options: Store.island.anchors[mode]

    SettingRow {
        label: "Anchor center"
        description: "Keep the center widgets in the middle of the island; off packs the sections side by side"
        Switch {
            checked: modeSection.options.anchorCenter
            onToggled: c => modeSection.options.anchorCenter = c
        }
    }
    SettingRow {
        label: "Gap inside"
        description: "Between the widgets of a section"
        Stepper {
            value: modeSection.options.gap
            from: 0
            to: 40
            step: 2
            suffix: " px"
            onEdited: v => modeSection.options.gap = v
        }
    }
    SettingRow {
        label: "Gap between"
        description: "Between the sections (left, center, right)"
        Stepper {
            value: modeSection.options.between
            from: 0
            to: 80
            step: 2
            suffix: " px"
            onEdited: v => modeSection.options.between = v
        }
    }

    Repeater {
        model: [
            {
                name: "left",
                title: "Left card"
            },
            {
                name: "center",
                title: "Center card"
            },
            {
                name: "right",
                title: "Right card"
            }
        ]

        SettingRow {
            required property var modelData
            label: modelData.title
            description: "A card behind the whole section (the cards' color, Appearance → Colors → Cards); its widgets' own cards merge into it"
            Switch {
                checked: modeSection.options[modelData.name].card
                onToggled: c => modeSection.options[modelData.name].card = c
            }
        }
    }
}
