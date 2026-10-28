import QtQuick
import ".."
import "../mouse.js" as MouseData

// Helper → Mouse (2026-10-17): the clicks that aren't obvious, by place (mouse.js).
HelperList {
    placeholder: "Search clicks…"
    keyWidth: 230
    wrap: true
    note: "The clicks that aren't obvious, by place"
    heroIcon: "mouse"
    heroShape: "cookie6"
    heroTitle: "Mouse and gestures"
    heroText: "Many things do more than a left click: a right click often opens a second action or a menu, the wheel changes values or pages, a middle click dismisses or opens a new window. Here they are, by place."
    sections: MouseData.SECTIONS

    function opened() {
        reset();
    }
}
