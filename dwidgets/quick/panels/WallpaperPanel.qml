import QtQuick
import Quickshell.Widgets
import qs.core
import qs.services
import qs.kit as K

// Wallpaper (2026-10-27, user: every toggle has a panel): the one now on top (its name) with Random and
// the Wallpaper app as one connected group, then the folder's wallpapers as thumbnails; a click puts one
// (the colours regenerate, services/Wallpapers.qml), the current one outlined.
Item {
    id: root

    // the look of the Dwidget that opened the panel (look.panel)
    property var look: null
    // its Qwidget (the hero toggles it)
    property QtObject qwidget: null

    readonly property PanelColors c: PanelColors {
        look: root.look
    }
    // thumbnails per row, about 88 px each, the cells splitting the whole width (a cell wider than its
    // share left a column out: a third of the panel empty, user)
    readonly property int perRow: Math.max(2, Math.floor((width + 6) / 94))
    readonly property real cellWidth: width / perRow
    readonly property real thumbWidth: Math.floor(cellWidth - 6)

    Component.onCompleted: if (Wallpapers.list.length === 0)
        Wallpapers.refresh()

    PanelHero {
        id: hero
        width: parent.width
        look: root.look
        qwidget: root.qwidget
        symbol: "wallpaper"
        title: Wallpapers.current !== "" ? Wallpapers.name(Wallpapers.current) : "No wallpaper"
        subtitle: Wallpapers.list.length === 1 ? "1 in the folder" : `${Wallpapers.list.length} in the folder`
        actions: [
            {
                text: "Random",
                icon: "shuffle",
                primary: true,
                run: () => Wallpapers.applyRandom()
            },
            {
                text: "Open",
                icon: "open_in_new",
                run: () => Launch.run("vtnc:wallpaper")
            }
        ]
    }

    PanelSection {
        id: section
        anchors.top: hero.bottom
        anchors.topMargin: 8
        width: parent.width
        look: root.look
        text: "Wallpapers"
    }

    GridView {
        anchors.top: section.bottom
        anchors.topMargin: 4
        anchors.bottom: parent.bottom
        width: parent.width
        clip: true
        boundsBehavior: Flickable.StopAtBounds
        cellWidth: root.cellWidth
        cellHeight: Math.round(root.thumbWidth * 0.625) + 6
        model: Wallpapers.list

        delegate: Item {
            id: cell
            required property string modelData
            readonly property bool isCurrent: modelData === Wallpapers.current

            width: root.thumbWidth
            height: Math.round(root.thumbWidth * 0.625)

            ClippingRectangle {
                anchors.fill: parent
                radius: K.Kit.rounding.small
                color: root.c.off

                Image {
                    anchors.fill: parent
                    // thumbsVersion: reload once the thumbnails are made
                    source: Wallpapers.thumbsVersion >= 0 ? Wallpapers.thumbFor(cell.modelData) : ""
                    fillMode: Image.PreserveAspectCrop
                    sourceSize.width: 192
                    asynchronous: true
                }
            }
            Rectangle {
                anchors.fill: parent
                visible: cell.isCurrent
                radius: K.Kit.rounding.small
                color: "transparent"
                border.width: 2
                border.color: root.c.accent
            }
            K.StateLayer {
                radius: K.Kit.rounding.small
                color: root.c.strong
                onClicked: Wallpapers.apply(cell.modelData)
            }
        }
    }
}
