import QtQuick
import qs.dwidgets
import qs.dwidgets.quick
import "../catalog.js" as DCatalog

// The calendar in the Iwidget family (2026-10-11): shapes · tones · tone, each also on the card
// (DwidgetCard), drawn by CalendarView. The size picks the layout: a row 4 cells wide or more is a
// week, 3x3 and up a month, the small ones today. Options: color (the tones' colour role), weight (the
// days'), title and weekdays (show / hide).
Dwidget {
    id: root

    readonly property bool card: DCatalog.isCard("calendar", root.style)
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

    CalendarView {
        anchors.fill: parent
        anchors.margins: cardHost.pad
        look: DCatalog.baseStyle("calendar", root.style)
        pal: cardHost.pal
        tone: colors.tone
        overTone: colors.overTone
        weight: root.options?.weight ?? 0
        showTitle: root.options?.title ?? true
        showWeekdays: root.options?.weekdays ?? true
        randomShapes: root.options?.randomShapes ?? true
        interactive: !root.editing
        layout: root.size.h === 1 && root.size.w >= 4 ? "week" : root.size.w >= 3 && root.size.h >= 3 ? "month" : "day"
    }
}
