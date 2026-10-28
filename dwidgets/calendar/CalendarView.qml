import QtQuick
import qs.kit as K
import qs.dwidgets

// The calendar in the Iwidget family (2026-10-11, redone from scratch in the island's language). Three
// layouts, by the size (Widget.qml):
//  - month (3x3 and up): "Oct 2026", one-letter weekdays and this month's days (MonthView)
//  - week (a row, 4x1 and up): the week's seven days under their letters (WeekView)
//  - day (1x1, 2x1, 1x2, 2x2): today's mark, its weekday and month beside or under it (DayView)
// Looks (the Iwidget meanings):
//  - shapes: plain text (surface / variant), today on an accent M3 shape, a new one each day
//  - tones: the days gone by strong in the tone, the ones to come a weak tone of it, today a rounded
//    square in the tone (the earlier Expressive, the user's reference)
//  - tone: everything in the tone, no fills; today heavier with a bar under it
// Numbers in Rubik, words in Google Sans Flex, caps-centred. The wheel changes the month (or the week),
// a middle click goes back to today; the week starts as the system locale says.
Item {
    id: root

    property string look: "shapes"
    property var pal: K.Kit.bare
    property color tone: pal.accent
    property color overTone: pal.overAccent
    // the days' weight (0: the look's)
    property int weight: 0
    property bool showTitle: true
    property bool showWeekdays: true
    property bool interactive: true
    // month · week · day
    property string layout: "month"

    readonly property var locale: Qt.locale()
    // 0 = Sunday … 6 = Saturday (Qt's firstDayOfWeek is 1 = Monday … 7 = Sunday)
    readonly property int weekStart: locale.firstDayOfWeek % 7

    // today (refreshed each minute, so midnight moves it)
    property date now: new Date()
    Timer {
        interval: 60000
        running: true
        repeat: true
        onTriggered: root.now = new Date()
    }
    readonly property real todayStart: new Date(now.getFullYear(), now.getMonth(), now.getDate()).getTime()

    // the colours per look
    readonly property bool shapes: look === "shapes"
    readonly property color strong: shapes ? pal.over : tone
    readonly property color weak: shapes ? pal.overVariant : Qt.alpha(tone, look === "tone" ? 0.7 : 0.55)
    readonly property color markFill: look === "tone" ? "transparent" : shapes ? pal.accent : tone
    readonly property color markInk: look === "tone" ? tone : shapes ? pal.overAccent : overTone
    readonly property int dayWeight: weight > 0 ? weight : 500
    // a day's colour: Two tones splits gone by (strong) from to come (weak)
    function dayColor(time: real): color {
        return look === "tones" && time >= todayStart ? weak : strong;
    }
    function dayWeightAt(time: real): int {
        return look === "tones" && time < todayStart ? Math.max(600, dayWeight) : dayWeight;
    }

    // today's shape (Shapes): one per day, the same in every copy (no clovers: their lobes crowd the digits);
    // with Random shapes (2026-10-16, user) a random one each time the dashboard opens (in sync with the
    // marks), a new one at midnight
    // the Dwidget's Random shapes option
    property bool randomShapes: true
    readonly property RandomShape todayRandom: RandomShape {
        enabled: root.randomShapes
    }
    readonly property var todayShapes: ["cookie4", "cookie6", "cookie7", "cookie9", "cookie12", "sunny", "softBurst"]
    readonly property string todayShape: todayRandom.enabled ? todayRandom.shape : todayShapes[(now.getFullYear() * 372 + now.getMonth() * 31 + now.getDate()) % todayShapes.length]
    onTodayStartChanged: todayRandom.next()

    // the month (or week) asked for, from the current one; `shown` follows it halfway through the slide
    property int shift: 0
    property int shown: 0
    onLayoutChanged: {
        monthAnim.stop();
        shift = 0;
        shown = 0;
        slide = 0;
        fade = 1;
    }

    property real slide: 0
    property real fade: 1
    property int direction: 1
    onShiftChanged: {
        if (shift === shown)
            return;
        direction = shift > shown ? -1 : 1;
        if (!K.Kit.anim.enabled || !visible) {
            monthAnim.stop();
            shown = shift;
            slide = 0;
            fade = 1;
            return;
        }
        monthAnim.restart();
    }
    SequentialAnimation {
        id: monthAnim
        ParallelAnimation {
            K.Anim {
                target: root
                property: "slide"
                to: K.Kit.padding.extraLarge * root.direction
                type: K.Anim.FastSpatial
            }
            K.Anim {
                target: root
                property: "fade"
                to: 0
                type: K.Anim.FastEffects
            }
        }
        ScriptAction {
            script: {
                root.shown = root.shift;
                root.slide = -K.Kit.padding.extraLarge * root.direction;
            }
        }
        ParallelAnimation {
            K.Anim {
                target: root
                property: "slide"
                to: 0
                type: K.Anim.DefaultSpatial
            }
            K.Anim {
                target: root
                property: "fade"
                to: 1
                type: K.Anim.DefaultEffects
            }
        }
    }

    WheelHandler {
        enabled: root.interactive && root.layout !== "day"
        onWheel: w => root.shift += w.angleDelta.y > 0 ? -1 : 1
    }
    TapHandler {
        enabled: root.interactive
        acceptedButtons: Qt.MiddleButton
        onTapped: root.shift = 0
    }

    Loader {
        anchors.fill: parent
        opacity: root.fade
        transform: Translate {
            x: root.slide
        }
        sourceComponent: root.layout === "week" ? week : root.layout === "day" ? day : month
    }
    Component {
        id: month
        MonthView {
            cal: root
        }
    }
    Component {
        id: week
        WeekView {
            cal: root
        }
    }
    Component {
        id: day
        DayView {
            cal: root
        }
    }
}
