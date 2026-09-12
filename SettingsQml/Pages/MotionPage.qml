import QtQuick
import ".."
import "../../ConfigValues"

SettingsPage {
    title: "Motion"
    icon: "󰑮"

    SettingGroup {
        title: "Durations"

        SettingSlider {
            label: "Instant"
            hint: "Hover tint, border lighting up"
            value: Motion.instant
            from: 0; to: 400; step: 10; suffix: "ms"
            store: Motion.data; key: "instant"; defaults: Defaults.motion
        }
        SettingSlider {
            label: "Quick"
            hint: "Content fades and item swaps"
            value: Motion.quick
            from: 0; to: 400; step: 10; suffix: "ms"
            store: Motion.data; key: "quick"; defaults: Defaults.motion
        }
        SettingSlider {
            label: "Standard"
            hint: "Expansions: wide bar, reveal opening, card growing"
            value: Motion.standard
            from: 80; to: 800; step: 10; suffix: "ms"
            store: Motion.data; key: "standard"; defaults: Defaults.motion
        }
        SettingSlider {
            label: "Slider tracking"
            hint: "Volume and brightness while the button is held"
            value: Motion.track
            from: 0; to: 400; step: 10; suffix: "ms"
            store: Motion.data; key: "track"; defaults: Defaults.motion
        }
    }

    SettingGroup {
        title: "Settle"

        SettingSlider {
            label: "Overshoot"
            hint: "NOT the fraction it passes the target by: 0.7→1.8% · "
                + "1.0→3.7% (Apple's range) · 1.2→5.3% · 1.7→10%. Above "
                + "~1.3 the island visibly pinches when the control center closes"
            value: Motion.overshoot
            from: 0; to: 2; step: 0.1
            store: Motion.data; key: "overshoot"; defaults: Defaults.motion
        }
    }

    SettingGroup {
        title: "Hover patience"

        SettingSlider {
            label: "Delay before opening"
            hint: "How long the pointer must rest before something opens. "
                + "Below 200 filters nothing; above 500 feels frozen"
            value: Motion.hoverDelay
            from: 0; to: 800; step: 25; suffix: "ms"
            store: Motion.data; key: "hoverDelay"; defaults: Defaults.motion
        }
        SettingSlider {
            label: "Grace before closing"
            hint: "How long what is open survives after the pointer leaves"
            value: Motion.hoverGrace
            from: 0; to: 1000; step: 25; suffix: "ms"
            store: Motion.data; key: "hoverGrace"; defaults: Defaults.motion
        }
    }
}
