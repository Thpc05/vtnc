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
