import QtQuick
import Quickshell
import qs.core
import qs.kit as K

// The time (the date is its own Iwidget, iwidgets/date). Its look and format come from island.clock
// (Island → Layout → Clock): font, weight, size, letter spacing, roundness, colour, background.
Item {
    id: root

    property string style: "time"
    // from the frame: the palette (the island card's, or the bare island's)
    property var pal: K.Kit.bare

    readonly property var options: Store.island.clock ?? ({})
    readonly property string format: options.timeFormat || "HH:mm"

    implicitWidth: pill.implicitWidth
    implicitHeight: pill.implicitHeight

    SystemClock {
        id: clock
        // seconds only when the format shows them
        precision: /s/.test(root.format) ? SystemClock.Seconds : SystemClock.Minutes
    }

    TextPill {
        id: pill
        options: root.options
        pal: root.pal
        text: Qt.formatDateTime(clock.date, root.format)
    }
}
