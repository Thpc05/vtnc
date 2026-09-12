import QtQuick
import "../Config"
import "../Ui"

// ═══════════════════════════════════════════
//  SETTING SLIDER — Número contínuo, com o valor à direita.
//
//  Uso:
//      SettingSlider {
//          label: "Raio da ilha"
//          value: Theme.radiusIsland
//          from: 8; to: 40
//          onCommit: v => Theme.data.radiusIsland = v
//      }
//
//  O `value` é um BINDING de leitura e o `commit` escreve na fonte —
//  nunca guardamos uma cópia local do valor. Quem arrasta escreve na
//  fonte, a fonte reemite, e o polegar segue. Uma cópia local daria
//  duas verdades, e elas divergiriam no instante em que outra coisa
//  mudasse o mesmo token.
// ═══════════════════════════════════════════
SettingRow {
    id: root

    property real value: 0
    property real from: 0
    property real to: 100
    // 0 = contínuo; 1 = inteiros; 0.1 = uma casa
    property real step: 1
    property string suffix: ""

    signal commit(real v)

    controlWidth: 210

    readonly property real _frac:
        to > from ? Math.max(0, Math.min(1, (value - from) / (to - from))) : 0

    function _apply(px) {
        const f = Math.max(0, Math.min(1, px / trilho.width))
        let v = from + f * (to - from)
        if (step > 0)
            v = Math.round(v / step) * step
        if (v !== value)
            root.commit(v)
    }

    Item {
        anchors.fill: parent

        Text {
            id: valorTexto

            anchors.right: parent.right
            anchors.verticalCenter: parent.verticalCenter
            // Largura fixa: sem isto o trilho encolhe e cresce conforme
            // o número muda de dígitos, e o polegar treme ao arrastar
            width: 52
            horizontalAlignment: Text.AlignRight
            text: (root.step >= 1 ? Math.round(root.value)
                                  : root.value.toFixed(1))
                  + (root.suffix ? " " + root.suffix : "")
            color: Theme.textSecondary
            font { family: Theme.fontMono; pixelSize: 12 }
        }

        Item {
            id: trilho

            anchors.left: parent.left
            anchors.right: valorTexto.left
            anchors.rightMargin: 12
            anchors.verticalCenter: parent.verticalCenter
            height: 22

            Rectangle {
                anchors.verticalCenter: parent.verticalCenter
                width: parent.width
                height: 6
                radius: height / 2
                color: Theme.hoverLayer
            }

            Rectangle {
                anchors.verticalCenter: parent.verticalCenter
                width: parent.width * root._frac
                height: 6
                radius: height / 2
                color: Theme.accent
            }

            Rectangle {
                x: parent.width * root._frac - width / 2
                anchors.verticalCenter: parent.verticalCenter
                width: arrasta.pressed || alvo.hovered ? 16 : 13
                height: width
                radius: width / 2
                color: Theme.textPrimary
                Behavior on width { Smooth { duration: Motion.instant } }
            }

            HoverHandler { id: alvo }

            MouseArea {
                id: arrasta

                anchors.fill: parent
                // Folga vertical: o trilho tem 6px, mirar isso é chato
                anchors.topMargin: -6
                anchors.bottomMargin: -6
                onPressed: mouse => root._apply(mouse.x)
                onPositionChanged: mouse => { if (pressed) root._apply(mouse.x) }
            }
        }
    }
}
