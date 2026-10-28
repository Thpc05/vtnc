pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Controls as QQC
import qs.theme
import qs.kit as K
import "../controls"

// About → Components: every kit control in every state, to review the caelestia-inspired look
// side by side with caelestia (plan stage 1). Nothing here is saved.
Page {
    id: page

    component Label: K.StyledText {
        width: 110
        height: 36
        verticalAlignment: Text.AlignVCenter
        color: Colors.overSurfaceVariant
        font: K.Kit.font.label.medium
    }

    component Line: Flow {
        width: parent?.width ?? 0
        spacing: K.Kit.spacing.medium
        topPadding: K.Kit.spacing.small
        bottomPadding: K.Kit.spacing.small
    }

    Section {
        title: "Surfaces"

        Line {
            Repeater {
                model: [["page", K.Kit.expressive.page], ["container", K.Kit.expressive.container], ["off", K.Kit.expressive.off], ["high", K.Kit.expressive.high], ["tonal", K.Kit.expressive.tonal], ["on", K.Kit.expressive.on]]

                K.StyledRect {
                    required property var modelData
                    width: 96
                    height: 56
                    radius: K.Kit.rounding.large
                    color: modelData[1]
                    border.width: 1
                    border.color: Colors.outlineVariant

                    K.StyledText {
                        anchors.centerIn: parent
                        text: parent.modelData[0]
                        color: parent.modelData[0] === "on" ? Colors.overPrimary : parent.modelData[0] === "tonal" ? Colors.overSecondaryContainer : Colors.overSurface
                    }
                }
            }
        }
    }

    Section {
        title: "Type"

        Column {
            width: parent.width
            topPadding: K.Kit.spacing.small
            bottomPadding: K.Kit.spacing.small
            spacing: K.Kit.spacing.extraSmall

            K.StyledText {
                text: "Headline · Google Sans Flex, ROND 25"
                font: K.Kit.font.headline.small
            }
            K.StyledText {
                text: "Title large"
                font: K.Kit.font.title.large
            }
            K.StyledText {
                text: "Title medium · the quick brown fox"
                font: K.Kit.font.title.medium
            }
            K.StyledText {
                text: "Body medium · the quick brown fox jumps over the lazy dog"
                font: K.Kit.font.body.medium
            }
            K.StyledText {
                text: "Body small · the default text"
            }
            K.StyledText {
                text: "Label medium"
                font: K.Kit.font.label.medium
                color: Colors.overSurfaceVariant
            }
            K.StyledText {
                text: "mono · 0123456789 {}[]()"
                font: K.Kit.font.mono.medium
            }
            K.StyledText {
                text: "12:34"
                font.family: K.Kit.clockFamily
                font.pointSize: K.Kit.font.headline.medium.pointSize
                font.weight: Font.Bold
                color: Colors.primary
            }
        }
    }

    Section {
        title: "Icon buttons"

        Repeater {
            model: [["Filled", K.ButtonBase.Filled], ["Tonal", K.ButtonBase.Tonal], ["Text", K.ButtonBase.Text]]

            Line {
                id: iconRow
                required property var modelData

                Label {
                    text: iconRow.modelData[0]
                }
                K.IconButton {
                    type: iconRow.modelData[1]
                    icon: "favorite"
                }
                K.IconButton {
                    type: iconRow.modelData[1]
                    icon: "bluetooth"
                    isToggle: true
                }
                K.IconButton {
                    type: iconRow.modelData[1]
                    icon: "wifi"
                    isToggle: true
                    checked: true
                }
                K.IconButton {
                    type: iconRow.modelData[1]
                    icon: "settings"
                    isRound: true
                }
                K.IconButton {
                    type: iconRow.modelData[1]
                    icon: "dark_mode"
                    isToggle: true
                    shapeMorph: true
                    isRound: true
                }
                K.IconButton {
                    type: iconRow.modelData[1]
                    icon: "block"
                    active: false
                }
            }
        }
    }

    Section {
        title: "Text buttons"

        Repeater {
            model: [["Filled", K.ButtonBase.Filled], ["Tonal", K.ButtonBase.Tonal], ["Text", K.ButtonBase.Text]]

            Line {
                id: textRow
                required property var modelData

                Label {
                    text: textRow.modelData[0]
                }
                K.TextButton {
                    type: textRow.modelData[1]
                    text: "Button"
                }
                K.TextButton {
                    type: textRow.modelData[1]
                    text: "Toggle"
                    isToggle: true
                }
                K.TextButton {
                    type: textRow.modelData[1]
                    text: "Round"
                    isRound: true
                }
                K.IconTextButton {
                    type: textRow.modelData[1]
                    icon: "add"
                    text: "Icon + text"
                }
                K.IconTextButton {
                    type: textRow.modelData[1]
                    icon: "check"
                    text: "Toggle"
                    isToggle: true
                    checked: true
                }
                K.TextButton {
                    type: textRow.modelData[1]
                    text: "Disabled"
                    disabled: true
                }
            }
        }
    }

    Section {
        title: "Selection"

        Line {
            Label {
                text: "Switch"
            }
            K.Switch {}
            K.Switch {
                checked: true
            }
            K.Switch {
                disabled: true
            }
            K.Switch {
                disabled: true
                checked: true
            }
        }
        Line {
            Label {
                text: "Radio"
            }
            K.RadioButton {
                text: "One"
                checked: true
            }
            K.RadioButton {
                text: "Two"
            }
            K.RadioButton {
                text: "Three"
            }
        }
        Line {
            Label {
                text: "Menu"
            }
            K.TextButton {
                id: menuButton
                type: K.ButtonBase.Tonal
                text: menu.active?.text ?? "Open"
                onClicked: menu.expanded = !menu.expanded
            }
            K.Menu {
                id: menu
                attachTo: menuButton
                thisSideX: K.Menu.Left
                attachSideX: K.Menu.Left
                marginY: K.Kit.spacing.extraSmall
                items: [
                    K.MenuItem {
                        text: "Automatic"
                        icon: "auto_mode"
                    },
                    K.MenuItem {
                        text: "Light"
                        icon: "light_mode"
                    },
                    K.MenuItem {
                        text: "Dark"
                        icon: "dark_mode"
                        trailingIcon: "check"
                    }
                ]
            }
        }
    }

    Section {
        title: "Sliders"

        Line {
            Label {
                text: "M3Slider"
            }
            K.M3Slider {
                id: flat
                width: 220
                height: 16
                value: 0.4
                onMoved: v => value = v
            }
            K.M3Slider {
                width: 220
                height: 16
                value: flat.value
                wavy: true
                onMoved: v => flat.value = v
            }
        }
    }

    Section {
        title: "Text fields"

        Line {
            K.TextField {
                width: 240
                placeholderText: "Outlined"
                supportingText: "Supporting text"
            }
            K.TextField {
                width: 240
                type: K.TextField.Filled
                placeholderText: "Filled"
                leadingIcon: "person"
            }
            K.TextField {
                width: 240
                placeholderText: "Numbers only"
                trailingIcon: "tag"
                validate: /^[0-9]+$/
                errorText: "Only digits"
            }
        }
        Line {
            K.SearchBar {
                width: 340
                placeholderText: "Search"
            }
        }
    }

    Section {
        title: "Elevation & scroll"

        Line {
            Repeater {
                model: 6

                Item {
                    required property int index
                    width: 64
                    height: 64

                    K.Elevation {
                        anchors.fill: parent
                        anchors.margins: 6
                        radius: K.Kit.rounding.large
                        level: parent.index
                    }
                    K.StyledRect {
                        anchors.fill: parent
                        anchors.margins: 6
                        radius: K.Kit.rounding.large
                        color: K.Kit.expressive.container

                        K.StyledText {
                            anchors.centerIn: parent
                            text: parent.parent.index
                        }
                    }
                }
            }

            K.StyledRect {
                width: 200
                height: 120
                radius: K.Kit.rounding.large
                color: K.Kit.expressive.container
                clip: true

                ListView {
                    id: list
                    anchors.fill: parent
                    anchors.margins: K.Kit.padding.small
                    model: 30
                    delegate: K.StyledText {
                        required property int index
                        text: "Row " + (index + 1)
                        height: 22
                    }
                    QQC.ScrollBar.vertical: K.ScrollBar {
                        flickable: list
                    }
                }
            }
        }
    }

    Section {
        title: "Shapes (click to morph)"

        Line {
            Repeater {
                model: ["circle", "square", "pill", "cookie4", "cookie6", "cookie7", "cookie9", "cookie12", "sunny", "softBurst", "clover4", "clover8"]

                Column {
                    id: shapeCell
                    required property string modelData
                    spacing: 4

                    K.M3Shape {
                        id: shape
                        width: shapeCell.modelData === "pill" ? 72 : 48
                        height: 48
                        shape: shapeCell.modelData
                        color: Colors.primary

                        MouseArea {
                            anchors.fill: parent
                            cursorShape: Qt.PointingHandCursor
                            readonly property var all: ["circle", "square", "cookie9", "sunny", "softBurst", "clover4", "cookie4"]
                            onClicked: shape.shape = all[(all.indexOf(shape.shape) + 1) % all.length]
                        }
                    }
                    K.StyledText {
                        anchors.horizontalCenter: parent.horizontalCenter
                        text: shapeCell.modelData
                        font: K.Kit.font.label.small
                        color: Colors.overSurfaceVariant
                    }
                }
            }
        }
    }
}
