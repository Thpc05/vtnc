pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Hyprland

// ═══════════════════════════════════════════
//  FULLSCREEN — Quais monitores têm fullscreen REAL (modo 2).
//  Usado pelo autohide: a pill (e a framed) se escondem no monitor
//  em fullscreen.
//
//  O Hyprland tem DOIS modos: 1 = maximized (respeita a barra) e
//  2 = fullscreen (cobre tudo). O `hasfullscreen` do workspace é só
//  um bool (true pros dois) — não distingue. Mas cada toplevel traz
//  `lastIpcObject.fullscreen` = 0|1|2, o modo. Então olhamos os
//  toplevels: só modo 2 conta como fullscreen aqui — maximizar não
//  esconde a barra.
//
//  `rev` força o mapa a reavaliar (leitura de lastIpcObject não é
//  reativa sozinha); recomputa a cada evento relevante.
// ═══════════════════════════════════════════
Singleton {
    id: root

    property int rev: 0

    function refresh() {
        Hyprland.refreshMonitors()
        Hyprland.refreshToplevels()
        rev++
    }

    // Estado inicial: se o shell nascer já em fullscreen, pega isso
    // sem esperar o primeiro evento
    Component.onCompleted: root.refresh()

    Connections {
        target: Hyprland
        function onRawEvent(event) {
            const n = event.name
            if (n === "fullscreen" || n.indexOf("workspace") === 0
                    || n === "focusedmon" || n === "monitoradded"
                    || n === "monitorremoved"
                    || n === "openwindow" || n === "closewindow"
                    || n === "movewindow") {
                root.refresh()
            }
        }
    }

    // nome do monitor → tem uma janela em fullscreen REAL (modo 2)?
    readonly property var byMonitor: {
        rev // dependência: reavalia quando um evento bate
        const o = ({})
        for (const m of Hyprland.monitors.values)
            o[m.name] = false
        for (const t of Hyprland.toplevels.values) {
            const io = t.lastIpcObject
            if (io && io.fullscreen === 2) {
                const mon = Hyprland.monitors.values.find(m => m.id === io.monitor)
                if (mon)
                    o[mon.name] = true
            }
        }
        return o
    }

    function on(name) {
        return byMonitor[name] === true
    }
}
