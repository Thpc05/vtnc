import QtQuick
import Quickshell
import Quickshell.Widgets
import "../Components"
import "../Components/Pill"

// ═══════════════════════════════════════════
//  LAUNCHER — Busca e lança apps (.desktop).
//  App face: captura o teclado enquanto aberto.
// ═══════════════════════════════════════════
PillFace {
    id: root

    name: "launcher"
    role: "app"
    grabsKeyboard: true

    contentWidth: Theme.launcherWidth
    contentHeight: 52 + Math.min(filteredApps.length, Config.maxLauncherResults) * 54 + 12
    // Lista muda ao filtrar — a face anima o próprio tamanho
    Behavior on contentHeight {
        enabled: active
        Settle { duration: 180 }
    }

    property string searchText: ""

    readonly property var filteredApps: {
        const all = [...DesktopEntries.applications.values]
        if (searchText.trim() === "")
            return all.slice(0, Config.maxLauncherResults)

        const query = searchText.toLowerCase()
        return all.filter(app => {
            const n = app.name ? app.name.toLowerCase() : ""
            const c = app.comment ? app.comment.toLowerCase() : ""
            return n.includes(query) || c.includes(query)
        }).slice(0, Config.maxLauncherResults)
    }

    // Reset da seleção ao filtrar
    onFilteredAppsChanged: appsList.currentIndex = 0

    onActiveChanged: {
        if (active) {
            searchText = ""
            searchInput.text = ""
            appsList.currentIndex = 0
            focusTimer.restart()
        }
    }

    Timer {
        id: focusTimer
        interval: 20
        onTriggered: searchInput.forceActiveFocus()
    }

    Column {
        anchors.fill: parent
        anchors.margins: Theme.contentPadding
        spacing: 8

        // ─── BARRA DE PESQUISA ───
        Item {
            width: parent.width
            height: 40

            Row {
                anchors.fill: parent
                anchors.leftMargin: 6
                anchors.rightMargin: 6
                spacing: 12

                Text {
                    text: "󰍉"
                    color: Theme.accent
                    anchors.verticalCenter: parent.verticalCenter
                    font.pixelSize: 18
                }

                TextInput {
                    id: searchInput

                    width: parent.width - 35
                    anchors.verticalCenter: parent.verticalCenter
                    color: Theme.textPrimary
                    font { family: Theme.fontDisplay; pixelSize: 15; weight: 500 }
                    clip: true
                    focus: root.active

                    Text {
                        text: "Search..."
                        color: Theme.textMuted
                        visible: parent.text === "" && !parent.activeFocus
                        font: parent.font
                    }

                    onTextChanged: root.searchText = text

                    // Navegação por teclado
                    Keys.onUpPressed: event => {
                        appsList.decrementCurrentIndex()
                        event.accepted = true
                    }
                    Keys.onDownPressed: event => {
                        appsList.incrementCurrentIndex()
                        event.accepted = true
                    }
                    Keys.onReturnPressed: event => {
                        if (root.filteredApps.length > 0 && appsList.currentItem)
                            appsList.currentItem.executeApp()
                        event.accepted = true
                    }
                    Keys.onEscapePressed: event => {
                        root.closeRequested()
                        event.accepted = true
                    }
                }
            }

            // Separador sutil
            Rectangle {
                anchors.bottom: parent.bottom
                width: parent.width
                height: 1
                color: Theme.separator
            }
        }

        // ─── LISTA DE APPS ───
        ListView {
            id: appsList

            width: parent.width
            height: Math.min(root.filteredApps.length, Config.maxLauncherResults) * 54
            model: root.filteredApps
            clip: true
            spacing: 4
            highlightMoveDuration: 150

            delegate: Rectangle {
                id: delegateRoot

                required property var modelData
                required property int index

                width: appsList.width
                height: 50
                radius: 12

                readonly property bool isSelected: ListView.isCurrentItem

                color: isSelected ? Theme.surface : "transparent"
                Behavior on color { ColorAnimation { duration: Motion.instant } }

                function executeApp() {
                    modelData.execute()
                    root.closeRequested()
                }

                MouseArea {
                    anchors.fill: parent
                    hoverEnabled: true
                    onEntered: appsList.currentIndex = delegateRoot.index
                    onClicked: delegateRoot.executeApp()
                }

                Row {
                    anchors.fill: parent
                    anchors.leftMargin: 4
                    spacing: 12

                    // Indicador lateral accent
                    Rectangle {
                        width: 4
                        height: 26
                        radius: 2
                        color: delegateRoot.isSelected ? Theme.accent : "transparent"
                        anchors.verticalCenter: parent.verticalCenter
                        Behavior on color { ColorAnimation { duration: Motion.instant } }
                    }

                    IconImage {
                        width: 32
                        height: 32
                        anchors.verticalCenter: parent.verticalCenter
                        source: Quickshell.iconPath(delegateRoot.modelData.icon, true)
                        scale: delegateRoot.isSelected ? 1.05 : 1.0
                        Behavior on scale { NumberAnimation { duration: Motion.instant } }
                    }

                    Column {
                        anchors.verticalCenter: parent.verticalCenter
                        spacing: 2

                        Text {
                            text: delegateRoot.modelData.name ?? "Unknown"
                            color: delegateRoot.isSelected ? Theme.accent : Theme.textPrimary
                            font {
                                family: Theme.fontDisplay
                                pixelSize: 14
                                weight: delegateRoot.isSelected ? 700 : 500
                            }
                        }

                        Text {
                            text: delegateRoot.modelData.comment ?? delegateRoot.modelData.genericName ?? "System application"
                            color: delegateRoot.isSelected ? Theme.textSecondary : Theme.textMuted
                            width: 380
                            elide: Text.ElideRight
                            font { family: Theme.fontDisplay; pixelSize: 11 }
                        }
                    }
                }
            }
        }
    }
}
