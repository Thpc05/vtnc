import QtQuick
import ".."
import "../../Config"

SettingsPage {
    title: "Behavior"
    icon: "󰒓"

    SettingGroup {
        title: "Auto-hide"
        // The island hides on whichever monitor is fullscreen; the
        // pointer at the top of the screen brings it back

        SettingToggle {
            label: "Always hide"
            hint: "Not just in fullscreen: the island lives tucked away and "
                + "only the pointer at the top reveals it"
            checked: Config.alwaysAutoHide
            store: Config.data; key: "alwaysAutoHide"; defaults: Defaults.config
        }
        SettingSlider {
            label: "Reveal strip"
            hint: "Height of the band at the top that reacts to the pointer"
            value: Config.autoHideRevealZone
            from: 1; to: 40; suffix: "px"
            store: Config.data; key: "autoHideRevealZone"; defaults: Defaults.config
        }
        SettingChoice {
            label: "Animation"
            options: ["slide", "fade", "retract"]
            value: Config.autoHideAnim
            store: Config.data; key: "autoHideAnim"; defaults: Defaults.config
        }
    }

    SettingGroup {
        title: "What forces the island visible"

        SettingToggle {
            label: "App open"
            hint: "Turning this off means opening the launcher in fullscreen "
                + "types into an invisible island — leave it on unless you "
                + "know what you want"
            checked: Config.autoHideShowOnApp
            store: Config.data; key: "autoHideShowOnApp"; defaults: Defaults.config
        }
        SettingToggle {
            label: "Control Center open"
            checked: Config.autoHideShowOnDashboard
            store: Config.data; key: "autoHideShowOnDashboard"; defaults: Defaults.config
        }
        SettingToggle {
            label: "Volume or brightness"
            checked: Config.autoHideShowOnOsd
            store: Config.data; key: "autoHideShowOnOsd"; defaults: Defaults.config
        }
        SettingToggle {
            label: "Notification arriving"
            checked: Config.autoHideShowOnNotif
            store: Config.data; key: "autoHideShowOnNotif"; defaults: Defaults.config
        }
    }

    SettingGroup {
        title: "OSD and notifications"

        SettingSlider {
            label: "OSD hides after"
            value: Config.osdTimeout
            from: 500; to: 8000; step: 250; suffix: "ms"
            store: Config.data; key: "osdTimeout"; defaults: Defaults.config
        }
        SettingToggle {
            label: "Show percentage"
            hint: "The number next to the volume and brightness bar"
            checked: Config.osdShowPercent
            store: Config.data; key: "osdShowPercent"; defaults: Defaults.config
        }
        SettingSlider {
            label: "Notification hides after"
            value: Config.notifyTimeout
            from: 1000; to: 15000; step: 500; suffix: "ms"
            store: Config.data; key: "notifyTimeout"; defaults: Defaults.config
        }
        SettingSlider {
            label: "History keeps"
            value: Config.maxNotifHistory
            from: 1; to: 100; suffix: "items"
            store: Config.data; key: "maxNotifHistory"; defaults: Defaults.config
        }
    }

    SettingGroup {
        title: "Misc"

        SettingSlider {
            label: "Launcher results"
            value: Config.maxLauncherResults
            from: 1; to: 20; suffix: "items"
            store: Config.data; key: "maxLauncherResults"; defaults: Defaults.config
        }
        SettingSlider {
            label: "Battery warning"
            hint: "Below this the battery shows up next to the clock. "
                + "100 = always visible, handy for testing"
            value: Config.batteryWarnLevel
            from: 0; to: 100; suffix: "%"
            store: Config.data; key: "batteryWarnLevel"; defaults: Defaults.config
        }
        SettingToggle {
            label: "Caption in Tools"
            hint: "Name of the selected item under the icons"
            checked: Config.showTips
            store: Config.data; key: "showTips"; defaults: Defaults.config
        }
    }
}
