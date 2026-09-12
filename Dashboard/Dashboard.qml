import QtQuick
import "Cards"
import "../Config"

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
// ═══════════════════════════════════════════
Item {
    id: root

    // Largura BASE pedida pela Bar; a dashboard não cresce mais além
    // dela (era o container que se esticava pra caber um expandido)
    property real baseWidth: 400

    // Nenhum widget pede teclado nesta versão: senha de Wi-Fi mora no
    // detalhe, que ainda não existe. A Bar lê isto pela cadeia
    // Dashboard → Bar → Island → shell
    readonly property bool wantsKeyboard: false

    readonly property real gap: Theme.dashGap
    // Duas colunas de cards, com o vão no meio
    readonly property real meia: (width - gap) / 2
    // Altura de um card de toggle; o card de mídia vale dois + o vão
    readonly property real unidade: Theme.dashCell

    width: baseWidth
    implicitHeight: pilha.implicitHeight

    Column {
        id: pilha

        width: parent.width
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
