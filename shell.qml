import QtQuick
import Quickshell
import Quickshell.Io
import Quickshell.Wayland
import Quickshell.Hyprland
import "Apps"
import "Apps/Dashboard"
import "Config"
import "Island"
import "Island/Bar"
import "Services"
import "Settings"
import "Ui"

// ═══════════════════════════════════════════
//  VTNC — shell de Ilha Dinâmica.
//  Este arquivo é o ÚNICO ponto de registro: pra adicionar ou
//  remover um módulo, basta mexer na lista `faces` abaixo.
//
//  Uma janela por tela: a ilha, na layer Overlay. Ela é puramente
//  overlay — não reserva espaço (exclusiveZone: 0) e não empurra
//  janela nenhuma do Hyprland.
// ═══════════════════════════════════════════
ShellRoot {
    id: shell

    // ═══ CONFIG — janela flutuante, fora da shell desenhada ═══
    // Uma só (não por tela) e nasce fechada. Mora aqui dentro de
    // propósito: escreve nos MESMOS singletons que a shell lê, então
    // cada slider reflete ao vivo na ilha
    SettingsWindow {
        id: configWin
        visible: false
    }

    // ═══ PILL — a ilha ═══
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
            // Mouse na faixa do topo revela a pill de volta (com as
            // esperas do HoverGroup lá embaixo, em revealCatch)
            readonly property bool revealHover: revealGroup.open
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
                || (Config.autoHideShowOnDashboard && mine && AppService.active === "dashboard")
                || (Config.autoHideShowOnOsd && OsdService.showing)
                || (Config.autoHideShowOnNotif && notifAuto)
                || revealHover
            readonly property bool hidden: autoHiding && !forced
            property real hideP: hidden ? 1 : 0
            Behavior on hideP {
                // Smooth, não Settle: no modo "retract" o hideP vira xScale,
                // e um overshoot passando de 1 deixaria a escala NEGATIVA
                // (a ilha espelhada por um frame)
                Smooth {}
            }

            screen: modelData
            color: "transparent"
            // Overlay: SEMPRE por cima, e não reserva nem respeita zona
            // exclusiva — a ilha flutua livre no topo
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
                    ? IslandTheme.marginTop + island.height + 24
                    : Config.autoHideRevealZone

                // A espera vale DOBRADO aqui: esta faixa cobre a tela
                // inteira no topo, então qualquer passada do mouse pela
                // borda superior revelaria a ilha escondida. O grace no
                // fechar é o que deixa o mouse descer da faixa até a
                // pill sem ela piscar
                HoverGroup {
                    id: revealGroup
                    candidate: revealCatchHover.hovered ? true : null
                }
                HoverHandler { id: revealCatchHover }
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
            Island {
                id: island

                anchors.top: parent.top
                anchors.topMargin: IslandTheme.marginTop
                anchors.horizontalCenter: parent.horizontalCenter

                // ── AUTOHIDE ── só a animação escolhida age; as outras
                // ficam identidade. hideP: 0 visível → 1 guardada
                opacity: Config.autoHideAnim === "fade" ? 1 - win.hideP : 1
                visible: opacity > 0
                transform: [
                    // slide: sobe pra fora da tela
                    Translate {
                        y: Config.autoHideAnim === "slide"
                            ? -win.hideP * (island.height + IslandTheme.marginTop + 20)
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
                    Bar {},
                    Dashboard {},
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
    //  qs ipc -t dashboard -c toggle | open | close
    //  qs ipc -t config -c toggle | open | close    (app de config)
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
        function dashboard(): void { AppService.toggle("dashboard") }
    }

    IpcHandler {
        target: Config.ipcPillTarget
        // Modo da ilha é global e persistente
        function toggle(): void { Persist.state.wideBar = !Persist.state.wideBar }
        function open(): void { Persist.state.wideBar = true }
        function close(): void { Persist.state.wideBar = false }
    }

    IpcHandler {
        target: Config.ipcConfigTarget
        function toggle(): void { configWin.visible = !configWin.visible }
        function open(): void { configWin.visible = true }
        function close(): void { configWin.visible = false }
    }

    IpcHandler {
        target: Config.ipcDashboardTarget
        function toggle(): void { AppService.toggle("dashboard") }
        function open(): void { AppService.open("dashboard") }
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
        // Virou service: a troca é global, como sempre deveria ter
        // sido. Este handler era o ÚLTIMO resto de roteamento por
        // monitor — ele vasculhava as instâncias vivas da janela pra
        // achar a face do monitor focado e chamar um método nela
        function random(): void { WallpaperService.random() }
    }
}
