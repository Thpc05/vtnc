import QtQuick
import ".."
import "../../Config"

SettingsPage {
    title: "Movimento"
    icon: "󰑮"

    SettingGroup {
        title: "Durações"

        SettingSlider {
            label: "Instantâneo"
            hint: "Cor de hover, acender de borda"
            value: Motion.instant
            from: 0; to: 400; step: 10; suffix: "ms"
            onCommit: v => Motion.data.instant = v
        }
        SettingSlider {
            label: "Rápido"
            hint: "Fades de conteúdo e troca de item"
            value: Motion.quick
            from: 0; to: 400; step: 10; suffix: "ms"
            onCommit: v => Motion.data.quick = v
        }
        SettingSlider {
            label: "Padrão"
            hint: "Expansões: ilha wide, reveal, widget"
            value: Motion.standard
            from: 80; to: 800; step: 10; suffix: "ms"
            onCommit: v => Motion.data.standard = v
        }
        SettingSlider {
            label: "Tracking de slider"
            hint: "Volume e brilho com o botão segurado"
            value: Motion.track
            from: 0; to: 400; step: 10; suffix: "ms"
            onCommit: v => Motion.data.track = v
        }
    }

    SettingGroup {
        title: "Assentamento"

        SettingSlider {
            label: "Overshoot"
            hint: "Não é a fração que passa do alvo: 0.7→1.8% · 1.0→3.7% "
                + "(faixa da Apple) · 1.2→5.3% · 1.7→10%. Acima de ~1.3 "
                + "a ilha pinça visivelmente ao fechar a dashboard"
            value: Motion.overshoot
            from: 0; to: 2; step: 0.1
            onCommit: v => Motion.data.overshoot = v
        }
    }

    SettingGroup {
        title: "Paciência do hover"

        SettingSlider {
            label: "Espera pra abrir"
            hint: "Quanto o mouse precisa descansar antes de algo abrir. "
                + "Abaixo de 200 não filtra nada; acima de 500 parece travado"
            value: Motion.hoverDelay
            from: 0; to: 800; step: 25; suffix: "ms"
            onCommit: v => Motion.data.hoverDelay = v
        }
        SettingSlider {
            label: "Folga pra fechar"
            hint: "Quanto o aberto sobrevive depois que o mouse sai"
            value: Motion.hoverGrace
            from: 0; to: 1000; step: 25; suffix: "ms"
            onCommit: v => Motion.data.hoverGrace = v
        }
    }
}
