import QtQuick
import qs.dwidgets.quick.panels
import qs.kit as K

// The settings switch (R1.5, 2026-10-17): the Quick panels' switch in the apps' look (K.Kit.appLook), with
// the old API: `checked` is driven from outside, a click emits `toggled(next)`.
Item {
    id: root

    property bool checked: false
    signal toggled(bool checked)

    implicitWidth: sw.implicitWidth
    implicitHeight: sw.implicitHeight

    PanelSwitch {
        id: sw
        look: K.Kit.appLook
        checked: root.checked
        onToggled: root.toggled(!root.checked)
    }
}
