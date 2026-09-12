import QtQuick
import ".."
import "../../Config"

SettingsPage {
    title: "Sistema"
    icon: "󰋊"

    SettingGroup {
        title: "Pastas"

        SettingText {
            label: "Wallpapers"
            text: Config.wallpaperPath
            onCommit: v => Config.data.wallpaperPath = v
        }
        SettingText {
            label: "Capturas de tela"
            text: Config.screenshotPath
            onCommit: v => Config.data.screenshotPath = v
        }
        SettingText {
            label: "Gravações"
            text: Config.recordingPath
            onCommit: v => Config.data.recordingPath = v
        }
    }

    SettingGroup {
        title: "Papel de parede e cores"

        SettingText {
            label: "Transição"
            hint: "none · simple · fade · left · right · top · bottom · "
                + "wipe · wave · grow · center · any · outer · random"
            text: Config.wallpaperTransition
            onCommit: v => Config.data.wallpaperTransition = v
        }
        SettingSlider {
            label: "Duração da transição"
            value: Config.wallpaperTransitionMs
            from: 0; to: 4000; step: 100; suffix: "ms"
            onCommit: v => Config.data.wallpaperTransitionMs = v
        }
        SettingToggle {
            label: "Cores seguem o papel de parede"
            hint: "O matugen extrai a paleta da imagem. O FUNDO fica de "
                + "fora e continua #000000 — e a mira do hover também, "
                + "porque ela é camada com alfa, não cor"
            checked: Config.wallpaperTintsShell
            onCommit: v => Config.data.wallpaperTintsShell = v
        }
        SettingText {
            label: "Esquema"
            hint: "scheme-tonal-spot · scheme-vibrant · scheme-content · "
                + "scheme-expressive · scheme-fidelity · scheme-neutral · "
                + "scheme-monochrome · scheme-fruit-salad · scheme-rainbow"
            text: Config.matugenScheme
            onCommit: v => Config.data.matugenScheme = v
        }
        SettingText {
            label: "Cor preferida"
            hint: "Qual candidata vence quando a imagem tem várias: "
                + "darkness · lightness · saturation · less-saturation · value"
            text: Config.matugenPrefer
            onCommit: v => Config.data.matugenPrefer = v
        }
    }

    SettingGroup {
        title: "Programas externos"

        SettingText {
            label: "Rede"
            hint: "Aberto pelo ícone do widget de rede"
            text: Config.networkApp
            onCommit: v => Config.data.networkApp = v
        }
        SettingText {
            label: "Bluetooth"
            text: Config.bluetoothApp
            onCommit: v => Config.data.bluetoothApp = v
        }
    }

    SettingGroup {
        title: "Backlight"
        // sysfs não emite inotify, então a shell relê por polling

        SettingText {
            label: "Arquivo de brilho"
            text: Config.backlightFile
            onCommit: v => Config.data.backlightFile = v
        }
        SettingText {
            label: "Arquivo de máximo"
            text: Config.backlightMaxFile
            onCommit: v => Config.data.backlightMaxFile = v
        }
        SettingSlider {
            label: "Intervalo de leitura"
            hint: "Menor reage mais rápido ao brilho mudar por fora, "
                + "e custa mais CPU à toa"
            value: Config.backlightPollMs
            from: 50; to: 2000; step: 50; suffix: "ms"
            onCommit: v => Config.data.backlightPollMs = v
        }
    }

    SettingGroup {
        title: "Onde isto tudo é gravado"

        SettingRow {
            label: "Pasta de estado"
            hint: "theme · motion · island · config (configuração, dá "
                + "pra copiar pra outra máquina) e state (a shell "
                + "escreve sozinha)"
            controlWidth: 240

            Text {
                anchors.right: parent.right
                anchors.verticalCenter: parent.verticalCenter
                text: Paths.stateDir
                color: Theme.textMuted
                elide: Text.ElideLeft
                width: parent.width
                horizontalAlignment: Text.AlignRight
                font { family: Theme.fontMono; pixelSize: 11 }
            }
        }
    }
}
