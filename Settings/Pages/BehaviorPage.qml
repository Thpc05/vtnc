import QtQuick
import ".."
import "../../Config"

SettingsPage {
    title: "Comportamento"
    icon: "󰒓"

    SettingGroup {
        title: "Autohide"
        // A ilha se esconde no monitor em fullscreen; o mouse no topo
        // da tela traz ela de volta

        SettingToggle {
            label: "Esconder sempre"
            hint: "Não só em fullscreen: a ilha vive guardada e só o "
                + "mouse no topo revela"
            checked: Config.alwaysAutoHide
            onCommit: v => Config.data.alwaysAutoHide = v
        }
        SettingSlider {
            label: "Faixa de revelação"
            hint: "Altura da tira no topo que reage ao mouse"
            value: Config.autoHideRevealZone
            from: 1; to: 40; suffix: "px"
            onCommit: v => Config.data.autoHideRevealZone = v
        }
        SettingText {
            label: "Animação"
            hint: "slide · fade · retract"
            text: Config.autoHideAnim
            onCommit: v => Config.data.autoHideAnim = v
        }
    }

    SettingGroup {
        title: "O que força a ilha a aparecer"

        SettingToggle {
            label: "App aberto"
            hint: "Desligar isto faz o launcher em fullscreen digitar "
                + "numa ilha invisível — deixe ligado a menos que saiba "
                + "o que quer"
            checked: Config.autoHideShowOnApp
            onCommit: v => Config.data.autoHideShowOnApp = v
        }
        SettingToggle {
            label: "Dashboard aberta"
            checked: Config.autoHideShowOnDashboard
            onCommit: v => Config.data.autoHideShowOnDashboard = v
        }
        SettingToggle {
            label: "Volume / brilho"
            checked: Config.autoHideShowOnOsd
            onCommit: v => Config.data.autoHideShowOnOsd = v
        }
        SettingToggle {
            label: "Notificação chegando"
            checked: Config.autoHideShowOnNotif
            onCommit: v => Config.data.autoHideShowOnNotif = v
        }
    }

    SettingGroup {
        title: "OSD e notificações"

        SettingSlider {
            label: "OSD some depois de"
            value: Config.osdTimeout
            from: 500; to: 8000; step: 250; suffix: "ms"
            onCommit: v => Config.data.osdTimeout = v
        }
        SettingToggle {
            label: "Mostrar porcentagem"
            hint: "O número ao lado da barra de volume/brilho"
            checked: Config.osdShowPercent
            onCommit: v => Config.data.osdShowPercent = v
        }
        SettingSlider {
            label: "Notificação some depois de"
            value: Config.notifyTimeout
            from: 1000; to: 15000; step: 500; suffix: "ms"
            onCommit: v => Config.data.notifyTimeout = v
        }
        SettingSlider {
            label: "Histórico guarda"
            value: Config.maxNotifHistory
            from: 1; to: 100; suffix: "itens"
            onCommit: v => Config.data.maxNotifHistory = v
        }
    }

    SettingGroup {
        title: "Diversos"

        SettingSlider {
            label: "Resultados do launcher"
            value: Config.maxLauncherResults
            from: 1; to: 20; suffix: "itens"
            onCommit: v => Config.data.maxLauncherResults = v
        }
        SettingSlider {
            label: "Aviso de bateria"
            hint: "Abaixo disto a bateria aparece ao lado do relógio. "
                + "100 = sempre visível, útil pra testar"
            value: Config.batteryWarnLevel
            from: 0; to: 100; suffix: "%"
            onCommit: v => Config.data.batteryWarnLevel = v
        }
        SettingToggle {
            label: "Legenda no Tools"
            hint: "Nome do selecionado embaixo dos ícones"
            checked: Config.showTips
            onCommit: v => Config.data.showTips = v
        }
    }
}
