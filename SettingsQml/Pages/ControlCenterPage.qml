import QtQuick
import ".."
import "../../ConfigValues"

SettingsPage {
    title: "Control Center"
    icon: "󰕮"

    SettingGroup {
        title: "Grid"

        SettingSlider {
            label: "Width"
            value: Theme.controlWidth
            from: 300; to: 1200; step: 10; suffix: "px"
            store: Theme.data; key: "controlWidth"; defaults: Defaults.theme
        }
        SettingSlider {
            label: "Card height"
            hint: "Applies to toggles and sliders; the media card is worth two"
            value: Theme.controlCardHeight
            from: 24; to: 160; suffix: "px"
            store: Theme.data; key: "controlCardHeight"; defaults: Defaults.theme
        }
        SettingSlider {
            label: "Gap"
            value: Theme.controlGap
            from: 0; to: 32; suffix: "px"
            store: Theme.data; key: "controlGap"; defaults: Defaults.theme
        }
    }

    SettingGroup {
        title: "Media"

        SettingSlider {
            label: "Artwork blur"
            hint: "The album art behind the media card"
            value: Theme.widgetMediaBlur
            from: 0; to: 1; step: 0.05
            store: Theme.data; key: "widgetMediaBlur"; defaults: Defaults.theme
        }
    }

    SettingGroup {
        title: "OSD and notifications"

        SettingSlider {
            label: "OSD bar width"
            hint: "Pixels per 1% of volume or brightness"
            value: Theme.osdPxPerPct
            from: 0.5; to: 6; step: 0.5
            store: Theme.data; key: "osdPxPerPct"; defaults: Defaults.theme
        }
        SettingSlider {
            label: "History height"
            value: Theme.notifHistoryMaxHeight
            from: 60; to: 600; step: 10; suffix: "px"
            store: Theme.data; key: "notifHistoryMaxHeight"; defaults: Defaults.theme
        }
        SettingSlider {
            label: "Launcher width"
            value: Theme.launcherWidth
            from: 300; to: 1000; step: 10; suffix: "px"
            store: Theme.data; key: "launcherWidth"; defaults: Defaults.theme
        }
    }
}
