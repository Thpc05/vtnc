import QtQuick
import "."
import "../../../Config"
import "../../../Services"

// ═══════════════════════════════════════════
//  BRIGHTNESS CARD — O slider de brilho.
//  Lê do OsdService (que já faz o polling do sysfs) e escreve pelo
//  brightnessctl. Sem detalhe: brilho é um número só.
// ═══════════════════════════════════════════
SliderCard {
    id: root

    icon: {
        const p = OsdService.brightnessPct
        if (p >= 66) return "󰃠"
        if (p >= 33) return "󰃟"
        return "󰃞"
    }

    value: OsdService.brightnessPct / 100

    // Piso em 1%: zero apaga a tela e não há como enxergar pra
    // desfazer. O brightnessctl aceita 0 — nós é que não devemos
    onCommit: v => OsdService.setBrightness(Math.max(1, v * 100))
}
