import QtQuick
import qs.dwidgets
import qs.kit as K
import "days.js" as Days

// A week in a row (CalendarView's week layout): seven columns, the weekday's letter over its number
// (the letters hide when the Weekdays option is off), today on its mark. The wheel moves a week.
Item {
    id: root

    required property Item cal

    // a day of the week shown
    readonly property date anchorDay: new Date(cal.now.getFullYear(), cal.now.getMonth(), cal.now.getDate() + 7 * cal.shown)
    readonly property var days: Days.week(anchorDay, cal.now, cal.weekStart)

    readonly property real column: width / 7
    readonly property int letterSize: Math.round(K.Kit.clamp(height * 0.2, 9, 12))
    readonly property int letterHeight: cal.showWeekdays ? letterSize + 4 : 0
    readonly property int mark: 2 * Math.floor(Math.min(column * 0.95, height - letterHeight, 36) / 2)
    readonly property int digit: Math.round(Math.min(mark * 0.44, 14))
    // the letters and marks as one block, centred
    readonly property int blockY: Math.round((height - letterHeight - mark) / 2)

    Row {
        Repeater {
            model: root.days

            Item {
                id: cell
                required property var modelData
                width: root.column
                height: root.height

                CapText {
                    visible: root.cal.showWeekdays
                    y: root.blockY
                    width: parent.width
                    height: root.letterSize
                    family: K.Kit.family
                    text: root.cal.locale.dayName(cell.modelData.weekday, Locale.NarrowFormat)
                    pixelSize: root.letterSize
                    weight: 600
                    color: cell.modelData.today ? root.cal.strong : root.cal.weak
                }
                TodayMark {
                    visible: cell.modelData.today
                    cal: root.cal
                    day: cell.modelData.day
                    digit: root.digit
                    width: root.mark
                    height: root.mark
                    x: Math.round((parent.width - width) / 2)
                    y: root.blockY + root.letterHeight
                }
                CapText {
                    visible: !cell.modelData.today
                    y: root.blockY + root.letterHeight
                    width: parent.width
                    height: root.mark
                    text: cell.modelData.day
                    pixelSize: root.digit
                    weight: root.cal.dayWeightAt(cell.modelData.time)
                    color: root.cal.dayColor(cell.modelData.time)
                }
            }
        }
    }
}
