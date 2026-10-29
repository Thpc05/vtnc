import QtQuick
import qs.kit as K

// Top of a Qwidget panel opened by expanding (2026-10-16, the "hero" panels): the back arrow. No switch
// (2026-10-27, user: the hero's mark and name are the switch, PanelHero), no block behind it. A panel that
// is the Dwidget's face has no header.
Item {
    id: root

    // the look of the Dwidget that opened the panel (look.panel)
    property var look: null
    // the back arrow (an expanded Dwidget going back); off when the panel is the Dwidget's look
    property bool backVisible: true
    signal back

    readonly property PanelColors c: PanelColors {
        look: root.look
    }

    implicitHeight: 32

    K.IconButton {
        id: backButton
        type: K.ButtonBase.Text
        isRound: true
        anchors.left: parent.left
        anchors.leftMargin: -7
        anchors.verticalCenter: parent.verticalCenter
        icon: "arrow_back"
        size: 18
        label.color: root.c.strong
        visible: root.backVisible
        onClicked: root.back()
    }
}
