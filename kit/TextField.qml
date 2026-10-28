pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Shapes
import qs.theme

// The M3 text field (caelestia's StyledTextField, ported), `type` Outlined or Filled:
//  - the placeholder is the label: it floats up and shrinks to label.small on focus or text
//    (Outlined: into a gap in the outline; Filled: to the top of the field)
//  - Outlined: a 1 px outline, 2 px primary on focus, error when invalid; Filled: a container
//    (Highest on focus) with a 1 → 2 px underline
//  - `leadingIcon` / `trailingIcon` (Material names), `supportingText` under it, `validate` (a
//    RegExp or a function) checked when editing finishes, shown with `errorText`
TextFieldBase {
    id: root

    enum TextFieldType {
        Outlined,
        Filled
    }

    property int type: TextField.Outlined

    property int smallFontSize: Kit.font.label.small.pointSize
    readonly property real smallFontScale: smallFontSize / font.pointSize

    property int verticalPadding: Kit.padding.large
    property int horizontalPadding: Kit.padding.large
    property int radius: Kit.rounding.small
    readonly property int clampedRadius: Math.min(horizontalPadding, Math.min(width, height) / 2, radius)

    property string leadingIcon
    property string trailingIcon
    readonly property int leadingOffset: leadingIcon ? leadingIconLoader.width + leadingIconLoader.anchors.leftMargin : 0
    readonly property int trailingOffset: trailingIcon ? trailingIconLoader.width + trailingIconLoader.anchors.rightMargin : 0

    property string supportingText
    property string errorText
    property bool isError
    property bool emptyIsValid: true
    // a RegExp or a function(text) → bool
    property var validate
    readonly property bool valid: !validate || (!text && emptyIsValid) || (validate instanceof RegExp ? validate.test(text) : !!validate(text))
    readonly property string effectiveSupportingText: isError && errorText ? errorText : supportingText
    readonly property int supportingTextOffset: effectiveSupportingText ? supportingTextLoader.height + Kit.spacing.extraSmall : 0

    readonly property int filledOffset: type === TextField.Filled ? Kit.spacing.small : 0

    leftPadding: horizontalPadding + leadingOffset
    rightPadding: horizontalPadding + trailingOffset
    topPadding: verticalPadding + filledOffset
    bottomPadding: verticalPadding + supportingTextOffset - filledOffset

    onPressed: {
        if (!stateLayer.disabled)
            stateLayer.press(stateLayer.mouseX, stateLayer.mouseY);
    }
    onTextEdited: {
        if (isError)
            isError = false;
    }
    onEditingFinished: {
        if (!valid)
            isError = true;
    }

    background: Loader {
        anchors.fill: parent
        anchors.bottomMargin: root.supportingTextOffset

        sourceComponent: root.type === TextField.Filled ? filledComp : outlineComp

        StateLayer {
            id: stateLayer

            topLeftRadius: root.clampedRadius
            topRightRadius: root.clampedRadius
            radius: root.type === TextField.Outlined ? root.clampedRadius : 0

            cursorShape: Qt.IBeamCursor
            disabled: root.activeFocus
            manualPressOverride: tapHandler.pressed
            onClicked: root.forceActiveFocus()
        }
    }

    Item {
        id: contentWrapper

        anchors.fill: parent
        anchors.bottomMargin: root.supportingTextOffset

        StyledText {
            id: placeholder

            font.family: root.font.family
            font.variableAxes: root.font.variableAxes
            font.pointSize: root.font.pointSize
            font.weight: root.font.weight

            anchors.left: parent.left
            anchors.verticalCenter: parent.verticalCenter
            anchors.leftMargin: root.leftPadding
            anchors.topMargin: Kit.padding.extraSmall
            renderType: Text.QtRendering

            text: root.placeholderText
            color: root.isError ? Colors.error : (root.activeFocus ? Colors.primary : root.text ? Colors.outline : root.placeholderTextColor)

            states: [
                State {
                    name: "smallOutlined"
                    when: root.type === TextField.Outlined && (root.activeFocus || root.text)

                    PropertyChanges {
                        placeholder.scale: root.smallFontScale
                        placeholder.anchors.leftMargin: -(1 - root.smallFontScale) * placeholder.width / 2 + root.horizontalPadding - Kit.spacing.extraSmall
                    }
                    AnchorChanges {
                        target: placeholder
                        anchors.verticalCenter: contentWrapper.top
                    }
                },
                State {
                    name: "smallFilled"
                    when: root.type === TextField.Filled && (root.activeFocus || root.text)

                    PropertyChanges {
                        placeholder.scale: root.smallFontScale
                        placeholder.anchors.leftMargin: -(1 - root.smallFontScale) * placeholder.width / 2 + root.horizontalPadding + root.leadingOffset
                    }
                    AnchorChanges {
                        target: placeholder
                        anchors.top: contentWrapper.top
                        anchors.verticalCenter: undefined
                    }
                }
            ]

            transitions: Transition {
                Anim {
                    properties: "scale,leftMargin"
                    type: Anim.DefaultEffects
                }
                AnchorAnimation {
                    duration: Kit.anim.durations.expressiveDefaultEffects
                    easing.type: Easing.BezierSpline
                    easing.bezierCurve: Kit.anim.expressiveDefaultEffects
                }
            }
        }

        Loader {
            id: leadingIconLoader

            anchors.left: parent.left
            anchors.verticalCenter: parent.verticalCenter
            anchors.leftMargin: Kit.padding.medium
            active: root.leadingIcon

            sourceComponent: MaterialIcon {
                text: root.leadingIcon
                color: Colors.overSurfaceVariant
                size: Math.round(Kit.font.icon.medium.pointSize * 4 / 3 * 0.9)
            }
        }

        Loader {
            id: trailingIconLoader

            anchors.right: parent.right
            anchors.verticalCenter: parent.verticalCenter
            anchors.rightMargin: Kit.padding.medium
            active: root.trailingIcon

            sourceComponent: MaterialIcon {
                text: root.trailingIcon
                color: Colors.overSurfaceVariant
                size: Math.round(Kit.font.icon.medium.pointSize * 4 / 3 * 0.9)
            }
        }
    }

    Loader {
        id: supportingTextLoader

        anchors.bottom: parent.bottom
        anchors.left: parent.left
        anchors.leftMargin: root.horizontalPadding
        active: root.effectiveSupportingText

        sourceComponent: StyledText {
            text: root.effectiveSupportingText
            color: root.isError ? Colors.error : Colors.overSurfaceVariant
            font: Kit.font.label.small
        }
    }

    TapHandler {
        id: tapHandler
    }

    Component {
        id: outlineComp

        Shape {
            id: bg

            preferredRendererType: Shape.CurveRenderer
            asynchronous: true

            ShapePath {
                id: path

                readonly property real outlineGap: placeholder.width * root.smallFontScale + Kit.spacing.extraSmall * 2
                property real outlineGapScale: root.activeFocus || root.text ? 1 : 0
                readonly property real inset: strokeWidth / 2

                strokeWidth: root.activeFocus ? 2 : 1
                strokeColor: root.isError ? Colors.error : (root.activeFocus ? Colors.primary : Colors.outline)
                fillColor: "transparent"
                capStyle: ShapePath.RoundCap

                startX: path.inset + root.horizontalPadding - root.clampedRadius + path.outlineGap * (1 - path.outlineGapScale) / 2 + path.outlineGap * path.outlineGapScale

                PathLine {
                    x: bg.width - path.inset - root.clampedRadius
                }
                PathArc {
                    x: bg.width - path.inset
                    y: path.inset + root.clampedRadius
                    radiusX: root.clampedRadius
                    radiusY: root.clampedRadius
                }
                PathLine {
                    x: bg.width - path.inset
                    y: bg.height - path.inset - root.clampedRadius
                }
                PathArc {
                    x: bg.width - path.inset - root.clampedRadius
                    y: bg.height - path.inset
                    radiusX: root.clampedRadius
                    radiusY: root.clampedRadius
                }
                PathLine {
                    x: path.inset + root.clampedRadius
                    y: bg.height - path.inset
                }
                PathArc {
                    x: path.inset
                    y: bg.height - path.inset - root.clampedRadius
                    radiusX: root.clampedRadius
                    radiusY: root.clampedRadius
                }
                PathLine {
                    x: path.inset
                    y: path.inset + root.clampedRadius
                }
                PathArc {
                    x: path.inset + root.clampedRadius
                    y: path.inset
                    radiusX: root.clampedRadius
                    radiusY: root.clampedRadius
                }
                PathLine {
                    x: path.inset + root.horizontalPadding - root.clampedRadius + path.outlineGap * (1 - path.outlineGapScale) / 2
                }

                Behavior on outlineGapScale {
                    Anim {
                        type: Anim.DefaultEffects
                    }
                }

                Behavior on strokeWidth {
                    Anim {}
                }

                Behavior on strokeColor {
                    CAnim {}
                }
            }
        }
    }

    Component {
        id: filledComp

        StyledRect {
            topLeftRadius: root.clampedRadius
            topRightRadius: root.clampedRadius
            color: root.activeFocus ? Colors.layer(Colors.surfaceContainerHighest, 2) : Colors.layer(Colors.surfaceContainerHigh, 2)

            StyledRect {
                anchors.left: parent.left
                anchors.right: parent.right
                anchors.bottom: parent.bottom
                implicitHeight: root.activeFocus ? 2 : 1
                color: root.isError ? Colors.error : (root.activeFocus ? Colors.primary : Colors.outline)

                Behavior on implicitHeight {
                    Anim {}
                }
            }
        }
    }
}
