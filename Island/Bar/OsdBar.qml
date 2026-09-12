import QtQuick
import "../../ConfigValues"

// ═══════════════════════════════════════════
//  OSD BAR — ícone | barra | porcentagem.
//  A linha que volume e brilho mostram no centro da ilha.
//
//  A barra É o valor (Theme.osdPxPerPct por %) — quem passa o `pct`
//  já manda ele animado, então largura e preenchimento derivam do
//  mesmo número e não têm como dessincronizar.
//
//  `overdriveOn`: só o volume passa de 100%. Daí em diante ele
//  esvermelhece e engorda gradualmente até 150%.
// ═══════════════════════════════════════════
Row {
    id: root

    property int pct: 0
    property string icon: ""
    property bool muted: false
    property bool overdriveOn: false

    spacing: 12

    // 0 → 1 conforme vai de 100% a 150%
    readonly property real overdrive: overdriveOn
        ? Math.max(0, Math.min(1, (pct - 100) / 50))
        : 0
    // Curva sqrt: o vermelho já é perceptível logo acima de 100%
    readonly property real redMix: Math.sqrt(overdrive)

    readonly property color barColor: {
        if (muted)
            return Theme.textMuted
        return Qt.rgba(
            Theme.accent.r + (Theme.danger.r - Theme.accent.r) * redMix,
            Theme.accent.g + (Theme.danger.g - Theme.accent.g) * redMix,
            Theme.accent.b + (Theme.danger.b - Theme.accent.b) * redMix,
            1)
    }

    Text {
        anchors.verticalCenter: parent.verticalCenter
        text: root.icon
        color: root.barColor
        font { family: Theme.fontIcon; pixelSize: 15 }
    }

    // A barra: o width É o valor, já animado por quem passa o pct
    Rectangle {
        anchors.verticalCenter: parent.verticalCenter
        width: root.pct * Theme.osdPxPerPct
        height: 5
        radius: 2.5
        color: root.barColor
    }

    // Caixa medida pelo Nº DE DÍGITOS atual (mono: dígito não muda de
    // largura) — só cresce/encolhe ao cruzar 9↔10↔100, animado, pra
    // barra ficar centrada sem folga morta
    Item {
        anchors.verticalCenter: parent.verticalCenter
        visible: Config.osdShowPercent
        width: pctMetrics.width
        height: pctText.implicitHeight
        Behavior on width {
            NumberAnimation { duration: Motion.instant; easing.type: Easing.OutCubic }
        }

        Text {
            id: pctText

            anchors.left: parent.left
            text: root.muted ? "mute" : `${root.pct}%`
            // < 100%: cor primária; acima: esvermelhece gradualmente
            color: Qt.rgba(
                Theme.textPrimary.r + (Theme.danger.r - Theme.textPrimary.r) * root.redMix,
                Theme.textPrimary.g + (Theme.danger.g - Theme.textPrimary.g) * root.redMix,
                Theme.textPrimary.b + (Theme.danger.b - Theme.textPrimary.b) * root.redMix,
                1)
            font {
                family: Theme.fontMono
                pixelSize: 12
                // Peso aumenta gradualmente acima de 100%
                weight: 500 + Math.round(root.overdrive * 300)
            }
        }
    }

    TextMetrics {
        id: pctMetrics

        font.family: Theme.fontMono
        font.pixelSize: 12
        text: {
            if (root.muted) return "mute"
            if (root.pct >= 100) return "111%"
            if (root.pct >= 10) return "11%"
            return "8%"
        }
    }
}
