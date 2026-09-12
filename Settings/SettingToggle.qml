import QtQuick
import "../Config"
import "../Ui"

// ═══════════════════════════════════════════
//  SETTING TOGGLE — Liga/desliga.
//
//      SettingToggle {
//          label: "Autohide sempre"
//          checked: Config.alwaysAutoHide
//          onCommit: v => Config.data.alwaysAutoHide = v
//      }
// ═══════════════════════════════════════════
SettingRow {
    id: root

    property bool checked: false
    currentValue: checked

    controlWidth: 52

    Item {
        anchors.fill: parent

        Rectangle {
            id: pista

            anchors.right: parent.right
            anchors.verticalCenter: parent.verticalCenter
            width: 44
            height: 26
            radius: height / 2
            color: root.checked ? Theme.accent : Theme.hoverLayer
            Behavior on color { ColorAnimation { duration: Motion.instant } }

            Rectangle {
                x: root.checked ? parent.width - width - 3 : 3
                anchors.verticalCenter: parent.verticalCenter
                width: 20
                height: 20
                radius: width / 2
                // Sobre o accent o polegar é o preto da shell; desligado,
                // é claro — nos dois casos ele contrasta com a pista
                color: root.checked ? Theme.bg : Theme.textSecondary
                Behavior on x { Smooth { duration: Motion.instant } }
                Behavior on color { ColorAnimation { duration: Motion.instant } }
            }

            TapHandler {
                gesturePolicy: TapHandler.ReleaseWithinBounds
                onTapped: root.apply(!root.checked)
            }
        }
    }
}
