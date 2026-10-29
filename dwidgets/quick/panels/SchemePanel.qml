import QtQuick
import qs.core
import qs.services
import qs.kit as K

// Color scheme (2026-10-27, user: every toggle has a panel): the scheme now on top with the mode (Dark /
// Light) as one connected group, then every scheme matugen can build; a click picks one (the colours
// regenerate, Store.theme.scheme; also in Settings → Appearance).
Item {
    id: root

    // the look of the Dwidget that opened the panel (look.panel)
    property var look: null
    // its Qwidget (the hero toggles it)
    property QtObject qwidget: null

    readonly property PanelColors c: PanelColors {
        look: root.look
    }

    function title(scheme: string): string {
        return (scheme || "").replace("scheme-", "").split("-").map(w => w.charAt(0).toUpperCase() + w.slice(1)).join(" ");
    }

    PanelHero {
        id: hero
        width: parent.width
        look: root.look
        qwidget: root.qwidget
        symbol: "palette"
        title: root.title(Store.theme.scheme)
        subtitle: "From the wallpaper"
        actions: [
            {
                text: "Dark",
                icon: "dark_mode",
                primary: !Store.theme.light,
                run: () => Store.theme.light = false
            },
            {
                text: "Light",
                icon: "light_mode",
                primary: Store.theme.light,
                run: () => Store.theme.light = true
            }
        ]
    }

    PanelSection {
        id: section
        anchors.top: hero.bottom
        anchors.topMargin: 8
        width: parent.width
        look: root.look
        text: "Schemes"
    }

    Flickable {
        anchors.top: section.bottom
        anchors.bottom: parent.bottom
        width: parent.width
        contentWidth: width
        contentHeight: list.implicitHeight
        clip: true
        boundsBehavior: Flickable.StopAtBounds
        interactive: contentHeight > height

        Column {
            id: list
            width: parent.width

            Repeater {
                model: Wallpapers.schemes

                PanelRow {
                    required property string modelData
                    required property int index

                    width: parent.width
                    look: root.look
                    current: modelData === Store.theme.scheme
                    icon: current ? "check" : "palette"
                    title: root.title(modelData)
                    onClicked: Store.theme.scheme = modelData
                }
            }
        }
    }
}
