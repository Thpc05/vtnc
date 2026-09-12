import QtQuick
import ".."
import "../../Config"

SettingsPage {
    title: "Dashboard"
    icon: "󰕮"

    SettingGroup {
        title: "Grade"

        SettingSlider {
            label: "Largura"
            value: Theme.dashWidth
            from: 300; to: 1200; step: 10; suffix: "px"
            onCommit: v => Theme.data.dashWidth = v
        }
        SettingSlider {
            label: "Altura do card"
            hint: "O card de mídia vale dois; os sliders, 0.72"
            value: Theme.dashCell
            from: 24; to: 160; suffix: "px"
            onCommit: v => Theme.data.dashCell = v
        }
        SettingSlider {
            label: "Vão entre células"
            value: Theme.dashGap
            from: 0; to: 32; suffix: "px"
            onCommit: v => Theme.data.dashGap = v
        }
        SettingSlider {
            label: "Altura do topo"
            hint: "A faixa que vira a title bar quando a dashboard abre"
            value: Theme.dashTopHeight
            from: 20; to: 100; suffix: "px"
            onCommit: v => Theme.data.dashTopHeight = v
        }
    }

    SettingGroup {
        title: "Aparência"

        SettingSlider {
            label: "Blur da capa"
            hint: "A capa do álbum no fundo do widget de mídia"
            value: Theme.widgetMediaBlur
            from: 0; to: 1; step: 0.05
            onCommit: v => Theme.data.widgetMediaBlur = v
        }
        SettingSlider {
            label: "Entrada do conteúdo"
            hint: "Em que ponto da expansão o conteúdo começa a aparecer. "
                + "Menor entra antes e mais gradual (menos 'pipoca')"
            value: Theme.dashContentStart
            from: 0; to: 0.99; step: 0.05
            onCommit: v => Theme.data.dashContentStart = v
        }
        SettingSlider {
            label: "Entrada padrão"
            hint: "O mesmo, para o resto da shell"
            value: Theme.lateStart
            from: 0; to: 0.99; step: 0.05
            onCommit: v => Theme.data.lateStart = v
        }
    }

    SettingGroup {
        title: "OSD e notificações"

        SettingSlider {
            label: "Largura da barra do OSD"
            hint: "Pixels por 1% de volume/brilho"
            value: Theme.osdPxPerPct
            from: 0.5; to: 6; step: 0.5
            onCommit: v => Theme.data.osdPxPerPct = v
        }
        SettingSlider {
            label: "Altura do histórico"
            value: Theme.notifHistoryMaxHeight
            from: 60; to: 600; step: 10; suffix: "px"
            onCommit: v => Theme.data.notifHistoryMaxHeight = v
        }
        SettingSlider {
            label: "Largura do launcher"
            value: Theme.launcherWidth
            from: 300; to: 1000; step: 10; suffix: "px"
            onCommit: v => Theme.data.launcherWidth = v
        }
    }
}
