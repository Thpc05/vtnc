import QtQuick
import qs.base.theme
import "tree.js" as Tree
import qs.apps.common

VtncApp {
    appId: "settings"
    title: "Settings"
    icon: Icons.gear
    // every page's path (IPC `settings pages`)
    readonly property var pages: Tree.leaves().map(l => l.path)
    view: Component {
        View {}
    }
}
