import QtQuick
import Quickshell.Services.UPower
import qs.kit as K

// Power profile (2026-10-16, the "hero" panel): the current profile on top (its icon, name and what it
// does), the others under "Profiles"; a click picks one.
Item {
    id: root

    // the look of the Dwidget that opened the panel (look.panel)
    property var look: null
    // its Qwidget (the hero toggles it)
    property QtObject qwidget: null

    readonly property var profiles: [
        {
            value: PowerProfile.PowerSaver,
            title: "Power saver",
            detail: "Longer battery, slower",
            icon: "eco"
        },
        {
            value: PowerProfile.Balanced,
            title: "Balanced",
            detail: "The default",
            icon: "balance"
        },
        {
            value: PowerProfile.Performance,
            title: "Performance",
            detail: PowerProfiles.hasPerformanceProfile ? "Faster, more power" : "Not supported here",
            icon: "bolt"
        }
    ]
    readonly property var current: profiles.find(p => p.value === PowerProfiles.profile) ?? profiles[1]

    PanelHero {
        id: hero
        width: parent.width
        look: root.look
        qwidget: root.qwidget
        symbol: root.current.icon
        title: root.current.title
        subtitle: root.current.detail
    }

    PanelSection {
        id: section
        anchors.top: hero.bottom
        anchors.topMargin: 8
        width: parent.width
        look: root.look
        text: "Profiles"
    }

    // its whole height (the toggle Dwidget scrolls a panel taller than its rect)
    implicitHeight: hero.implicitHeight + 8 + section.implicitHeight + profileList.implicitHeight

    Column {
        id: profileList
        anchors.top: section.bottom
        width: parent.width

        Repeater {
            model: root.profiles.filter(p => p !== root.current)

            PanelRow {
                required property var modelData
                required property int index

                width: parent.width
                look: root.look
                position: index
                usable: modelData.value !== PowerProfile.Performance || PowerProfiles.hasPerformanceProfile
                icon: modelData.icon
                title: modelData.title
                onClicked: PowerProfiles.profile = modelData.value
            }
        }
    }
}
