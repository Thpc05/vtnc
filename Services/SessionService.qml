pragma Singleton
import QtQuick
import Quickshell

// ═══════════════════════════════════════════
//  SESSION SERVICE — Ações de sessão, usadas pelo Apps/Session.qml.
//  (o nome é "SessionService" pra não colidir com o tipo do app)
//
//  `danger`: ações destrutivas ficam vermelhas ao selecionar.
// ═══════════════════════════════════════════
Singleton {
    id: root

    readonly property var actions: [
        { id: "lock",     icon: "󰌾", label: "Bloquear" },
        { id: "logout",   icon: "󰍃", label: "Sair", danger: true },
        { id: "suspend",  icon: "󰒲", label: "Suspender" },
        { id: "reboot",   icon: "󰜉", label: "Reiniciar", danger: true },
        { id: "shutdown", icon: "󰐥", label: "Desligar", danger: true }
    ]

    function run(id) {
        switch (id) {
        case "lock":
            // TODO: locker ainda não escolhido (hyprlock? swaylock?)
            break
        case "logout":
            // O Hyprland daqui tem plugin lua que intercepta
            // `hyprctl dispatch`: a sintaxe é lua, não o exit nativo
            Quickshell.execDetached(["hyprctl", "dispatch", "hl.dsp.exit()"])
            break
        case "suspend":
            Quickshell.execDetached(["systemctl", "suspend"])
            break
        case "reboot":
            Quickshell.execDetached(["systemctl", "reboot"])
            break
        case "shutdown":
            Quickshell.execDetached(["systemctl", "poweroff"])
            break
        }
    }
}
