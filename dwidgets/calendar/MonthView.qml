import QtQuick
import qs.dwidgets
import qs.kit as K
import "days.js" as Days

// The month (CalendarView's month layout): "Oct 2026" (the month bold, the year weak), one-letter
// weekdays (today's strong) and only this month's days, today on its mark. The text is sized for 6 rows,
// so it doesn't jump between months; this month's rows spread over the height. A click on the title
// goes back to today.
Item {
    id: root

    required property Item cal

    readonly property date first: new Date(cal.now.getFullYear(), cal.now.getMonth() + cal.shown, 1)
    readonly property var days: Days.days(first, cal.now, cal.weekStart)
    // the weeks this month needs (4…6)
    readonly property int rows: Math.ceil((days.findIndex(d => d.current) + new Date(first.getFullYear(), first.getMonth() + 1, 0).getDate()) / 7)
    readonly property int todayColumn: (cal.now.getDay() - cal.weekStart + 7) % 7

    // the title 1.3 slots, the weekdays 0.9, the days 6
    readonly property real titleUnits: cal.showTitle ? 1.3 : 0
    readonly property real weekdayUnits: cal.showWeekdays ? 0.9 : 0
    readonly property real slot: height / (titleUnits + weekdayUnits + 6)
    readonly property real cellWidth: width / 7
    readonly property real cellHeight: (height - slot * (titleUnits + weekdayUnits)) / rows
    readonly property int digit: Math.round(K.Kit.clamp(Math.min(slot * 0.6, cellWidth * 0.52), 10, 30))
    // today's mark may reach past its cell a little (the digits around it leave room)
    readonly property int mark: 2 * Math.floor(Math.min(cellWidth * 1.15, cellHeight * 1.15, digit * 2.4) / 2)

    // Oct 2026 (a click: back to today)
    Item {
        id: title
        visible: root.cal.showTitle
        width: parent.width
        height: Math.round(root.slot * root.titleUnits)

        Row {
            x: Math.round((parent.width - width) / 2)
            height: parent.height
            spacing: Math.round(root.digit * 0.35)

            CapText {
                height: parent.height
                width: implicitWidth
                family: K.Kit.family
                text: root.cal.locale.standaloneMonthName(root.first.getMonth(), Locale.ShortFormat).replace(/^./, c => c.toUpperCase())
                pixelSize: Math.round(root.digit * 1.2)
                weight: 700
                color: root.cal.strong
            }
            CapText {
                height: parent.height
                width: implicitWidth
                family: K.Kit.family
                text: root.first.getFullYear()
                pixelSize: Math.round(root.digit * 1.2)
                weight: 400
                color: root.cal.weak
            }
        }
        MouseArea {
            anchors.fill: parent
            enabled: root.cal.interactive && root.cal.shift !== 0
            cursorShape: Qt.PointingHandCursor
            onClicked: root.cal.shift = 0
        }
    }

    // one-letter weekdays, today's strong
    Row {
        id: weekdays
        visible: root.cal.showWeekdays
        y: title.visible ? title.height : 0

        Repeater {
            model: 7

            CapText {
                required property int index
                width: root.cellWidth
                height: Math.round(root.slot * root.weekdayUnits)
                family: K.Kit.family
                text: root.cal.locale.dayName((root.cal.weekStart + index) % 7, Locale.NarrowFormat)
                pixelSize: Math.round(root.digit * 0.82)
                weight: 600
                color: index === root.todayColumn && root.cal.shown === 0 ? root.cal.strong : root.cal.weak
            }
        }
    }

    Grid {
        y: (title.visible ? title.height : 0) + (weekdays.visible ? weekdays.height : 0)
        columns: 7

        Repeater {
            model: root.days.slice(0, root.rows * 7)

            Item {
                id: cell
                required property var modelData
                readonly property bool today: modelData.today && modelData.current
                readonly property real time: new Date(root.first.getFullYear(), root.first.getMonth(), modelData.day).getTime()
                width: root.cellWidth
                height: root.cellHeight

                TodayMark {
                    visible: cell.today
                    cal: root.cal
                    day: cell.modelData.day
                    digit: root.digit
                    width: root.mark
                    height: root.mark
                    x: Math.round((parent.width - width) / 2)
                    y: Math.round((parent.height - height) / 2)
                }
                CapText {
                    anchors.fill: parent
                    visible: cell.modelData.current && !cell.today
                    text: cell.modelData.day
                    pixelSize: root.digit
                    weight: root.cal.dayWeightAt(cell.time)
                    color: root.cal.dayColor(cell.time)
                }
            }
        }
    }
}
