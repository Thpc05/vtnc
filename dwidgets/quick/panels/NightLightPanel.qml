import QtQuick
import qs.core
import qs.services
import qs.kit as K

// Night light (2026-10-16, the "hero" panel): the temperature on top (big, its state) with a slider
// under it, then the presets as one connected group. Changing it turns it on (Store.nightLight.temp,
// also in Settings → System → Night light).
Item {
    id: root

    // the look of the Dwidget that opened the panel (look.panel)
    property var look: null
    // its Qwidget (the hero toggles it)
    property QtObject qwidget: null

    readonly property PanelColors c: PanelColors {
        look: root.look
    }
    readonly property int temp: Store.nightLight.temp
    readonly property int low: 2500
    readonly property int high: 6500
    readonly property var presets: [3000, 3500, 4000, 4500, 5000, 5500]

    function set(k) {
        Store.nightLight.temp = Math.max(low, Math.min(high, Math.round(k / 100) * 100));
        if (!NightLightClient.active)
            NightLightClient.toggle();
    }

    PanelHero {
        id: hero
        width: parent.width
        look: root.look
        qwidget: root.qwidget
        active: NightLightClient.active
        symbol: "nightlight"
        title: root.temp + " K"
        subtitle: NightLightClient.active ? "Lower is warmer" : "Off"
        extraHeight: 16

        K.M3Slider {
            anchors.fill: parent
            vertical: false
            trackThickness: 6
            activeColor: NightLightClient.active ? root.c.accent : root.c.weak
            inactiveColor: root.c.off
            value: (root.temp - root.low) / (root.high - root.low)
            onMoved: v => root.set(root.low + v * (root.high - root.low))
        }
    }

    PanelSection {
        id: section
        anchors.top: hero.bottom
        anchors.topMargin: 8
        width: parent.width
        look: root.look
        text: "Presets"
    }

    // its whole height (the toggle Dwidget scrolls a panel taller than its rect)
    implicitHeight: hero.implicitHeight + 8 + section.implicitHeight + 2 + presetGroup.implicitHeight

    ActionGroup {
        id: presetGroup
        anchors.top: section.bottom
        anchors.topMargin: 2
        width: parent.width
        look: root.look
        perRow: 3
        rowHeight: 30
        actions: root.presets.map(k => ({
                    text: String(k),
                    primary: NightLightClient.active && root.temp === k,
                    run: () => root.set(k)
                }))
    }
}
