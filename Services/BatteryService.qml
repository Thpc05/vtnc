pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Services.UPower
import "../ConfigValues"

// ═══════════════════════════════════════════
//  BATTERY SERVICE — Estado da bateria (UPower) num lugar só.
//  O ícone (Island/Bar/Battery) e o painel (Island/Bar/BatteryReveal)
//  liam o mesmo dado cada um por si — inclusive a tabela de glyphs,
//  que é derivação do nível, não desenho.
//
//  Sem device (desktop), `percentage` é 100 e `low` é falso: quem
//  mostra a bateria de emergência simplesmente nunca aparece.
// ═══════════════════════════════════════════
Singleton {
    id: root

    readonly property var device: UPower.displayDevice
    readonly property int percentage: device ? Math.round(device.percentage * 100) : 100
    readonly property bool charging: device
        ? (device.state === UPowerDeviceState.Charging)
        : false

    // Nível de aviso: só "grita" quando é baixo E não está carregando
    readonly property bool low: percentage < Config.batteryWarnLevel
    readonly property bool warning: low && !charging

    // Estimativa: carregando → até cheio; na bateria → restante
    readonly property int etaSecs: device
        ? (charging ? device.timeToFull : device.timeToEmpty)
        : 0
    readonly property string eta: {
        if (etaSecs <= 0)
            return ""
        const h = Math.floor(etaSecs / 3600)
        const m = Math.round((etaSecs % 3600) / 60)
        const t = h > 0 ? `${h}h${String(m).padStart(2, "0")}` : `${m}min`
        return charging ? `${t} até cheio` : `${t} restantes`
    }

    // Glyph por nível (Nerd Font). É derivação do dado — quem desenha
    // só pede o ícone e não repete a escada de ifs
    readonly property string icon: {
        const p = percentage
        if (charging) {
            if (p === 100) return "󰂅"
            if (p >= 90) return "󰂋"
            if (p >= 80) return "󰂊"
            if (p >= 70) return "󰢞"
            if (p >= 60) return "󰂉"
            if (p >= 50) return "󰢝"
            if (p >= 40) return "󰂈"
            if (p >= 30) return "󰂇"
            if (p >= 20) return "󰂆"
            return "󰢜"
        }
        if (p === 100) return "󰁹"
        if (p >= 90) return "󰂂"
        if (p >= 80) return "󰂁"
        if (p >= 70) return "󰂀"
        if (p >= 60) return "󰁿"
        if (p >= 50) return "󰁾"
        if (p >= 40) return "󰁽"
        if (p >= 30) return "󰁼"
        if (p >= 20) return "󰁻"
        return "󰁺"
    }
}
