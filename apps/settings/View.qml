import QtQuick
import qs.core
import qs.components
import qs.theme
import qs.services
import qs.kit as K
import "controls"
import "pages"
import "pages/island" as IslandPages
import "pages/dashboard" as DashboardPages
import "pages/appearance" as AppearancePages
import "pages/apps" as AppsPages
import "tree.js" as Tree

// Settings: a tree of pages (some have sub-pages: Island, Dashboard) in the sidebar; every change
// is written to its file in ~/.config/vtnc right away (live preview). Island, Dashboard and
// Appearance belong to the active preset (services/Presets.qml): a changed one shows Revert.
// Keys: ↑/↓ previous/next page (sub-pages included), Ctrl+Tab / Ctrl+Shift+Tab next/previous
// top-level page.
FocusScope {
    id: root

    // the page tree (tree.js), with each page's component and icon: { id, title, icon, component } or
    // { id, title, icon, children: [{ id, title, component }] }
    readonly property var components: ({
            "appearance/general": appearanceGeneral,
            "appearance/colors": appearanceColors,
            "appearance/popups": appearancePopups,
            "island/general": islandGeneral,
            "island/layout": islandWidgets,
            "island/anchors": islandAnchors,
            "island/autohide": islandAutoHide,
            "dashboard/general": dashboardGeneral,
            "dashboard/layout": dashboardLayout,
            "apps/notifications": appsNotifications,
            "apps/clipboard": appsClipboard,
            "apps/notes": appsNotes,
            "apps/session": appsSession,
            "apps/tools": appsTools,
            "apps/wallpaper": appsWallpaper,
            "apps/dino": appsDino,
            "presets": presetsPage,
            "system": systemPage,
            "about/general": aboutPage,
            "about/components": componentGallery
        })
    readonly property var tree: Tree.TREE.map(n => Object.assign({}, n, {
                icon: Icons[n.icon],
                component: components[n.id] ?? null,
                children: n.children?.map(c => Object.assign({}, c, {
                        component: components[n.id + "/" + c.id]
                    }))
            }))

    // every selectable page in order: { path, title, parentTitle, component }
    readonly property var leaves: Tree.leaves().map(l => Object.assign({}, l, {
                component: components[l.path]
            }))

    function leafIndex(path: string): int {
        return leaves.findIndex(l => l.path === path);
    }

    function resolve(path: string): string {
        return Tree.resolve(path);
    }

    property string path: resolve(Store.appGet("settings", "path", "island/general"))
    readonly property var current: leaves[Math.max(0, leafIndex(path))]

    function select(p: string) {
        path = resolve(p);
        Store.appSet("settings", "path", path);
    }
    function step(delta: int) {
        const n = leaves.length;
        select(leaves[(leafIndex(path) + delta + n) % n].path);
    }
    function stepTop(delta: int) {
        const i = tree.findIndex(t => t.id === path.split("/")[0]);
        select(tree[(i + delta + tree.length) % tree.length].id);
    }

    implicitWidth: 1120
    implicitHeight: 620

    // args.page (IPC `settings page <name>`): a path ("island/autohide"), a sub-page's title or a
    // top-level id or title, case and spaces ignored (Tree.find)
    function opened(args) {
        if (args?.page) {
            const hit = Tree.find(args.page);
            if (hit !== "")
                select(hit);
        }
        sidebar.reshuffle();
        root.forceActiveFocus();
    }

    Keys.onPressed: e => {
        const ctrl = e.modifiers & Qt.ControlModifier;
        if (e.key === Qt.Key_Tab && ctrl)
            stepTop(1);
        else if (e.key === Qt.Key_Backtab && ctrl)
            stepTop(-1);
        else if (e.key === Qt.Key_Down)
            step(1);
        else if (e.key === Qt.Key_Up)
            step(-1);
        else
            return;
        e.accepted = true;
    }

    Component {
        id: islandGeneral
        IslandPages.General {}
    }
    Component {
        id: islandWidgets
        IslandPages.Widgets {}
    }
    Component {
        id: islandAnchors
        IslandPages.Anchors {}
    }
    Component {
        id: islandAutoHide
        IslandPages.AutoHide {}
    }
    Component {
        id: dashboardGeneral
        DashboardPages.General {}
    }
    Component {
        id: dashboardLayout
        DashboardPages.Layout {}
    }
    Component {
        id: appearanceGeneral
        AppearancePages.General {}
    }
    Component {
        id: appearanceColors
        AppearancePages.ColorMapping {}
    }
    Component {
        id: appearancePopups
        AppearancePages.Popups {}
    }
    Component {
        id: appsNotifications
        AppsPages.Notifications {}
    }
    Component {
        id: appsClipboard
        AppsPages.Clipboard {}
    }
    Component {
        id: appsNotes
        AppsPages.Notes {}
    }
    Component {
        id: appsDino
        AppsPages.Dino {}
    }
    Component {
        id: appsSession
        AppsPages.Session {}
    }
    Component {
        id: appsTools
        AppsPages.Tools {}
    }
    Component {
        id: appsWallpaper
        AppsPages.Wallpaper {}
    }
    Component {
        id: presetsPage
        PresetsSettings {}
    }
    Component {
        id: systemPage
        SystemSettings {}
    }
    Component {
        id: aboutPage
        AboutSettings {}
    }
    Component {
        id: componentGallery
        ComponentGallery {}
    }

    Sidebar {
        id: sidebar
        height: parent.height
        tree: root.tree
        path: root.path
        onPicked: p => root.select(p)
    }

    // page --------------------------------------------------------------------
    Item {
        anchors.left: sidebar.right
        anchors.leftMargin: Tokens.spacing.l
        anchors.right: parent.right
        anchors.top: parent.top
        anchors.bottom: parent.bottom

        // "Island › Auto hide" for sub-pages
        Row {
            id: pageTitle
            height: 36
            leftPadding: Tokens.spacing.s
            spacing: Tokens.spacing.s

            StyledText {
                anchors.verticalCenter: parent.verticalCenter
                visible: root.current.parentTitle !== ""
                text: root.current.parentTitle
                font.pixelSize: Tokens.font.title
                font.weight: Font.Bold
                color: K.Kit.appLook.panel.weak
            }
            Icon {
                anchors.verticalCenter: parent.verticalCenter
                visible: root.current.parentTitle !== ""
                icon: Icons.caretRight
                size: 16
                color: K.Kit.appLook.panel.weak
            }
            StyledText {
                anchors.verticalCenter: parent.verticalCenter
                text: root.current.title
                font.pixelSize: Tokens.font.title
                font.weight: Font.Bold
                color: K.Kit.appLook.panel.strong
            }
        }

        // the page's part of the active preset was changed: Revert (saving is on the Presets page)
        Row {
            readonly property string part: root.path.split("/")[0]

            anchors.right: parent.right
            anchors.rightMargin: Tokens.spacing.m
            anchors.verticalCenter: pageTitle.verticalCenter
            spacing: Tokens.spacing.s
            visible: Presets.modifiedParts.includes(part)

            StyledText {
                anchors.verticalCenter: parent.verticalCenter
                text: "Changed from " + Presets.active
                font.pixelSize: Tokens.font.small
                color: K.Kit.appLook.panel.weak
            }
            SmallButton {
                anchors.verticalCenter: parent.verticalCenter
                text: "Revert"
                onClicked: Presets.revert(parent.part)
            }
        }

        Loader {
            id: pageLoader
            anchors.top: pageTitle.bottom
            anchors.topMargin: Tokens.spacing.s
            anchors.left: parent.left
            anchors.right: parent.right
            anchors.bottom: parent.bottom
            sourceComponent: root.current.component

            // fade + small slide when switching pages
            onLoaded: {
                item.opacity = 0;
                pageIn.restart();
            }
            ParallelAnimation {
                id: pageIn
                K.Anim {
                    target: pageLoader.item
                    property: "opacity"
                    from: 0
                    to: 1
                    type: K.Anim.DefaultEffects
                }
                K.Anim {
                    target: pageLoader
                    property: "anchors.topMargin"
                    from: Tokens.spacing.s + 12
                    to: Tokens.spacing.s
                    type: K.Anim.DefaultSpatial
                }
            }
        }
    }
}
