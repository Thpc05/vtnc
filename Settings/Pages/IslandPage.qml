import QtQuick
import ".."
import "../../Config"
import "../../Island"

SettingsPage {
    title: "Ilha"
    icon: "󰟾"

    SettingGroup {
        title: "Tamanho"

        SettingSlider {
            label: "Largura (normal)"
            value: IslandTheme.width
            from: 60; to: 400; suffix: "px"
            onCommit: v => IslandTheme.data.width = v
        }
        SettingSlider {
            label: "Altura"
            hint: "Também é o teto útil do raio da ilha (metade dela)"
            value: IslandTheme.height
            from: 20; to: 80; suffix: "px"
            onCommit: v => IslandTheme.data.height = v
        }
        SettingSlider {
            label: "Largura (wide)"
            hint: "Base do modo largo; workspaces e cluster somam a isto"
            value: IslandTheme.wideWidth
            from: 60; to: 500; suffix: "px"
            onCommit: v => IslandTheme.data.wideWidth = v
        }
        SettingSlider {
            label: "Altura (wide)"
            value: IslandTheme.wideHeight
            from: 20; to: 80; suffix: "px"
            onCommit: v => IslandTheme.data.wideHeight = v
        }
        SettingSlider {
            label: "Distância do topo"
            value: IslandTheme.marginTop
            from: 0; to: 40; suffix: "px"
            onCommit: v => IslandTheme.data.marginTop = v
        }
    }

    SettingGroup {
        title: "Coreografia do morph"

        SettingSlider {
            label: "Conteúdo sai"
            value: IslandTheme.faceFadeOut
            from: 0; to: 400; step: 10; suffix: "ms"
            onCommit: v => IslandTheme.data.faceFadeOut = v
        }
        SettingSlider {
            label: "Ilha morfa"
            value: IslandTheme.morphDuration
            from: 80; to: 800; step: 10; suffix: "ms"
            onCommit: v => IslandTheme.data.morphDuration = v
        }
        SettingSlider {
            label: "Espera antes do conteúdo"
            value: IslandTheme.faceFadeInDelay
            from: 0; to: 600; step: 10; suffix: "ms"
            onCommit: v => IslandTheme.data.faceFadeInDelay = v
        }
        SettingSlider {
            label: "Conteúdo entra"
            value: IslandTheme.faceFadeIn
            from: 0; to: 400; step: 10; suffix: "ms"
            onCommit: v => IslandTheme.data.faceFadeIn = v
        }

        // A invariante é fácil de furar mexendo nos sliders acima, e o
        // sintoma (tamanho saltando no fim do morph) não é óbvio
        SettingRow {
            label: "Invariante"
            hint: "morfar ≤ espera + entrar. Furada, o tamanho da ilha "
                + "SALTA no fim do morph, porque os Behaviors dela já "
                + "desligaram"
            controlWidth: 130

            readonly property bool ok:
                IslandTheme.morphDuration
                <= IslandTheme.faceFadeInDelay + IslandTheme.faceFadeIn

            Text {
                anchors.right: parent.right
                anchors.verticalCenter: parent.verticalCenter
                text: parent.ok
                    ? "ok (folga " + (IslandTheme.faceFadeInDelay
                        + IslandTheme.faceFadeIn - IslandTheme.morphDuration) + "ms)"
                    : "FURADA"
                color: parent.ok ? Theme.textMuted : Theme.danger
                font { family: Theme.fontMono; pixelSize: 12 }
            }
        }

        SettingRow {
            label: "Dashboard"
            hint: "DERIVADO: sair + morfar. É o que faz a dashboard "
                + "assentar no mesmo instante que um app"
            controlWidth: 80

            Text {
                anchors.right: parent.right
                anchors.verticalCenter: parent.verticalCenter
                text: IslandTheme.dashDuration + " ms"
                color: Theme.textMuted
                font { family: Theme.fontMono; pixelSize: 12 }
            }
        }
    }

    SettingGroup {
        title: "Escala do conteúdo"

        SettingSlider {
            label: "Quem sai encolhe até"
            value: IslandTheme.faceScaleOut
            from: 0.5; to: 1; step: 0.01
            onCommit: v => IslandTheme.data.faceScaleOut = v
        }
        SettingSlider {
            label: "Quem entra nasce em"
            hint: "Abaixo de 1 o conteúdo parece estar DENTRO da ilha "
                + "que se move, em vez de piscar por cima dela"
            value: IslandTheme.faceScaleIn
            from: 0.5; to: 1; step: 0.01
            onCommit: v => IslandTheme.data.faceScaleIn = v
        }
    }
}
