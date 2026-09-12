import QtQuick
import ".."
import "../../Config"

SettingsPage {
    title: "Aparência"
    icon: "󰏘"

    SettingGroup {
        title: "Cores"

        SettingColor {
            label: "Destaque"
            hint: "Foco, seleção e o que está ativo"
            value: Theme.accent
            onCommit: hex => Theme.data.accent = hex
        }
        SettingColor {
            label: "Superfície"
            value: Theme.surface
            onCommit: hex => Theme.data.surface = hex
        }
        SettingColor {
            label: "Mira do hover"
            hint: "O fundo de TODO alvo apontado. Use alfa (#2effffff)"
            value: Theme.hoverLayer
            onCommit: hex => Theme.data.hoverLayer = hex
        }
        SettingColor {
            label: "Separador"
            value: Theme.separator
            onCommit: hex => Theme.data.separator = hex
        }
        SettingColor {
            label: "Sombra"
            value: Theme.shadow
            onCommit: hex => Theme.data.shadow = hex
        }
        SettingColor {
            label: "Perigo"
            hint: "Excluir, desligar, bateria crítica"
            value: Theme.danger
            onCommit: hex => Theme.data.danger = hex
        }
    }

    SettingGroup {
        title: "Texto"

        SettingColor {
            label: "Primário"
            value: Theme.textPrimary
            onCommit: hex => Theme.data.textPrimary = hex
        }
        SettingColor {
            label: "Secundário"
            value: Theme.textSecondary
            onCommit: hex => Theme.data.textSecondary = hex
        }
        SettingColor {
            label: "Apagado"
            value: Theme.textMuted
            onCommit: hex => Theme.data.textMuted = hex
        }
        SettingText {
            label: "Fonte de texto"
            text: Theme.fontDisplay
            onCommit: v => Theme.data.fontDisplay = v
        }
        SettingText {
            label: "Fonte monoespaçada"
            hint: "Relógio e números"
            text: Theme.fontMono
            onCommit: v => Theme.data.fontMono = v
        }
        SettingText {
            label: "Fonte de ícones"
            text: Theme.fontIcon
            onCommit: v => Theme.data.fontIcon = v
        }
    }

    SettingGroup {
        title: "Raio"

        SettingSlider {
            label: "Ilha"
            hint: "Teto prático: metade da altura da barra. Acima disso "
                + "o canto volta a variar com a altura"
            value: Theme.radiusIsland
            from: 0; to: 40; suffix: "px"
            onCommit: v => Theme.data.radiusIsland = v
        }
        SettingSlider {
            label: "Card"
            hint: "Raiz da cadeia concêntrica — o chip deriva daqui"
            value: Theme.radiusCard
            from: 0; to: 40; suffix: "px"
            onCommit: v => Theme.data.radiusCard = v
        }
        SettingSlider {
            label: "Cantos da tela"
            value: Theme.radiusScreen
            from: 0; to: 60; suffix: "px"
            onCommit: v => Theme.data.radiusScreen = v
        }
        SettingRow {
            label: "Chip"
            hint: "DERIVADO: card − respiro do card. Não se edita — é o "
                + "que mantém os cantos concêntricos"
            controlWidth: 60

            Text {
                anchors.right: parent.right
                anchors.verticalCenter: parent.verticalCenter
                text: Math.round(Theme.radiusChip) + " px"
                color: Theme.textMuted
                font { family: Theme.fontMono; pixelSize: 12 }
            }
        }
    }

    SettingGroup {
        title: "Espaçamento"

        SettingSlider {
            label: "Respiro do conteúdo"
            value: Theme.contentPadding
            from: 0; to: 30; suffix: "px"
            onCommit: v => Theme.data.contentPadding = v
        }
        SettingSlider {
            label: "Respiro do card"
            hint: "Também define o raio do chip"
            value: Theme.cardPadding
            from: 0; to: 30; suffix: "px"
            onCommit: v => Theme.data.cardPadding = v
        }
    }
}
