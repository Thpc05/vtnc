import QtQuick
import Quickshell
import Quickshell.Io
import Quickshell.Wayland
import Quickshell.Hyprland
import "Components"
import "Components/Pill"
import "Components/Framed"
import "Services"
import "Apps"

// ═══════════════════════════════════════════
//  VTNC — shell de Ilha Dinâmica.
//  Este arquivo é o ÚNICO ponto de registro: pra adicionar ou
//  remover um módulo, basta mexer na lista `faces` abaixo.
//
//  Até 3 janelas por tela, nesta ordem (a ordem de declaração é o
//  z-order dentro da mesma layer — a última mapeada fica por cima):
//    1. RESERVA (invisível) — reserva o espaço de topo (exclusiveZone)
//    2. FRAMED  — a barra de topo (só quando ligada), por baixo
//    3. PILL    — a ilha, por cima de tudo (intocada)
//  A ilha é overlay: ela mesma não reserva espaço (exclusiveZone: 0).
// ═══════════════════════════════════════════
ShellRoot {
    id: shell

    // Base da reserva de topo. Hoje só a framed reserva; o futuro
    // `|| (pillExclusive ? ... )` entra aqui
    readonly property real framedReserve: Persist.state.framed ? Framed_Theme.height : 0

    // ═══ 1. RESERVA (exclusivezone) — janela invisível, por tela ═══
    // Ancorada só no topo: o layer-shell respeita a zona exclusiva dela
    // e empurra as janelas pra baixo. Clique atravessa (mask vazia).
    // Per-monitor: no monitor em fullscreen a reserva SOLTA (0) — as
    // janelas sobem junto com a framed que some
    Variants {
        model: shell.framedReserve > 0 ? Quickshell.screens : []

        PanelWindow {
            required property var modelData
            screen: modelData
            color: "transparent"
            anchors { top: true; left: true; right: true }
            implicitHeight: Framed_Theme.height
            // Esta É quem reserva: reserva o espaço contra as janelas
            // reais do Hyprland (a framed e a pill IGNORAM esta zona)
            WlrLayershell.exclusionMode: ExclusionMode.Normal
            exclusiveZone: Fullscreen.on(modelData.name) ? 0 : shell.framedReserve
            mask: Region {}
        }
    }

    // ═══ 2. FRAMED — a barra de topo (por baixo da pill) ═══
    Variants {
        model: Persist.state.framed ? Quickshell.screens : []

        PanelWindow {
            id: framedWin

            required property var modelData
            readonly property alias bar: bar

            screen: modelData
            color: "transparent"
            // Camada Top (acima das janelas), mas IGNORA a zona da
            // reserva — senão a barra desceria pra dentro do espaço
            // que ela mesma reservou. A pill (Overlay) fica por cima.
            WlrLayershell.layer: WlrLayer.Top
            WlrLayershell.exclusionMode: ExclusionMode.Ignore
            anchors { top: true; bottom: true; left: true; right: true }

            // ── AUTOHIDE ── some no fullscreen (junto com a reserva).
            // Sem peek e sem alwaysAutoHide — a framed só reage ao
            // fullscreen; o peek do topo é só da pill
            readonly property bool hidden: Fullscreen.on(modelData.name)
            property real hideP: hidden ? 1 : 0
            Behavior on hideP {
                NumberAnimation { duration: Theme.expandDuration; easing.type: Easing.OutQuart }
            }

            // Só a faixa e a bolha ativa recebem clique; o resto
            // atravessa pro Hyprland
            mask: Region {
                item: bar.hitAreas[0]
                Region {
                    item: bar.hitAreas[1]
                    intersection: Intersection.Combine
                }
            }

            Framed {
                id: bar
                anchors.fill: parent
                onBackgroundTapped: AppService.toggleDashboard()

                // Fade escolhe opacity; slide/retract sobem a barra
                opacity: Config.autoHideAnim === "fade" ? 1 - framedWin.hideP : 1
                transform: Translate {
                    y: Config.autoHideAnim === "fade"
                        ? 0
                        : -framedWin.hideP * Framed_Theme.height
                }
            }
        }
    }

    // ═══ 3. PILL — a ilha (por cima) ═══
    Variants {
        id: windows

        model: Quickshell.screens

        PanelWindow {
            id: win

            required property var modelData
            readonly property alias island: island

            // Este monitor é o dono do que está aberto? App e dashboard
            // nascem no monitor focado; os outros seguem só com a barra
            readonly property bool mine: AppService.showsOn(modelData.name)

            // Apps E dashboard cobrem a tela (clique-fora-fecha); só
            // apps capturam teclado — hover não rouba nada. Só a janela
            // dona reage — senão as duas telas se copiam
            readonly property bool isOpen: mine && AppService.isOpen

            // ── AUTOHIDE ── (este monitor)
            readonly property bool autoHiding:
                Fullscreen.on(modelData.name) || Config.alwaysAutoHide
            // Mouse na faixa do topo revela a pill de volta
            property bool revealHover: false
            // Notificação recém-chegada (peek temporário)
            property bool notifAuto: false
            Connections {
                target: NotifServer
                function onNotified() {
                    win.notifAuto = true
                    notifAutoTimer.restart()
                }
            }
            Timer {
                id: notifAutoTimer
                interval: Config.notifyTimeout
                onTriggered: win.notifAuto = false
            }
            // O que força a pill visível apesar do autohide (cada
            // gatilho é opcional via Config)
            readonly property bool forced:
                  (Config.autoHideShowOnApp && mine && AppService.hasApp)
                || (Config.autoHideShowOnDashboard && mine && AppService.dashboard)
                || (Config.autoHideShowOnOsd && OsdService.showing)
                || (Config.autoHideShowOnNotif && notifAuto)
                || revealHover
            readonly property bool hidden: autoHiding && !forced
            property real hideP: hidden ? 1 : 0
            Behavior on hideP {
                NumberAnimation { duration: Theme.expandDuration; easing.type: Easing.OutQuart }
            }

            screen: modelData
            color: "transparent"
            // Overlay: SEMPRE por cima (inclusive da framed, que é Top)
            // e IGNORA a zona da reserva — a ilha flutua livre no topo
            WlrLayershell.layer: WlrLayer.Overlay
            WlrLayershell.exclusionMode: ExclusionMode.Ignore
            WlrLayershell.keyboardFocus: (mine && AppService.wantsKeyboard)
                ? WlrKeyboardFocus.Exclusive
                : WlrKeyboardFocus.None

            anchors {
                top: true
                bottom: true
                left: true
                right: true
            }

            // Fora da ilha, cliques passam direto pro Hyprland
            // (click-through). App aberto → tela toda; autohide → a
            // faixa de captura no topo; senão → a ilha
            mask: Region {
                item: win.isOpen ? bgClickArea
                    : (win.autoHiding ? revealCatch : island)
            }

            // ── FAIXA DE REVEAL ── no topo, full-width. Fina quando a
            // pill está guardada (só o gatilho); ao ser mirada, CRESCE
            // pra cobrir a pill revelada — assim o mouse desce até ela
            // sem sair da faixa e a pill não pisca. HoverHandler passivo:
            // os cliques ainda chegam na pill embaixo
            Item {
                id: revealCatch

                anchors.top: parent.top
                anchors.left: parent.left
                anchors.right: parent.right
                height: win.revealHover
                    ? Pill_Theme.marginTop + island.height + 24
                    : Config.autoHideRevealZone

                HoverHandler {
                    onHoveredChanged: {
                        if (hovered) {
                            revealCloseTimer.stop()
                            win.revealHover = true
                        } else {
                            revealCloseTimer.restart()
                        }
                    }
                }
                // Grace pro mouse cruzar da faixa até a pill sem piscar
                Timer {
                    id: revealCloseTimer
                    interval: 300
                    onTriggered: win.revealHover = false
                }
            }

            // Overlay invisível — clique fora fecha o app.
            // TapHandler não toma grab exclusivo, então cliques DENTRO
            // da ilha também chegariam aqui: o hit-test descarta eles
            Item {
                id: bgClickArea

                anchors.fill: parent

                TapHandler {
                    enabled: win.isOpen
                    onTapped: eventPoint => {
                        const l = bgClickArea.mapToItem(
                            island, eventPoint.position.x, eventPoint.position.y)
                        if (l.x >= 0 && l.x <= island.width
                            && l.y >= 0 && l.y <= island.height)
                            return
                        AppService.close()
                    }
                }
            }

            // ═══ CANTOS ARREDONDADOS DA TELA ═══
            // Puramente visual — fora da mask, nunca intercepta clique
            ScreenCorners {
                anchors.fill: parent
            }

            // ═══ A ILHA ═══
            Pill {
                id: island

                anchors.top: parent.top
                anchors.topMargin: Pill_Theme.marginTop
                anchors.horizontalCenter: parent.horizontalCenter

                // ── AUTOHIDE ── só a animação escolhida age; as outras
                // ficam identidade. hideP: 0 visível → 1 guardada
                opacity: Config.autoHideAnim === "fade" ? 1 - win.hideP : 1
                visible: opacity > 0
                transform: [
                    // slide: sobe pra fora da tela
                    Translate {
                        y: Config.autoHideAnim === "slide"
                            ? -win.hideP * (island.height + Pill_Theme.marginTop + 20)
                            : 0
                    },
                    // retract: encolhe a largura pro centro
                    Scale {
                        origin.x: island.width / 2
                        xScale: Config.autoHideAnim === "retract" ? 1 - win.hideP : 1
                    }
                ]

                // ── REGISTRO DE MÓDULOS ──
                // Cada face é independente: remova uma linha (e o
                // arquivo) e o resto continua funcionando.
                //
                // Só morfa em app/dashboard se este for o monitor dono
                // (a barra idle/wide/reveals continua em todas as telas)
                monitorActive: win.mine

                // Volume/brilho NÃO são faces: são conteúdo do Center,
                // com estado no OsdService.
                faces: [
                    PillBar {},
                    Launcher {},
                    Wallpaper {},
                    Tools {},
                    Clipboard {},
                    Session {}
                ]
            }
        }
    }

    // ═══════════════════════════════════════════
    //  IPC GLOBAL — os handlers moram AQUI (um por target na shell
    //  inteira): dentro das janelas eles duplicariam por tela e só a
    //  primeira registrada atenderia.
    //
    //  qs ipc call island toggle <nome> | open <nome> | close
    //  qs ipc -t pill -c toggle | open | close   (ilha normal ↔ wide)
    //  qs ipc -t framed -c toggle | open | close (barra de topo)
    //  qs ipc -t dashboard -c toggle | open | close
    //  qs ipc -t osd -c volume | brightness
    //  qs ipc -t launcher | tools | clipboard | session -c toggle
    //  qs ipc -t wallpaper -c toggle | random
    // ═══════════════════════════════════════════
    IpcHandler {
        target: Config.ipcTarget
        function open(name: string): void { AppService.open(name) }
        function toggle(name: string): void { AppService.toggle(name) }
        function close(): void { AppService.close() }
        function osd(name: string): void { OsdService.show(name) }
        function dashboard(): void { AppService.toggleDashboard() }
    }

    IpcHandler {
        target: Config.ipcPillTarget
        // Modo da ilha é global e persistente
        function toggle(): void { Persist.state.wideBar = !Persist.state.wideBar }
        function open(): void { Persist.state.wideBar = true }
        function close(): void { Persist.state.wideBar = false }
    }

    IpcHandler {
        target: Config.ipcFramedTarget
        // Barra de topo independente (por baixo da pill), global
        function toggle(): void { Persist.state.framed = !Persist.state.framed }
        function open(): void { Persist.state.framed = true }
        function close(): void { Persist.state.framed = false }
    }

    IpcHandler {
        target: Config.ipcDashboardTarget
        function toggle(): void { AppService.toggleDashboard() }
        function open(): void { AppService.openDashboard() }
        function close(): void { AppService.close() }
    }

    // Os OSDs se mostram sozinhos quando volume/brilho mudam; isto é
    // só o empurrão manual
    IpcHandler {
        target: Config.ipcOsdTarget
        function volume(): void { OsdService.show("volume") }
        function brightness(): void { OsdService.show("brightness") }
    }

    // ── APPS: um target por app (os binds do Hyprland usam estes) ──
    IpcHandler {
        target: Config.ipcLauncherTarget
        function toggle(): void { AppService.toggle("launcher") }
        function close(): void { AppService.close() }
    }

    IpcHandler {
        target: Config.ipcToolsTarget
        function toggle(): void { AppService.toggle("tools") }
        function close(): void { AppService.close() }
    }

    IpcHandler {
        target: Config.ipcClipboardTarget
        function toggle(): void { AppService.toggle("clipboard") }
        function close(): void { AppService.close() }
    }

    IpcHandler {
        target: Config.ipcSessionTarget
        function toggle(): void { AppService.toggle("session") }
        function close(): void { AppService.close() }
    }

    IpcHandler {
        target: Config.ipcWallpaperTarget
        function toggle(): void { AppService.toggle("wallpaper") }
        // AÇÃO da face, não estado: precisa alcançar a instância viva.
        // Único resto do roteamento por monitor — some quando o
        // wallpaper virar service (a troca é global, como o resto)
        function random(): void {
            const insts = windows.instances
            if (!insts || insts.length === 0)
                return
            const mon = Hyprland.focusedMonitor
            const hit = mon ? insts.find(w => w.screen?.name === mon.name) : null
            ;(hit ?? insts[0]).island.faceByName("wallpaper")?.randomWall()
        }
    }
}
