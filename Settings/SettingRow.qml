import QtQuick
import "../Config"

// ═══════════════════════════════════════════
//  SETTING ROW — A base de toda linha do config: rótulo à esquerda,
//  controle à direita, e uma descrição opcional embaixo.
//
//  Não sabe editar nada: os controles concretos (SettingSlider,
//  SettingToggle, …) herdam daqui e enchem o `control`.
// ═══════════════════════════════════════════
Item {
    id: root

    property string label: ""
    // Linha fina embaixo do rótulo, pra explicar o que não é óbvio
    property string hint: ""
    // Controle declarado pelo filho concreto, encostado à direita
    default property alias control: controlHost.data
    // Quanto o controle ocupa da largura (o resto é do rótulo)
    property real controlWidth: 160

    width: parent ? parent.width : 0
    implicitHeight: Math.max(36, labelCol.implicitHeight + 16)

    Column {
        id: labelCol

        anchors.left: parent.left
        anchors.verticalCenter: parent.verticalCenter
        anchors.right: controlHost.left
        anchors.rightMargin: 16
        spacing: 2

        Text {
            width: parent.width
            text: root.label
            color: Theme.textPrimary
            elide: Text.ElideRight
            font { family: Theme.fontDisplay; pixelSize: 13 }
        }

        Text {
            width: parent.width
            visible: root.hint !== ""
            text: root.hint
            color: Theme.textMuted
            wrapMode: Text.WordWrap
            font { family: Theme.fontDisplay; pixelSize: 11 }
        }
    }

    Item {
        id: controlHost

        anchors.right: parent.right
        anchors.verticalCenter: parent.verticalCenter
        width: root.controlWidth
        height: parent.height
    }
}
