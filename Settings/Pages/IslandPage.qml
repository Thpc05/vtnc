import QtQuick
import ".."
import "../../Config"
import "../../Island"

SettingsPage {
    title: "Island"
    icon: "󰟾"

    SettingGroup {
        title: "Size"

        SettingSlider {
            label: "Width (normal)"
            value: IslandTheme.width
            from: 60; to: 400; suffix: "px"
            store: IslandTheme.data; key: "width"; defaults: Defaults.island
        }
        SettingSlider {
            label: "Height"
            hint: "Also the useful ceiling for the island radius (half of it)"
            value: IslandTheme.height
            from: 20; to: 80; suffix: "px"
            store: IslandTheme.data; key: "height"; defaults: Defaults.island
        }
        SettingSlider {
            label: "Width (wide)"
            hint: "Base of the wide mode; workspaces and cluster add to it"
            value: IslandTheme.wideWidth
            from: 60; to: 500; suffix: "px"
            store: IslandTheme.data; key: "wideWidth"; defaults: Defaults.island
        }
        SettingSlider {
            label: "Height (wide)"
            value: IslandTheme.wideHeight
            from: 20; to: 80; suffix: "px"
            store: IslandTheme.data; key: "wideHeight"; defaults: Defaults.island
        }
        SettingSlider {
            label: "Distance from top"
            value: IslandTheme.marginTop
            from: 0; to: 40; suffix: "px"
            store: IslandTheme.data; key: "marginTop"; defaults: Defaults.island
        }
    }

    SettingGroup {
        title: "Morph choreography"

        SettingSlider {
            label: "Content leaves"
            value: IslandTheme.faceFadeOut
            from: 0; to: 400; step: 10; suffix: "ms"
            store: IslandTheme.data; key: "faceFadeOut"; defaults: Defaults.island
        }
        SettingSlider {
            label: "Island morphs"
            value: IslandTheme.morphDuration
            from: 80; to: 800; step: 10; suffix: "ms"
            store: IslandTheme.data; key: "morphDuration"; defaults: Defaults.island
        }
        SettingSlider {
            label: "Wait before content"
            value: IslandTheme.faceFadeInDelay
            from: 0; to: 600; step: 10; suffix: "ms"
            store: IslandTheme.data; key: "faceFadeInDelay"; defaults: Defaults.island
        }
        SettingSlider {
            label: "Content enters"
            value: IslandTheme.faceFadeIn
            from: 0; to: 400; step: 10; suffix: "ms"
            store: IslandTheme.data; key: "faceFadeIn"; defaults: Defaults.island
        }

        // Easy to break with the four sliders above, and the symptom
        // (size jumping at the end of the morph) does not name its cause
        SettingRow {
            label: "Invariant"
            hint: "morph ≤ wait + enter. Broken, the island's size JUMPS at "
                + "the end of the morph, because its Behaviors already "
                + "switched off"
            controlWidth: 130

            readonly property bool ok:
                IslandTheme.morphDuration
                <= IslandTheme.faceFadeInDelay + IslandTheme.faceFadeIn

            Text {
                anchors.right: parent.right
                anchors.verticalCenter: parent.verticalCenter
                text: parent.ok
                    ? "ok (" + (IslandTheme.faceFadeInDelay
                        + IslandTheme.faceFadeIn - IslandTheme.morphDuration)
                        + "ms spare)"
                    : "BROKEN"
                color: parent.ok ? Theme.textMuted : Theme.danger
                font { family: Theme.fontMono; pixelSize: 12 }
            }
        }
    }

    SettingGroup {
        title: "Content scale"

        SettingSlider {
            label: "Leaving shrinks to"
            value: IslandTheme.faceScaleOut
            from: 0.5; to: 1; step: 0.01
            store: IslandTheme.data; key: "faceScaleOut"; defaults: Defaults.island
        }
        SettingSlider {
            label: "Entering starts at"
            hint: "Below 1 the content looks like it is INSIDE the island "
                + "that moves, instead of blinking on top of it"
            value: IslandTheme.faceScaleIn
            from: 0.5; to: 1; step: 0.01
            store: IslandTheme.data; key: "faceScaleIn"; defaults: Defaults.island
        }
    }
}
