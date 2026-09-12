import QtQuick
import Quickshell
import Quickshell.Hyprland
import Quickshell.Widgets
import "../../ConfigValues"
import "../../Ui"

// ═══════════════════════════════════════════
//  WORKSPACE REVEAL — Os dots do canto esquerdo são o anchor; mirar
//  revela o que MORA em cada workspace: uma linha por workspace, com
//  o ícone de cada janela aberta.
//  Clique no número troca de workspace; clique num ícone foca aquela
//  janela direto.
//
//  Único reveal do cluster ESQUERDO (os outros vivem à direita) — o
//  contrato não liga pra isso, o painel se posiciona pelo anchor.
// ═══════════════════════════════════════════
Reveal {
    id: root

    name: "workspaces"

    // A Bar dimensiona a pill wide pelo nº de dots — repassa
    readonly property int count: ws.count

    panelHovered: panelHover.hovered

    // Os toplevels não chegam sozinhos: pede quando o painel abre
    onRevealedChanged: if (revealed) Hyprland.refreshToplevels()

    // Janelas por workspace.
    // ARMADILHA: `toplevel.workspace` vem nulo aqui — o id real só
    // existe no lastIpcObject (confirmado por probe).
    readonly property var byWs: {
        const m = ({})
        for (const t of Hyprland.toplevels.values) {
            const id = t.lastIpcObject?.workspace?.id ?? -1
            if (id <= 0)
                continue
            if (!m[id])
                m[id] = []
            m[id].push(t)
        }
        return m
    }

    // class do Hyprland → DesktopEntry (pro ícone do app)
    function entryFor(t) {
        const cls = (t.lastIpcObject?.class ?? "").toLowerCase()
        if (cls === "")
            return null
        const apps = DesktopEntries.applications.values
        return apps.find(a => (a.id ?? "").toLowerCase() === cls)
            ?? apps.find(a => (a.name ?? "").toLowerCase() === cls)
            ?? apps.find(a => (a.id ?? "").toLowerCase().includes(cls))
            ?? null
    }

    // ── ANCHOR: os dots ──
    Workspaces { id: ws }

    // ── PANEL: uma linha por workspace ──
    panel: Item {
        implicitHeight: wsCol.implicitHeight + 8

        Behavior on opacity { NumberAnimation { duration: Motion.quick } }

        HoverHandler { id: panelHover }

        Column {
            id: wsCol

            anchors.top: parent.top
            anchors.left: parent.left
            anchors.right: parent.right
            spacing: 2

            Repeater {
                model: ws.list

                Hoverable {
                    id: wsRow

                    required property var modelData

                    readonly property var wins: root.byWs[modelData.id] ?? []
                    readonly property bool focused: modelData.focused

                    width: wsCol.width
                    height: 24
                    onTapped: Hyprland.dispatch("workspace " + wsRow.modelData.id)

                    // Número (accent = focado)
                    Text {
                        id: wsNum

                        anchors.left: parent.left
                        anchors.leftMargin: 7
                        anchors.verticalCenter: parent.verticalCenter
                        text: wsRow.modelData.id
                        color: wsRow.focused ? Theme.accent : Theme.textSecondary
                        font {
                            family: Theme.fontMono
                            pixelSize: 11
                            weight: wsRow.focused ? 700 : 400
                        }
                        Behavior on color { ColorAnimation { duration: Motion.instant } }
                    }

                    // Ícones das janelas
                    Row {
                        anchors.left: wsNum.right
                        anchors.leftMargin: 10
                        anchors.right: parent.right
                        anchors.rightMargin: 7
                        anchors.verticalCenter: parent.verticalCenter
                        spacing: 5

                        Repeater {
                            model: wsRow.wins

                            Hoverable {
                                id: winItem

                                required property var modelData

                                readonly property var entry: root.entryFor(modelData)

                                width: 18
                                height: 18
                                onTapped: Hyprland.dispatch(
                                    "focuswindow address:"
                                    + winItem.modelData.lastIpcObject.address)

                                IconImage {
                                    anchors.centerIn: parent
                                    width: 14
                                    height: 14
                                    visible: winItem.entry !== null
                                    source: winItem.entry
                                        ? Quickshell.iconPath(winItem.entry.icon, true)
                                        : ""
                                }

                                // Sem .desktop casando: um ponto no lugar
                                Text {
                                    anchors.centerIn: parent
                                    visible: winItem.entry === null
                                    text: "󰄰"
                                    color: Theme.textMuted
                                    font { family: Theme.fontIcon; pixelSize: 10 }
                                }

                            }
                        }
                    }

                    // Vazio: aviso sutil no lugar dos ícones
                    Text {
                        anchors.left: wsNum.right
                        anchors.leftMargin: 10
                        anchors.verticalCenter: parent.verticalCenter
                        visible: wsRow.wins.length === 0
                        text: "vazio"
                        color: Theme.textMuted
                        font { family: Theme.fontDisplay; pixelSize: 10 }
                    }

                }
            }
        }
    }
}
