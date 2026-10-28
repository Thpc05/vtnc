import QtQuick
import Quickshell
import Quickshell.Hyprland
import qs.theme
import qs.components
import qs.kit as K

// The dock's right-click menu, under the app's icon (a popup, as the media's player picker): pin / unpin
// (only an app with a desktop entry: it has to open again), a new window, close its windows.
PopupWindow {
    id: root

    // the dock's icon it was opened on (iwidgets/dock/Widget.qml)
    property Item app: null

    signal togglePin(string key)
    signal launch(var entry)

    function open(item) {
        app = item;
        visible = true;
    }

    readonly property var rows: {
        if (!app)
            return [];
        const out = [];
        if (app.entry)
            out.push({
                id: "pin",
                icon: app.pinned ? "keep_off" : "keep",
                text: app.pinned ? "Unpin" : "Pin to dock"
            });
        if (app.entry)
            out.push({
                id: "new",
                icon: "add",
                text: "New window"
            });
        if (app.windows.length > 0)
            out.push({
                id: "close",
                icon: "close",
                text: app.windows.length > 1 ? `Close ${app.windows.length} windows` : "Close window"
            });
        return out;
    }

    function pick(id) {
        visible = false;
        if (id === "pin")
            togglePin(app.key);
        else if (id === "new")
            launch(app.entry);
        else if (id === "close")
            for (const w of app.windows)
                w.wayland?.close();
    }

    anchor.item: app
    anchor.rect.x: (app?.width ?? 0) / 2 - width / 2
    anchor.rect.y: (app?.height ?? 0) + 10
    implicitWidth: 180
    implicitHeight: list.implicitHeight + 16
    color: "transparent"
    visible: false

    HyprlandFocusGrab {
        active: root.visible
        windows: [root]
        onCleared: root.visible = false
    }

    Rectangle {
        anchors.fill: parent
        radius: K.Kit.rounding.large
        color: K.Kit.expressive.container
        border.width: 1
        border.color: Colors.outlineVariant

        Column {
            id: list
            anchors.fill: parent
            anchors.margins: 8
            spacing: 2

            // the app's name
            K.StyledText {
                x: 10
                width: parent.width - 20
                height: 26
                verticalAlignment: Text.AlignVCenter
                text: root.app?.entry?.name ?? root.app?.key ?? ""
                font: K.Kit.makeFont(11, Font.Bold)
                color: Colors.overSurfaceVariant
                elide: Text.ElideRight
            }

            Repeater {
                model: root.rows

                Item {
                    id: row
                    required property var modelData
                    width: list.width
                    height: 32

                    K.StateLayer {
                        radius: K.Kit.rounding.small
                        color: Colors.overSurface
                        onClicked: root.pick(row.modelData.id)
                    }
                    K.MaterialIcon {
                        id: rowIcon
                        x: 10
                        anchors.verticalCenter: parent.verticalCenter
                        text: row.modelData.icon
                        size: 18
                        color: row.modelData.id === "close" ? Colors.error : Colors.overSurface
                    }
                    K.StyledText {
                        anchors.left: rowIcon.right
                        anchors.leftMargin: 10
                        anchors.right: parent.right
                        anchors.rightMargin: 10
                        anchors.verticalCenter: parent.verticalCenter
                        text: row.modelData.text
                        font: K.Kit.makeFont(12, Font.Medium)
                        color: row.modelData.id === "close" ? Colors.error : Colors.overSurface
                        elide: Text.ElideRight
                    }
                }
            }
        }
    }
}
