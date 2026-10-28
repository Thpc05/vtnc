import QtQuick
import qs.dwidgets.quick.panels
import qs.kit as K

// A titled group of SettingRows, in the apps' look (R1.5, 2026-10-17; was a caelestia card): bare on the
// page like the finished apps and the Quick panels, the title a small weak caption with a hairline to
// the right edge (the panels' PanelSection).
Column {
    id: root

    property string title: ""
    default property alias rows: body.data

    width: parent?.width ?? 0
    spacing: 2

    PanelSection {
        visible: root.title !== ""
        width: parent.width
        look: K.Kit.appLook
        text: root.title
    }

    Column {
        id: body
        width: parent.width
    }
}
