import QtQuick
import qs.kit as K

// The shell's switch (settings controls/Switch.qml, dashboard panels): the kit's M3 switch
// (K.Switch, caelestia's), kept behind the old API: `checked` is driven from outside and a click
// emits `toggled(next)` without flipping it itself.
Item {
    id: root

    property bool checked: false
    // the surface layer it sits on (Colors.layer)
    property int cLayer: 1
    signal toggled(bool checked)

    implicitWidth: sw.implicitWidth
    implicitHeight: sw.implicitHeight

    K.Switch {
        id: sw

        anchors.centerIn: parent
        checked: root.checked
        cLayer: root.cLayer
        onToggled: {
            const next = checked;
            // the owner decides: back to its value until it changes
            checked = Qt.binding(() => root.checked);
            root.toggled(next);
        }
    }
}
