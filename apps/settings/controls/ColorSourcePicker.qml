import QtQuick
import qs.components
import qs.theme
import "../../../theme/colorRoles.js" as Roles

// Where a color token comes from (theme/colorRoles.js specs), in three tabs:
//  - Roles: every matugen role of the dark and of the light scheme (follow the wallpaper)
//  - Tones: the six tonal palettes × 18 tones (follow the wallpaper)
//  - Hex: a fixed #rrggbb
// `spec` is the current one ("" = Auto); a pick emits `picked(spec)`. Swatches show the colors of
// the wallpaper now.
Column {
    id: root

    property string mode: "dark"
    property string spec: ""
    signal picked(string spec)

    // the swatch under the pointer (its spec), for the label
    property string hovered: ""
    readonly property string shown: hovered !== "" ? hovered : spec

    property string tab: spec.startsWith("tone:") ? "tones" : Roles.isHex(spec) ? "hex" : "roles"
    readonly property var roles: Roles.roles(Colors.data)
    // the swatch size: 18 px, smaller when the tones row doesn't fit (a narrow column)
    readonly property int labelWidth: 72
    readonly property int cell: Math.max(10, Math.min(18, Math.floor((width - labelWidth - 3 * 18) / 18)))

    width: parent?.width ?? 0
    spacing: Tokens.spacing.s

    Flow {
        width: parent.width
        spacing: Tokens.spacing.m

        Segmented {
            options: [
                {
                    value: "roles",
                    label: "Roles"
                },
                {
                    value: "tones",
                    label: "Tones"
                },
                {
                    value: "hex",
                    label: "Hex"
                }
            ]
            value: root.tab
            onSelected: v => root.tab = v
        }
        // what the pointer is on, or the current source
        Row {
            height: 30
            spacing: Tokens.spacing.xs

            Rectangle {
                anchors.verticalCenter: parent.verticalCenter
                width: 14
                height: 14
                radius: 4
                color: Colors.specHex(root.mode, root.shown) || "transparent"
                border.width: 1
                border.color: Colors.outlineVariant
            }
            StyledText {
                anchors.verticalCenter: parent.verticalCenter
                text: Roles.describe(root.shown) + (root.shown !== "" ? "  " + Colors.specHex(root.mode, root.shown) : "")
                font.pixelSize: Tokens.font.small
                color: Colors.outline
            }
        }
    }

    // Roles: the dark scheme's and the light scheme's
    Row {
        visible: root.tab === "roles"
        width: parent.width
        spacing: Tokens.spacing.m

        Repeater {
            model: ["dark", "light"]

            Column {
                id: scheme
                required property string modelData
                width: (parent.width - Tokens.spacing.m) / 2
                spacing: Tokens.spacing.xs

                StyledText {
                    text: scheme.modelData === "dark" ? "Dark scheme" : "Light scheme"
                    font.pixelSize: Tokens.font.small
                    font.weight: Font.Bold
                    color: Colors.overSurfaceVariant
                }
                Flow {
                    width: parent.width
                    spacing: 3

                    Repeater {
                        model: root.roles

                        Swatch {
                            required property string modelData
                            target: scheme.modelData + ":" + modelData
                        }
                    }
                }
            }
        }
    }

    // Tones: a row per palette
    Column {
        visible: root.tab === "tones"
        width: parent.width
        spacing: 3

        Repeater {
            model: Roles.PALETTES

            Row {
                id: palette
                required property string modelData
                spacing: 3

                StyledText {
                    anchors.verticalCenter: parent.verticalCenter
                    width: root.labelWidth
                    text: Roles.describe("tone:" + palette.modelData + ":0").replace(" · tone 0", "")
                    font.pixelSize: Tokens.font.small
                    color: Colors.overSurfaceVariant
                    elide: Text.ElideRight
                }
                Repeater {
                    model: Roles.TONES

                    Swatch {
                        required property int modelData
                        target: "tone:" + palette.modelData + ":" + modelData
                    }
                }
            }
        }
        // the tone numbers under the columns
        Row {
            spacing: 3
            Item {
                width: root.labelWidth
                height: 1
            }
            Repeater {
                model: Roles.TONES
                StyledText {
                    required property int modelData
                    width: root.cell
                    horizontalAlignment: Text.AlignHCenter
                    text: modelData
                    font.pixelSize: 8
                    color: Colors.outline
                }
            }
        }
    }

    // Hex: a fixed color
    Row {
        visible: root.tab === "hex"
        spacing: Tokens.spacing.s

        TextField {
            id: hex
            anchors.verticalCenter: parent.verticalCenter
            implicitWidth: 120
            mono: true
            placeholder: "#rrggbb"
            value: Roles.isHex(root.spec) ? root.spec : ""
            onEdited: v => {
                const s = v.startsWith("#") ? v : "#" + v;
                if (Roles.isHex(s))
                    root.picked(s.toLowerCase());
            }
        }
        StyledText {
            anchors.verticalCenter: parent.verticalCenter
            text: "Fixed: doesn't follow the wallpaper. Enter to apply"
            font.pixelSize: Tokens.font.small
            color: Colors.outline
        }
    }

    // a color to pick: its spec in `target`
    component Swatch: Rectangle {
        id: swatch
        property string target
        readonly property bool current: root.spec === target

        width: root.cell
        height: root.cell
        radius: Math.round(root.cell * 0.28)
        color: Colors.specHex(root.mode, target) || "transparent"
        border.width: current ? 2 : 1
        border.color: current ? Colors.primary : Colors.outlineVariant

        MouseArea {
            anchors.fill: parent
            hoverEnabled: true
            cursorShape: Qt.PointingHandCursor
            onEntered: root.hovered = swatch.target
            onExited: if (root.hovered === swatch.target)
                root.hovered = ""
            onClicked: root.picked(swatch.target)
        }
    }
}
