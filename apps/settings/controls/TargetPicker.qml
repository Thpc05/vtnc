import QtQuick
import Quickshell
import Quickshell.Widgets
import qs.core
import qs.services
import qs.components
import qs.theme
import qs.kit as K

// Picks a launch target (core/launch.js), reusable wherever something "opens an app" (the App Qwidget
// today; dashboard tabs and others later): a field showing the current one (icon + name); clicking it
// opens a searchable list right below (inline, like FontPicker): vtnc's own apps first, then the
// desktop applications. ↑/↓ move, Enter picks, Escape closes.
Column {
    id: root

    property string value: ""
    property bool open: false

    signal edited(string value)

    readonly property var current: Launch.describe(value)
    readonly property var matches: {
        const q = search.text.trim().toLowerCase();
        const out = [];
        for (const id in Launch.vtncApps) {
            const a = Launch.vtncApps[id];
            if (q === "" || a.title.toLowerCase().includes(q) || id.includes(q))
                out.push({
                    target: Launch.format("vtnc", id, ""),
                    title: a.title,
                    note: "vtnc",
                    symbol: Icons[a.icon] ?? "apps",
                    image: ""
                });
        }
        for (const e of Apps.query(q))
            out.push({
                target: Launch.format("desktop", e.id, ""),
                title: e.name,
                note: "",
                symbol: "apps",
                image: Quickshell.iconPath(e.icon || e.id, true)
            });
        return out;
    }

    function pick(target: string) {
        open = false;
        if (target !== value)
            edited(target);
    }

    width: 240
    spacing: 4

    onOpenChanged: {
        if (open) {
            search.text = "";
            search.forceActiveFocus();
            list.currentIndex = Math.max(0, matches.findIndex(m => m.target === value));
            list.positionViewAtIndex(list.currentIndex, ListView.Center);
        }
    }

    component Mark: Item {
        property string symbol
        property string image
        width: 18
        height: 18
        IconImage {
            anchors.fill: parent
            visible: parent.image !== ""
            source: parent.image
            asynchronous: true
        }
        K.MaterialIcon {
            anchors.centerIn: parent
            visible: parent.image === ""
            text: parent.symbol
            size: 16
            color: Colors.primary
        }
    }

    // field
    Rectangle {
        width: root.width
        height: 30
        radius: height / 2
        color: K.Kit.expressive.off
        border.width: root.open ? 2 : 0
        border.color: Colors.primary

        Mark {
            id: fieldMark
            anchors.left: parent.left
            anchors.leftMargin: Tokens.spacing.s
            anchors.verticalCenter: parent.verticalCenter
            symbol: root.current.symbol
            image: root.current.image
        }
        StyledText {
            anchors.left: fieldMark.right
            anchors.leftMargin: Tokens.spacing.s
            anchors.right: caret.left
            anchors.rightMargin: Tokens.spacing.s
            anchors.verticalCenter: parent.verticalCenter
            elide: Text.ElideRight
            text: root.current.title
            font.pixelSize: Tokens.font.small
            color: root.value === "" ? Colors.overSurfaceVariant : Colors.overBackground
        }
        Icon {
            id: caret
            anchors.right: parent.right
            anchors.rightMargin: Tokens.spacing.s
            anchors.verticalCenter: parent.verticalCenter
            icon: Icons.caretDown
            size: 14
            color: Colors.outline
            rotation: root.open ? 180 : 0
            Behavior on rotation {
                NumberAnimation {
                    duration: Tokens.anim.fast
                    easing.type: Easing.OutQuart
                }
            }
        }
        MouseArea {
            anchors.fill: parent
            cursorShape: Qt.PointingHandCursor
            onClicked: root.open = !root.open
        }
    }

    // list
    Rectangle {
        width: root.width
        height: root.open ? 280 : 0
        visible: height > 0
        opacity: root.open ? 1 : 0
        radius: K.Kit.rounding.large
        color: K.Kit.expressive.off
        clip: true
        Behavior on height {
            K.Anim {}
        }
        Behavior on opacity {
            NumberAnimation {
                duration: Tokens.anim.fast
                easing.type: Tokens.anim.fadeEasing
            }
        }

        // search
        Rectangle {
            id: searchBox
            x: 4
            y: 4
            width: parent.width - 8
            height: 28
            radius: height / 2
            color: K.Kit.expressive.high

            Icon {
                id: searchIcon
                anchors.left: parent.left
                anchors.leftMargin: Tokens.spacing.s
                anchors.verticalCenter: parent.verticalCenter
                icon: Icons.magnifyingGlass
                size: 13
                color: Colors.outline
            }
            TextInput {
                id: search
                anchors.left: searchIcon.right
                anchors.leftMargin: Tokens.spacing.s
                anchors.right: parent.right
                anchors.rightMargin: Tokens.spacing.s
                anchors.verticalCenter: parent.verticalCenter
                clip: true
                color: Colors.overBackground
                selectionColor: Colors.primary
                selectedTextColor: Colors.overPrimary
                font.family: Tokens.font.family
                font.pixelSize: Tokens.font.small
                onTextChanged: list.currentIndex = 0
                // consumed here: the settings view uses ↑/↓ to change pages
                Keys.onUpPressed: list.currentIndex = Math.max(0, list.currentIndex - 1)
                Keys.onDownPressed: list.currentIndex = Math.min(root.matches.length - 1, list.currentIndex + 1)
                Keys.onReturnPressed: if (root.matches.length > 0) root.pick(root.matches[list.currentIndex].target)
                Keys.onEnterPressed: if (root.matches.length > 0) root.pick(root.matches[list.currentIndex].target)
                Keys.onEscapePressed: root.open = false

                StyledText {
                    anchors.verticalCenter: parent.verticalCenter
                    visible: search.text === ""
                    text: "Search apps"
                    font.pixelSize: Tokens.font.small
                    color: Colors.outline
                }
            }
        }

        ListView {
            id: list
            x: 4
            anchors.top: searchBox.bottom
            anchors.topMargin: 4
            anchors.bottom: parent.bottom
            anchors.bottomMargin: 4
            width: parent.width - 8
            clip: true
            boundsBehavior: Flickable.StopAtBounds
            model: root.matches
            highlightFollowsCurrentItem: false
            onCurrentIndexChanged: positionViewAtIndex(currentIndex, ListView.Contain)

            delegate: Rectangle {
                id: row
                required property var modelData
                required property int index
                readonly property bool isCurrent: modelData.target === root.value
                readonly property bool isKey: index === list.currentIndex

                width: list.width
                height: 30
                radius: height / 2
                color: isCurrent ? Colors.primary : (rowMouse.containsMouse || isKey ? K.Kit.expressive.high : "transparent")

                Mark {
                    id: rowMark
                    anchors.left: parent.left
                    anchors.leftMargin: Tokens.spacing.s
                    anchors.verticalCenter: parent.verticalCenter
                    symbol: row.modelData.symbol
                    image: row.modelData.image
                }
                StyledText {
                    anchors.left: rowMark.right
                    anchors.leftMargin: Tokens.spacing.s
                    anchors.right: note.left
                    anchors.rightMargin: Tokens.spacing.s
                    anchors.verticalCenter: parent.verticalCenter
                    elide: Text.ElideRight
                    text: row.modelData.title
                    font.pixelSize: Tokens.font.small
                    color: row.isCurrent ? Colors.overPrimary : Colors.overSurface
                }
                StyledText {
                    id: note
                    anchors.right: parent.right
                    anchors.rightMargin: Tokens.spacing.s
                    anchors.verticalCenter: parent.verticalCenter
                    text: row.modelData.note
                    font.pixelSize: Tokens.font.small
                    color: row.isCurrent ? Colors.overPrimary : Colors.outline
                }
                MouseArea {
                    id: rowMouse
                    anchors.fill: parent
                    hoverEnabled: true
                    cursorShape: Qt.PointingHandCursor
                    onClicked: root.pick(row.modelData.target)
                }
            }

            StyledText {
                anchors.centerIn: parent
                visible: root.matches.length === 0
                text: "No apps found"
                font.pixelSize: Tokens.font.small
                color: Colors.outline
            }
        }
    }
}
