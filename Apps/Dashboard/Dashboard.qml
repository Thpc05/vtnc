import QtQuick
import "Cards"
import "../../Config"
import "../../Island"

// ═══════════════════════════════════════════
//  DASHBOARD — O Control Center.
//
//  O QUE SUMIU, e por quê: a versão anterior tinha grid por
//  coordenada, solver de colisão, empurrão-em-sombra, drag pra
//  reposicionar e pin persistido — ~250 linhas. Tudo aquilo existia
//  porque as peças mudavam de tamanho sozinhas (hover expandia) e
//  precisavam se desviar. Com tamanho FIXO não há o que desviar, e o
//  layout vira o que ele sempre quis ser: uma coluna de linhas.
//
//  Mexer no layout = mexer nestas linhas. Não é configurável em
//  runtime de propósito — posição de card é desenho, não preferência.
//
//  Registrar um card = criar em Cards/ + colocar aqui.
//
//  É uma FACE DE APP, não um pedaço da barra. Antes ela crescia pra
//  baixo dentro da Bar, o que deixava o relógio, os workspaces e o
//  cluster de reveals pendurados em cima dela. Um Control Center não
//  é continuação da barra: a ilha MORFA nele, como faz no launcher.
// ═══════════════════════════════════════════
IslandFace {
    id: root

    name: "dashboard"
    role: "app"

    readonly property real gap: Theme.dashGap
    // Duas colunas de cards, com o vão no meio
    readonly property real meia: (pilha.width - gap) / 2
    // Altura de um card de toggle; o card de mídia vale dois + o vão
    readonly property real unidade: Theme.dashCell

    contentWidth: Theme.dashWidth
    contentHeight: pilha.implicitHeight + Theme.contentPadding * 2

    Column {
        id: pilha

        anchors.top: parent.top
        anchors.left: parent.left
        anchors.right: parent.right
        anchors.margins: Theme.contentPadding
        spacing: root.gap

        // ── LINHA 1: Wi-Fi/Bluetooth empilhados | Mídia (altura dupla)
        Row {
            width: parent.width
            spacing: root.gap

            Column {
                width: root.meia
                spacing: root.gap

                WifiCard {
                    width: parent.width
                    height: root.unidade
                }
                BluetoothCard {
                    width: parent.width
                    height: root.unidade
                }
            }

            MediaCard {
                width: root.meia
                // Acompanha a coluna ao lado: dois cards mais o vão
                height: root.unidade * 2 + root.gap
            }
        }

        // ── LINHA 2 e 3: os sliders, largura cheia ──
        // Mais baixos que os cards de toggle de propósito: um slider
        // não tem duas linhas de texto pra acomodar, e deixá-lo da
        // mesma altura faria o Control Center parecer só uma pilha de
        // blocos iguais
        BrightnessCard {
            width: parent.width
            height: root.unidade * 0.72
        }

        VolumeCard {
            width: parent.width
            height: root.unidade * 0.72
        }
    }
}
