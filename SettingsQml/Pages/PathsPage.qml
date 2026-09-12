import QtQuick
import ".."
import "../../ConfigValues"

SettingsPage {
    title: "System"
    icon: "󰋊"

    SettingGroup {
        title: "Folders"

        SettingText {
            label: "Wallpapers"
            text: Config.wallpaperPath
            store: Config.data; key: "wallpaperPath"; defaults: Defaults.config
        }
        SettingText {
            label: "Screenshots"
            text: Config.screenshotPath
            store: Config.data; key: "screenshotPath"; defaults: Defaults.config
        }
        SettingText {
            label: "Recordings"
            text: Config.recordingPath
            store: Config.data; key: "recordingPath"; defaults: Defaults.config
        }
    }

    SettingGroup {
        title: "Wallpaper and colors"

        SettingChoice {
            label: "Transition"
            options: ["none", "simple", "fade", "left", "right", "top",
                      "bottom", "wipe", "wave", "grow", "center", "any",
                      "outer", "random"]
            value: Config.wallpaperTransition
            store: Config.data; key: "wallpaperTransition"; defaults: Defaults.config
        }
        SettingSlider {
            label: "Transition duration"
            value: Config.wallpaperTransitionMs
            from: 0; to: 4000; step: 100; suffix: "ms"
            store: Config.data; key: "wallpaperTransitionMs"; defaults: Defaults.config
        }
        SettingToggle {
            label: "Colors follow the wallpaper"
            hint: "matugen pulls the palette out of the image. The "
                + "background stays #000000, and so does the hover layer — "
                + "it is an alpha layer, not a color"
            checked: Config.wallpaperTintsShell
            store: Config.data; key: "wallpaperTintsShell"; defaults: Defaults.config
        }
        SettingChoice {
            label: "Scheme"
            hint: "How far the palette drifts from the image: content and "
                + "fidelity stay faithful, expressive shifts the hue on "
                + "purpose, monochrome drops color entirely"
            options: ["scheme-tonal-spot", "scheme-vibrant", "scheme-content",
                      "scheme-expressive", "scheme-fidelity", "scheme-neutral",
                      "scheme-monochrome", "scheme-fruit-salad", "scheme-rainbow"]
            value: Config.matugenScheme
            store: Config.data; key: "matugenScheme"; defaults: Defaults.config
        }
        SettingChoice {
            label: "Preferred source color"
            hint: "Which candidate wins when the image has several. This "
                + "changes the palette MORE than the scheme does"
            options: ["saturation", "less-saturation", "darkness",
                      "lightness", "value", "closest-to-fallback"]
            value: Config.matugenPrefer
            store: Config.data; key: "matugenPrefer"; defaults: Defaults.config
        }
    }

    SettingGroup {
        title: "External apps"

        SettingText {
            label: "Network"
            hint: "Opened from the network detail screen"
            text: Config.networkApp
            store: Config.data; key: "networkApp"; defaults: Defaults.config
        }
        SettingText {
            label: "Bluetooth"
            text: Config.bluetoothApp
            store: Config.data; key: "bluetoothApp"; defaults: Defaults.config
        }
    }

    SettingGroup {
        title: "Backlight"
        // sysfs emits no inotify, so the shell re-reads it by polling

        SettingText {
            label: "Brightness file"
            text: Config.backlightFile
            store: Config.data; key: "backlightFile"; defaults: Defaults.config
        }
        SettingText {
            label: "Maximum file"
            text: Config.backlightMaxFile
            store: Config.data; key: "backlightMaxFile"; defaults: Defaults.config
        }
        SettingSlider {
            label: "Poll interval"
            hint: "Lower reacts faster when brightness changes elsewhere, "
                + "and costs more CPU for nothing"
            value: Config.backlightPollMs
            from: 50; to: 2000; step: 50; suffix: "ms"
            store: Config.data; key: "backlightPollMs"; defaults: Defaults.config
        }
    }

    SettingGroup {
        title: "Where all this is written"

        SettingRow {
            label: "State folder"
            hint: "theme · motion · island · config are configuration and "
                + "can be copied to another machine; state is what the "
                + "shell writes on its own. Factory values live in the "
                + "source (Config/Defaults.qml) and are hand-edited only"
            controlWidth: 240

            Text {
                anchors.right: parent.right
                anchors.verticalCenter: parent.verticalCenter
                width: parent.width
                horizontalAlignment: Text.AlignRight
                text: Paths.stateDir
                color: Theme.textMuted
                elide: Text.ElideLeft
                font { family: Theme.fontMono; pixelSize: 11 }
            }
        }
    }
}
