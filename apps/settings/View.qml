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

// Settings: a tree of pages (some have sub-pages: Island, Dashboard) in the sidebar; every change
// is written to its file in ~/.config/vtnc right away (live preview). Island, Dashboard and
// Appearance belong to the active preset (services/Presets.qml): a changed one shows Revert.
// Keys: ↑/↓ previous/next page (sub-pages included), Ctrl+Tab / Ctrl+Shift+Tab next/previous
// top-level page.
FocusScope {
    id: root

    // { id, title, icon, component } or { id, title, icon, children: [{ id, title, component }] }
    readonly property var tree: [
        {
            id: "appearance",
            title: "Appearance",
            icon: Icons.paintBrush,
            children: [
                {
                    id: "general",
                    title: "General",
                    component: appearanceGeneral
                },
                {
                    id: "colors",
                    title: "Colors",
                    component: appearanceColors
                },
                {
                    id: "popups",
                    title: "Popups",
                    component: appearancePopups
                }
            ]
        },
        {
            id: "island",
            title: "Island",
            icon: Icons.island,
            children: [
                {
                    id: "general",
                    title: "General",
                    component: islandGeneral
                },
                {
                    id: "layout",
                    title: "Layout",
                    component: islandWidgets
                },
                {
                    id: "anchors",
                    title: "Anchors",
                    component: islandAnchors
                },
                {
                    id: "autohide",
                    title: "Auto hide",
                    component: islandAutoHide
                }
            ]
        },
        {
            id: "dashboard",
            title: "Dashboard",
            icon: Icons.squaresFour,
            children: [
                {
                    id: "general",
                    title: "General",
                    component: dashboardGeneral
                },
                {
                    id: "layout",
                    title: "Layout",
                    component: dashboardLayout
                }
            ]
        },
        {
            id: "apps",
            title: "Apps",
            icon: Icons.apps,
            children: [
                {
                    id: "notifications",
                    title: "Notifications",
                    component: appsNotifications
                },
                {
                    id: "clipboard",
                    title: "Clipboard",
                    component: appsClipboard
                },
                {
                    id: "notes",
                    title: "Notes",
                    component: appsNotes
                },
                {
                    id: "session",
                    title: "Session",
                    component: appsSession
                },
                {
                    id: "tools",
                    title: "Tools",
                    component: appsTools
                },
                {
                    id: "wallpaper",
                    title: "Wallpaper",
                    component: appsWallpaper
                },
                {
                    id: "dino",
                    title: "Dino run",
                    component: appsDino
                }
            ]
        },
        {
            id: "presets",
            title: "Presets",
            icon: Icons.stack,
            component: presetsPage
        },
        {
            id: "system",
            title: "System",
            icon: Icons.slidersHorizontal,
            component: systemPage
        },
        {
            id: "about",
            title: "About",
            icon: Icons.info,
            children: [
                {
                    id: "general",
                    title: "General",
                    component: aboutPage
                },
                {
                    id: "components",
                    title: "Examples",
                    component: componentGallery
                }
            ]
        }
    ]

    // every selectable page in order: { path, title, parentTitle, component }
    readonly property var leaves: {
        const out = [];
        for (const n of tree) {
            if (n.children?.length) {
                for (const c of n.children)
                    out.push({
                        path: n.id + "/" + c.id,
                        title: c.title,
                        parentTitle: n.title,
                        component: c.component
                    });
            } else {
                out.push({
                    path: n.id,
                    title: n.title,
                    parentTitle: "",
                    component: n.component
                });
            }
        }
        return out;
    }

    function leafIndex(path: string): int {
        return leaves.findIndex(l => l.path === path);
    }

    // a parent path resolves to its first sub-page; unknown paths to the first page
    function resolve(path: string): string {
        // Island → Iwidgets became Island → Layout (2026-10-09)
        if (path === "island/widgets")
            path = "island/layout";
        // Island → OSD became Appearance → OSD (2026-10-15); OSD and Notifications became Popups
        // (2026-10-17)
        if (path === "island/osd" || path === "appearance/osd" || path === "appearance/notifications")
            path = "appearance/popups";
        if (leafIndex(path) >= 0)
            return path;
        const n = tree.find(t => t.id === path);
        if (n?.children?.length)
            return n.id + "/" + n.children[0].id;
        return leaves[0].path;
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

    // args.page (IPC `settings page <name>`): a path ("island/autohide"), a page id or a title,
    // case-insensitive
    function opened(args) {
        if (args?.page) {
            const q = String(args.page).toLowerCase().replace(/\s+/g, "");
            const hit = leaves.find(l => l.path === q || l.title.toLowerCase().replace(/\s+/g, "") === q) ?? tree.find(t => t.id === q || t.title.toLowerCase() === q);
            if (hit)
                select(hit.path ?? hit.id);
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
