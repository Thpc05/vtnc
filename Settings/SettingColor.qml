import QtQuick
import "../Config"
import "../Ui"

// ═══════════════════════════════════════════
//  SETTING COLOR — Amostra + hex editável.
//
//  Hex e não um seletor de cor: é o que está guardado no JSON, é o
//  que o matugen vai escrever lá no futuro, e é o que se copia de um
//  lugar pro outro. Um color picker esconderia justamente o valor
//  que interessa.
// ═══════════════════════════════════════════
SettingRow {
    id: root

    property color value: "#000000"
    signal commit(string hex)

    controlWidth: 170

    // Aceita #rgb, #rrggbb e #aarrggbb — comitar lixo apagaria a cor
    function _valido(s) {
        return /^#([0-9a-fA-F]{3}|[0-9a-fA-F]{6}|[0-9a-fA-F]{8})$/.test(s.trim())
    }

    Row {
        anchors.right: parent.right
        anchors.verticalCenter: parent.verticalCenter
        spacing: 10

        Rectangle {
            anchors.verticalCenter: parent.verticalCenter
            width: 26
            height: 26
            radius: Theme.radiusChip
            color: root.value
            // Contorno claro: sem ele uma cor escura some no fundo preto
            border.width: 1
            border.color: Theme.separator
        }

        Rectangle {
            anchors.verticalCenter: parent.verticalCenter
            width: 120
            height: 30
            radius: Theme.radiusChip
            color: Theme.hoverLayer
            border.width: 1
            border.color: !campo.activeFocus ? "transparent"
                : (root._valido(campo.text) ? Theme.accent : Theme.danger)
            Behavior on border.color { ColorAnimation { duration: Motion.instant } }

            TextInput {
                id: campo

                anchors.fill: parent
                anchors.leftMargin: 9
                anchors.rightMargin: 9
                verticalAlignment: TextInput.AlignVCenter
                clip: true
                color: Theme.textPrimary
                selectionColor: Theme.accent
                selectedTextColor: Theme.bg
                font { family: Theme.fontMono; pixelSize: 12 }

                // Mesmo motivo do SettingText: sincroniza na mão
                Component.onCompleted: text = root.value.toString()
                Connections {
                    target: root
                    function onValueChanged() {
                        if (!campo.activeFocus)
                            campo.text = root.value.toString()
                    }
                }

                function enviar() {
                    if (root._valido(text))
                        root.commit(text.trim())
                    else
                        text = root.value.toString() // inválido: desfaz
                }

                onAccepted: { enviar(); focus = false }
                onActiveFocusChanged: if (!activeFocus) enviar()
                Keys.onEscapePressed: {
                    text = root.value.toString()
                    focus = false
                }
            }
        }
    }
}
