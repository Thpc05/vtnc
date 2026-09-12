import QtQuick
import Quickshell
import Quickshell.Widgets
import Quickshell.Services.SystemTray
import "../../ConfigValues"

// ═══════════════════════════════════════════
//  TRAY REVEAL — Apps ocultos (steam, discord...).
//  Mirar revela os ícones; mirar um ÍCONE mostra as opções do menu
//  dele (SNI) inline, logo abaixo. Clique esquerdo ativa o app;
//  clique numa opção dispara a ação.
// ═══════════════════════════════════════════
Reveal {
    id: root

    name: "tray"

    readonly property int count: SystemTray.items.values.length

    // Sem nenhum app no tray as reticências não levam a lugar nenhum:
    // some (e o cluster fecha o buraco sozinho, é um Row)
    visible: count > 0

    // Item do tray cujo menu está aberto (mirar noutro ícone troca)
    property var menuItem: null
    onRevealedChanged: if (!revealed) menuItem = null

    QsMenuOpener {
        id: menuOpener
        menu: root.menuItem?.menu ?? null
    }
    readonly property var menuEntries: menuItem
        ? (menuOpener.children?.values ?? [])
        : []

    panelHovered: panelHover.hovered

    // ── ANCHOR: reticências ──
    Text {
        text: "󰇘"
        color: root.revealed ? Theme.textPrimary : Theme.textSecondary
        font { family: Theme.fontIcon; pixelSize: 14 }
        Behavior on color { ColorAnimation { duration: Motion.instant } }
    }

    // ── PANEL: ícones + menu do ícone mirado ──
    panel: Item {
        implicitHeight: 30
            + (root.menuEntries.length > 0 ? menuCol.implicitHeight + 6 : 0)

        Behavior on opacity { NumberAnimation { duration: Motion.quick } }

        HoverHandler { id: panelHover }

        // Vazio: só um aviso sutil
        Text {
            anchors.centerIn: parent
            visible: root.count === 0
            text: "Nada no tray"
            color: Theme.textMuted
            font { family: Theme.fontDisplay; pixelSize: 11 }
        }

        Row {
            id: iconRow

            anchors.top: parent.top
            anchors.topMargin: 4
            anchors.horizontalCenter: parent.horizontalCenter
            spacing: 16

            Repeater {
                model: SystemTray.items

                Item {
                    id: trayItem

                    required property var modelData

                    readonly property bool menuOpen: root.menuItem === modelData

                    width: 22
                    height: 22

                    Rectangle {
                        anchors.fill: parent
                        radius: Theme.radiusChip
                        color: trayItem.menuOpen ? Theme.hoverLayer : "transparent"
                        Behavior on color { ColorAnimation { duration: Motion.instant } }
                    }

                    IconImage {
                        anchors.centerIn: parent
                        implicitSize: iconHover.hovered ? 20 : 17
                        source: trayItem.modelData.icon
                        Behavior on implicitSize {
                            NumberAnimation { duration: Motion.instant; easing.type: Easing.OutCubic }
                        }
                    }

                    HoverHandler {
                        id: iconHover
                        onHoveredChanged: {
                            if (hovered)
                                root.menuItem = trayItem.modelData
                        }
                    }

                    // Esquerdo ativa o app (o menu já está à mostra)
                    TapHandler {
                        acceptedButtons: Qt.LeftButton
                        onTapped: {
                            if (!trayItem.modelData.onlyMenu)
                                trayItem.modelData.activate()
                        }
                    }
                }
            }
        }

        // ── OPÇÕES DO MENU (inline, abaixo dos ícones) ──
        Column {
            id: menuCol

            anchors.top: iconRow.bottom
            anchors.topMargin: 6
            anchors.left: parent.left
            anchors.right: parent.right
            spacing: 1
            visible: root.menuEntries.length > 0

            Repeater {
                model: root.menuEntries

                Item {
                    id: entryItem

                    required property var modelData

                    readonly property bool isSep: modelData.isSeparator ?? false
                    readonly property bool enabled: modelData.enabled ?? true

                    width: menuCol.width
                    height: isSep ? 7 : 20

                    // Separador
                    Rectangle {
                        anchors.verticalCenter: parent.verticalCenter
                        anchors.left: parent.left
                        anchors.right: parent.right
                        anchors.margins: 4
                        visible: entryItem.isSep
                        height: 1
                        color: Theme.separator
                    }

                    // Mira
                    Rectangle {
                        anchors.fill: parent
                        radius: Theme.radiusChip
                        visible: !entryItem.isSep
                        color: entryHover.hovered && entryItem.enabled
                            ? Theme.hoverLayer
                            : "transparent"
                        Behavior on color { ColorAnimation { duration: Motion.instant } }
                    }

                    Text {
                        anchors.left: parent.left
                        anchors.leftMargin: 6
                        anchors.right: parent.right
                        anchors.rightMargin: 6
                        anchors.verticalCenter: parent.verticalCenter
                        visible: !entryItem.isSep
                        text: entryItem.modelData.text ?? ""
                        color: entryItem.enabled ? Theme.textSecondary : Theme.textMuted
                        elide: Text.ElideRight
                        font { family: Theme.fontDisplay; pixelSize: 11 }
                    }

                    HoverHandler { id: entryHover }
                    TapHandler {
                        enabled: !entryItem.isSep && entryItem.enabled
                        onTapped: entryItem.modelData.triggered()
                    }
                }
            }
        }
    }
}
