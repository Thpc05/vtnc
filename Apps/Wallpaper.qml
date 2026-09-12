import QtQuick
import QtQuick.Effects
import Quickshell
import Quickshell.Io
import "../Config"
import "../Island"
import "../Services"
import "../Ui"

// ═══════════════════════════════════════════
//  WALLPAPER — Seletor de wallpaper (hyprpaper).
//  A pill vira uma grade de miniaturas da pasta
//  Config.wallpaperPath. Setas navegam, Enter aplica.
//
//  IPC:  qs ipc call wallpaper toggle   → abre/fecha o seletor
//        qs ipc call wallpaper random   → aplica um aleatório
// ═══════════════════════════════════════════
IslandFace {
    id: root

    name: "wallpaper"
    role: "app"
    grabsKeyboard: true

    // Grade HORIZONTAL: poucas fileiras, miniaturas largas,
    // scroll para o lado (colunas entram/saem pela direita)
    readonly property int gridRows: 2
    readonly property int visibleColumns: 3
    readonly property real cellW: 240
    readonly property real cellH: 138

    // A lista, a troca e a paleta moram no WallpaperService: este app
    // é só a grade que escolhe. Antes ele listava com `sh -c` e
    // aplicava com hyprpaper por conta própria, o que deixava o IPC
    // `wallpaper random` ter que alcançar a INSTÂNCIA viva do app no
    // monitor certo pra funcionar
    readonly property var walls: WallpaperService.list
    readonly property int shownRows: Math.max(1, Math.min(gridRows, walls.length))

    // Margens simétricas: a grade respira igual em todos os lados
    contentWidth: visibleColumns * cellW + Theme.contentPadding * 2 + 8
    contentHeight: Theme.contentPadding * 2 + 32 + shownRows * cellH

    // ─── AÇÕES ───
    function apply(file) {
        WallpaperService.apply(file)
        root.closeRequested()
    }

    onActiveChanged: {
        if (active) {
            WallpaperService.refresh() // re-lê a pasta a cada abertura
            grid.currentIndex = 0
            focusTimer.restart()
        }
    }

    Timer {
        id: focusTimer
        interval: 20
        onTriggered: grid.forceActiveFocus()
    }

    Column {
        anchors.fill: parent
        anchors.margins: Theme.contentPadding
        spacing: 8

        // ─── CABEÇALHO ───
        Row {
            height: 24
            spacing: 10

            Text {
                text: "󰸉"
                color: Theme.accent
                anchors.verticalCenter: parent.verticalCenter
                font { family: Theme.fontIcon; pixelSize: 16 }
            }

            Text {
                text: "Wallpapers"
                color: Theme.textPrimary
                anchors.verticalCenter: parent.verticalCenter
                font { family: Theme.fontDisplay; pixelSize: 14; weight: 650 }
            }

            Text {
                text: `${root.walls.length}`
                color: Theme.textMuted
                anchors.verticalCenter: parent.verticalCenter
                font { family: Theme.fontMono; pixelSize: 11 }
            }
        }

        // ─── GRADE DE MINIATURAS (preenche por coluna, flica pro lado) ───
        GridView {
            id: grid

            width: parent.width
            height: root.shownRows * root.cellH
            cellWidth: root.cellW
            cellHeight: root.cellH
            flow: GridView.FlowTopToBottom
            model: root.walls
            clip: true
            focus: root.active

            Keys.onPressed: event => {
                switch (event.key) {
                case Qt.Key_Left:   grid.moveCurrentIndexLeft(); break
                case Qt.Key_Right:  grid.moveCurrentIndexRight(); break
                case Qt.Key_Up:     grid.moveCurrentIndexUp(); break
                case Qt.Key_Down:   grid.moveCurrentIndexDown(); break
                case Qt.Key_Return:
                case Qt.Key_Enter:
                    if (grid.currentIndex >= 0 && root.walls.length > 0)
                        root.apply(root.walls[grid.currentIndex])
                    break
                case Qt.Key_Escape: root.closeRequested(); break
                default: return
                }
                event.accepted = true
            }

            delegate: Item {
                id: cell

                required property string modelData
                required property int index

                width: grid.cellWidth
                height: grid.cellHeight

                readonly property bool isSelected: GridView.isCurrentItem

                Rectangle {
                    anchors.fill: parent
                    anchors.margins: 4
                    radius: Theme.radiusRow
                    color: Theme.card
                    // Borda accent no selecionado
                    border.width: cell.isSelected ? 2 : 0
                    border.color: Theme.accent

                    // Cantos arredondados DE VERDADE na miniatura
                    // (clip retangular cortava o radius nas bordas)
                    Image {
                        id: thumbImg
                        anchors.fill: parent
                        anchors.margins: 2
                        source: `file://${Config.wallpaperPath}/${cell.modelData}`
                        fillMode: Image.PreserveAspectCrop
                        asynchronous: true
                        // Miniatura leve: não decodifica a imagem inteira
                        sourceSize.width: 320
                        visible: false
                    }

                    Rectangle {
                        id: thumbMask
                        anchors.fill: thumbImg
                        radius: Theme.radiusChip
                        layer.enabled: true
                        visible: false
                    }

                    MultiEffect {
                        anchors.fill: thumbImg
                        source: thumbImg
                        maskEnabled: true
                        maskSource: thumbMask

                        scale: cell.isSelected ? 1.0 : 0.96
                        Behavior on scale { Settle { duration: 140 } }
                    }
                }

                MouseArea {
                    anchors.fill: parent
                    hoverEnabled: true
                    onEntered: grid.currentIndex = cell.index
                    onClicked: root.apply(cell.modelData)
                }
            }
        }
    }
}
