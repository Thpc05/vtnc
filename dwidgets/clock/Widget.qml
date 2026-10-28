import QtQuick
import Quickshell
import qs.dwidgets
import qs.dwidgets.quick
import qs.kit as K
import "../catalog.js" as DCatalog

// The clock (2026-10-27, user; a "single" Dwidget) in the Iwidget family: shapes · tones · tone, each also
// on the card. The hour sits on its mark, as the calendar's today: Shapes an accent M3 shape (with Random
// shapes the dashboard's random one, else a circle), Two tones a square in the tone, Tone the hour heavier;
// the minutes (and seconds) beside it, the date under it when there's room. Numbers in Rubik, caps-centred
// (CapText). Options: color (the tones' role), h24, seconds, date, randomShapes.
Dwidget {
    id: root

    readonly property bool card: DCatalog.isCard("clock", root.style)
    readonly property string look: DCatalog.baseStyle("clock", root.style)
    readonly property bool shapes: look === "shapes"
    readonly property bool h24: root.options?.h24 ?? true
    readonly property bool seconds: root.options?.seconds ?? false
    readonly property bool showDate: root.options?.date ?? true

    DwidgetCard {
        id: cardHost
        anchors.fill: parent
        card: root.card
    }
    ToneColors {
        id: colors
        pal: cardHost.pal
        role: root.options?.color || "primary"
    }
    readonly property var pal: cardHost.pal
    readonly property color strong: shapes ? pal.over : colors.tone
    readonly property color weak: shapes ? pal.overVariant : Qt.alpha(colors.tone, K.Kit.expressive.light ? 0.85 : 0.62)

    RandomShape {
        id: random
        enabled: root.options?.randomShapes ?? true
    }

    SystemClock {
        id: clock
        precision: root.seconds ? SystemClock.Seconds : SystemClock.Minutes
    }

    readonly property string hourText: Qt.formatTime(clock.date, root.h24 ? "HH" : "h")
    readonly property string restText: Qt.formatTime(clock.date, ":mm" + (root.seconds ? ":ss" : "")) + (root.h24 ? "" : " " + Qt.formatTime(clock.date, "AP"))

    // the content rect (the target one, so it doesn't reflow mid-move)
    readonly property real w: root.targetWidth - 2 * cardHost.padFor(root.targetWidth, root.targetHeight)
    readonly property real h: root.targetHeight - 2 * cardHost.padFor(root.targetWidth, root.targetHeight)
    // the time's size: by the height (a date under it takes a share), capped by the width (the hour's mark
    // is about 1.7 em wide, a digit about 0.62 em)
    readonly property bool dateFits: showDate && h >= 110
    readonly property int timePx: Math.max(14, Math.round(Math.min(h * (dateFits ? 0.34 : 0.46), w / (1.9 + restText.length * 0.62))))
    readonly property int markSize: 2 * Math.round(timePx * 0.85)

    Column {
        anchors.centerIn: parent
        spacing: Math.round(root.timePx * 0.3)

        Row {
            anchors.horizontalCenter: parent.horizontalCenter
            spacing: Math.round(root.timePx * 0.08)

            // the hour on its mark
            Item {
                // Tone has no mark: just the hour
                width: root.look === "tone" ? hour.implicitWidth : Math.max(root.markSize, hour.implicitWidth + Math.round(root.timePx * 0.5))
                height: root.markSize

                K.M3Shape {
                    anchors.fill: parent
                    visible: root.shapes
                    shape: random.enabled && random.shape !== "" ? random.shape : "circle"
                    animate: !random.instant
                    color: root.pal.accent
                }
                Rectangle {
                    anchors.fill: parent
                    visible: root.look === "tones"
                    radius: Math.round(height * 0.3)
                    color: colors.tone
                }
                CapText {
                    id: hour
                    anchors.fill: parent
                    text: root.hourText
                    pixelSize: root.timePx
                    weight: root.look === "tone" ? 800 : 600
                    color: root.shapes ? root.pal.overAccent : root.look === "tones" ? colors.overTone : colors.tone
                }
            }
            CapText {
                anchors.verticalCenter: parent.verticalCenter
                height: root.markSize
                text: root.restText
                pixelSize: root.timePx
                weight: 500
                horizontalAlignment: Text.AlignLeft
                color: root.strong
            }
        }
        CapText {
            anchors.horizontalCenter: parent.horizontalCenter
            visible: root.dateFits
            text: Qt.formatDate(clock.date, "dddd, d MMMM")
            family: K.Kit.family
            pixelSize: Math.max(11, Math.round(root.timePx * 0.32))
            weight: 500
            color: root.weak
        }
    }
}
