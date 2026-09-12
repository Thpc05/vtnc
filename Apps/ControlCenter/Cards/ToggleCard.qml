import QtQuick
import ".."
import "../../../ConfigValues"

// ═══════════════════════════════════════════
//  TOGGLE CARD — A forma do Wi-Fi e do Bluetooth: ícone num círculo,
//  título, e uma linha embaixo com o estado.
//
//  QUEM ACENDE É O CÍRCULO, não o card. O estado cabe inteiro em 34px
//  de disco: ligado, o disco é accent e o glyph fica preto; desligado,
//  o disco é um véu claro e o glyph fica apagado. O card não muda —
//  é o que deixa a shell parecer calma com dois toggles ligados.
// ═══════════════════════════════════════════
ControlCard {
    id: root

    property string icon: ""
    property string title: ""
    // Linha de baixo: rede conectada, dispositivo pareado, "Desligado"
    property string status: ""
    // Ligado — acende o círculo
    property bool lit: false

    Item {
        anchors.fill: parent

        Rectangle {
            id: bolha

            anchors.left: parent.left
            anchors.verticalCenter: parent.verticalCenter
            width: 34
            height: 34
            radius: width / 2
            color: root.lit ? Theme.accent : Qt.rgba(1, 1, 1, 0.08)
            Behavior on color { ColorAnimation { duration: Motion.instant } }

            Text {
                anchors.centerIn: parent
                text: root.icon
                // Sobre o accent o glyph é o preto da shell; desligado,
                // apagado. Nos dois casos ele contrasta com o disco
                color: root.lit ? Theme.bg : Theme.textMuted
                font { family: Theme.fontIcon; pixelSize: 16 }
                Behavior on color { ColorAnimation { duration: Motion.instant } }
            }
        }

        Column {
            anchors.left: bolha.right
            anchors.leftMargin: 11
            // Folga pro chevron não encostar no texto
            anchors.right: parent.right
            anchors.rightMargin: root.detail !== "" ? 18 : 0
            anchors.verticalCenter: parent.verticalCenter
            spacing: 1

            Text {
                width: parent.width
                text: root.title
                elide: Text.ElideRight
                color: Theme.textPrimary
                font { family: Theme.fontDisplay; pixelSize: 13; weight: 600 }
            }

            Text {
                width: parent.width
                text: root.status
                elide: Text.ElideRight
                color: Theme.textSecondary
                font { family: Theme.fontDisplay; pixelSize: 11 }
            }
        }
    }
}
