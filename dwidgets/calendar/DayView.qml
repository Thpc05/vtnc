import QtQuick
import qs.dwidgets
import qs.kit as K

// Today (CalendarView's day layout): its mark with the weekday (strong) and the month (weak) beside it in
// a wide rect, under it in a tall one, none in a square cell (1x1). The Weekdays / Title options hide
// either line; short names when narrow.
Item {
    id: root

    required property Item cal

    readonly property bool wide: width >= height * 1.5
    // (the mark is at most the height: no loop through `mark`)
    readonly property bool narrow: (wide ? width - Math.min(height, 48) - gap : width) < 90
    readonly property var lines: [cal.showWeekdays ? capital(cal.locale.dayName(cal.now.getDay(), narrow ? Locale.ShortFormat : Locale.LongFormat)) : "", cal.showTitle ? capital(cal.locale.standaloneMonthName(cal.now.getMonth(), narrow ? Locale.ShortFormat : Locale.LongFormat)) : ""].filter(l => l !== "")
    // the texts: beside the mark when wide, under it when tall enough
    readonly property bool texts: lines.length > 0 && (wide ? width - height >= 40 : height >= 90)
    readonly property int strongSize: 13
    readonly property int weakSize: 11
    readonly property int lineGap: 4
    readonly property int textHeight: texts ? (lines.length === 2 ? strongSize + weakSize + lineGap : strongSize) : 0
    readonly property int gap: K.Kit.spacing.medium
    readonly property int mark: 2 * Math.floor((wide ? Math.min(height, 48) : Math.min(width, texts ? height - textHeight - gap : height, 64)) / 2)

    function capital(s: string): string {
        return s.replace(/^./, c => c.toUpperCase());
    }

    TodayMark {
        id: todayMark
        cal: root.cal
        day: root.cal.now.getDate()
        digit: Math.round(root.mark * 0.44)
        width: root.mark
        height: root.mark
        x: root.wide && root.texts ? 0 : Math.round((root.width - width) / 2)
        y: root.wide || !root.texts ? Math.round((root.height - height) / 2) : Math.round((root.height - height - root.gap - root.textHeight) / 2)
    }

    Column {
        visible: root.texts
        x: root.wide ? todayMark.width + root.gap : 0
        y: root.wide ? Math.round((root.height - height) / 2) : todayMark.y + todayMark.height + root.gap
        width: root.wide ? root.width - x : root.width
        spacing: root.lineGap

        Repeater {
            model: root.lines

            CapText {
                required property string modelData
                required property int index
                width: parent.width
                height: index === 0 ? root.strongSize : root.weakSize
                family: K.Kit.family
                horizontalAlignment: root.wide ? Text.AlignLeft : Text.AlignHCenter
                text: modelData
                pixelSize: index === 0 ? root.strongSize : root.weakSize
                weight: index === 0 ? 700 : 500
                color: index === 0 ? root.cal.strong : root.cal.weak
            }
        }
    }
}
