import QtQuick
import "../Config"
import "../Ui"

// ═══════════════════════════════════════════
//  SETTING TEXT — Texto livre (caminhos, nomes de fonte, comandos).
//
//  Só comita no Enter ou ao perder o foco, NÃO a cada tecla: um path
//  meio digitado é um path inválido, e comitar letra a letra gravaria
//  dezenas de estados quebrados no disco pelo caminho.
// ═══════════════════════════════════════════
SettingRow {
    id: root

    property string text: ""
    currentValue: text

    controlWidth: 260

    Rectangle {
        anchors.right: parent.right
        anchors.verticalCenter: parent.verticalCenter
        width: root.controlWidth
        height: 30
        radius: Theme.radiusChip
        color: Theme.hoverLayer
        border.width: 1
        border.color: campo.activeFocus ? Theme.accent : "transparent"
        Behavior on border.color { ColorAnimation { duration: Motion.instant } }

        TextInput {
            id: campo

            anchors.fill: parent
            anchors.leftMargin: 10
            anchors.rightMargin: 10
            verticalAlignment: TextInput.AlignVCenter
            clip: true
            color: Theme.textPrimary
            selectionColor: Theme.accent
            selectedTextColor: Theme.bg
            font { family: Theme.fontMono; pixelSize: 12 }

            // O texto NÃO pode ser um binding: um binding em `text` que
            // leia `text` é um laço, e um binding puro em `root.text`
            // sobrescreveria o que você está digitando. Sincroniza na
            // mão, e só quando o campo não está com o foco
            Component.onCompleted: text = root.text
            Connections {
                target: root
                function onTextChanged() {
                    if (!campo.activeFocus)
                        campo.text = root.text
                }
            }

            onAccepted: { root.apply(text); focus = false }
            onActiveFocusChanged: if (!activeFocus) root.apply(text)
            Keys.onEscapePressed: { text = root.text; focus = false }
        }
    }
}
