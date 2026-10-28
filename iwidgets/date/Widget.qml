import QtQuick
import Quickshell
import qs.core
import qs.kit as K
import qs.iwidgets.clock as Clock

// The date, its own Iwidget (split from the clock, 2026-10-08). Its look and format come from
// island.date (Island → Layout → Date), independent of the clock's: font (default: the kit's,
// Google Sans Flex), weight, size, letter spacing, roundness, colour, background.
Item {
    id: root

    property string style: "default"
    // from the frame: the palette (the island card's, or the bare island's)
    property var pal: K.Kit.bare

    readonly property var options: Store.island.date ?? ({})
    readonly property string format: options.format || "ddd, dd MMM"

    implicitWidth: pill.implicitWidth
    implicitHeight: pill.implicitHeight

    SystemClock {
        id: clock
        precision: SystemClock.Minutes
    }

    Clock.TextPill {
        id: pill
        options: root.options
        pal: root.pal
        defaultFamily: K.Kit.family
        defaultWeight: Font.Medium
        text: Qt.formatDateTime(clock.date, root.format)
    }
}
