import QtQuick
import ".."
import "../../../Config"

// ═══════════════════════════════════════════
//  TOGGLE CARD — A forma do Wi-Fi e do Bluetooth no Control Center:
//  ícone num círculo, título, e uma linha embaixo com o estado.
//
//  O círculo INVERTE com o estado: desligado é um disco claro sobre
//  card escuro; ligado é um disco escuro sobre card accent. Sempre
//  contrasta, sem precisar de uma cor por estado.
// ═══════════════════════════════════════════
DashCard {
    id: root

    property string icon: ""
    property string title: ""
    // Linha de baixo: rede conectada, dispositivo pareado, "Desligado"
    property string status: ""

    Item {
        anchors.fill: parent

        Rectangle {
            id: bolha

            anchors.left: parent.left
            anchors.verticalCenter: parent.verticalCenter
            width: 34
            height: 34
            radius: width / 2
            color: root.lit ? Qt.rgba(0, 0, 0, 0.22) : Qt.rgba(1, 1, 1, 0.10)
            Behavior on color { ColorAnimation { duration: Motion.instant } }

            Text {
                anchors.centerIn: parent
                text: root.icon
                color: root.ink
                font { family: Theme.fontIcon; pixelSize: 17 }
                Behavior on color { ColorAnimation { duration: Motion.instant } }
            }
        }

        Column {
            anchors.left: bolha.right
            anchors.leftMargin: 10
            // Folga pro chevron não encostar no texto
            anchors.right: parent.right
            anchors.rightMargin: root.detail !== "" ? 20 : 0
            anchors.verticalCenter: parent.verticalCenter
            spacing: 1

            Text {
                width: parent.width
                text: root.title
                elide: Text.ElideRight
                color: root.ink
                font { family: Theme.fontDisplay; pixelSize: 13; weight: 600 }
                Behavior on color { ColorAnimation { duration: Motion.instant } }
            }

            Text {
                width: parent.width
                text: root.status
                elide: Text.ElideRight
                color: root.inkSoft
                font { family: Theme.fontDisplay; pixelSize: 11 }
                Behavior on color { ColorAnimation { duration: Motion.instant } }
            }
        }
    }
}
