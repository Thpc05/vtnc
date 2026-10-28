import QtQuick
import QtQuick.Shapes
import QtQuick.Templates as T
import qs.theme

// The M3 switch (caelestia's StyledSwitch, ported): a pill track 1.7 × its height, primary when on
// (a container when off); the thumb grows 1.2 × while pressed and draws a check (on) or a cross
// (off) that morphs through a dash while pressed.
T.Switch {
    id: root

    // the surface layer it sits on (Colors.layer), for the off track
    property int cLayer: 1
    property bool disabled

    enabled: !disabled

    implicitWidth: implicitIndicatorWidth
    implicitHeight: implicitIndicatorHeight

    indicator: StyledRect {
        radius: Kit.rounding.full
        color: {
            if (root.disabled)
                return root.checked ? Qt.alpha(Colors.overSurface, 0.12) : Qt.alpha(Colors.surfaceContainerHighest, 0.38);
            return root.checked ? Colors.primary : Colors.layer(Colors.surfaceContainerHighest, root.cLayer);
        }

        implicitWidth: Math.round(implicitHeight * 1.7)
        implicitHeight: Math.round(Kit.font.body.medium.pointSize + Kit.padding.small * 2)

        StyledRect {
            readonly property real nonAnimWidth: root.pressed ? implicitHeight * 1.2 : implicitHeight

            radius: Kit.rounding.full
            color: {
                if (root.disabled)
                    return root.checked ? Colors.surface : Qt.alpha(Colors.overSurface, 0.12);
                return root.checked ? Colors.overPrimary : Colors.layer(Colors.outline, root.cLayer + 1);
            }

            x: root.checked ? parent.implicitWidth - nonAnimWidth - Kit.padding.extraSmall / 2 : Kit.padding.extraSmall / 2
            implicitWidth: nonAnimWidth
            implicitHeight: parent.implicitHeight - Kit.padding.extraSmall
            anchors.verticalCenter: parent.verticalCenter

            StyledRect {
                anchors.fill: parent
                radius: parent.radius

                color: root.checked ? Colors.primary : Colors.overSurface
                opacity: root.pressed ? 0.1 : root.hovered ? 0.08 : 0

                Behavior on opacity {
                    Anim {
                        type: Anim.DefaultEffects
                    }
                }
            }

            Shape {
                id: icon

                property point start1: {
                    if (root.pressed)
                        return Qt.point(width * 0.2, height / 2);
                    if (root.checked)
                        return Qt.point(width * 0.15, height / 2);
                    return Qt.point(width * 0.15, height * 0.15);
                }
                property point end1: {
                    if (root.pressed)
                        return root.checked ? Qt.point(width * 0.4, height / 2) : Qt.point(width * 0.8, height / 2);
                    if (root.checked)
                        return Qt.point(width * 0.4, height * 0.7);
                    return Qt.point(width * 0.85, height * 0.85);
                }
                property point start2: {
                    if (root.pressed)
                        return root.checked ? Qt.point(width * 0.4, height / 2) : Qt.point(width * 0.2, height / 2);
                    if (root.checked)
                        return Qt.point(width * 0.4, height * 0.7);
                    return Qt.point(width * 0.15, height * 0.85);
                }
                property point end2: {
                    if (root.pressed)
                        return Qt.point(width * 0.8, height / 2);
                    if (root.checked)
                        return Qt.point(width * 0.85, height * 0.2);
                    return Qt.point(width * 0.85, height * 0.15);
                }

                anchors.centerIn: parent
                width: height
                height: Math.max(0, parent.implicitHeight - Kit.padding.medium)
                preferredRendererType: Shape.CurveRenderer
                asynchronous: true

                ShapePath {
                    strokeWidth: Kit.font.body.large.pointSize * 0.15
                    strokeColor: {
                        if (root.disabled)
                            return root.checked ? Colors.outline : Colors.surfaceContainer;
                        return root.checked ? Colors.primary : Colors.surfaceContainerHighest;
                    }
                    fillColor: "transparent"
                    capStyle: Kit.scale.rounding === 0 ? ShapePath.SquareCap : ShapePath.RoundCap

                    startX: icon.start1.x
                    startY: icon.start1.y

                    PathLine {
                        x: icon.end1.x
                        y: icon.end1.y
                    }
                    PathMove {
                        x: icon.start2.x
                        y: icon.start2.y
                    }
                    PathLine {
                        x: icon.end2.x
                        y: icon.end2.y
                    }

                    Behavior on strokeColor {
                        CAnim {}
                    }
                }

                Behavior on start1 {
                    PointAnim {}
                }
                Behavior on end1 {
                    PointAnim {}
                }
                Behavior on start2 {
                    PointAnim {}
                }
                Behavior on end2 {
                    PointAnim {}
                }
            }

            Behavior on x {
                Anim {
                    type: Anim.FastSpatial
                }
            }

            Behavior on implicitWidth {
                Anim {
                    type: Anim.FastSpatial
                }
            }
        }
    }

    HoverHandler {
        cursorShape: root.disabled ? Qt.ArrowCursor : Qt.PointingHandCursor
    }

    component PointAnim: PropertyAnimation {
        duration: Kit.anim.durations.expressiveFastSpatial
        easing.type: Easing.BezierSpline
        easing.bezierCurve: Kit.anim.expressiveFastSpatial
    }
}
