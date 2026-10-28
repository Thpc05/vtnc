import QtQuick
import qs.components
import qs.theme
import qs.dwidgets.quick.panels
import qs.kit as K

// Font family picker: a field showing the current family in its own font; clicking it opens a
// searchable list of the installed families right below (inline, so the page's clip and scroll
// never cut it), each row rendered in its font.
// ↑/↓ move through the list, Enter picks, Escape closes. `emptyLabel` adds a "" entry on top (e.g. "Theme font").
Column {
    id: root

    property string value: ""
    property string emptyLabel: ""
    property bool open: false

    signal edited(string value)

    // the apps' look (R1.5, 2026-10-17)
    readonly property PanelColors c: PanelColors {
        look: K.Kit.appLook
    }

    readonly property var families: {
        const seen = {};
        return Qt.fontFamilies().filter(f => !seen[f] && (seen[f] = true)).sort((a, b) => a.localeCompare(b));
    }
    readonly property var matches: {
        const q = search.text.trim().toLowerCase();
        const list = q === "" ? families : families.filter(f => f.toLowerCase().includes(q));
        return emptyLabel !== "" && q === "" ? [""].concat(list) : list;
    }

    function pick(family: string) {
        open = false;
        if (family !== value)
            edited(family);
    }

    width: 240
    spacing: 4

    onOpenChanged: {
        if (open) {
            search.text = "";
            search.forceActiveFocus();
            list.currentIndex = Math.max(0, matches.indexOf(value));
            list.positionViewAtIndex(list.currentIndex, ListView.Center);
        }
    }

    // field
    Rectangle {
        width: root.width
        height: 30
        radius: height / 2
        color: root.c.off
        border.width: root.open ? 2 : 0
        border.color: root.c.accent

        StyledText {
            anchors.left: parent.left
            anchors.leftMargin: Tokens.spacing.m
            anchors.right: caret.left
            anchors.rightMargin: Tokens.spacing.s
            anchors.verticalCenter: parent.verticalCenter
            elide: Text.ElideRight
            text: root.value === "" ? root.emptyLabel : root.value
            font.family: root.value === "" ? Tokens.font.family : root.value
            font.pixelSize: Tokens.font.small
            color: root.value === "" ? root.c.weak : root.c.strong
        }
        Icon {
            id: caret
            anchors.right: parent.right
            anchors.rightMargin: Tokens.spacing.s
            anchors.verticalCenter: parent.verticalCenter
            icon: Icons.caretDown
            size: 14
            color: root.c.weak
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
        height: root.open ? 260 : 0
        visible: height > 0
        opacity: root.open ? 1 : 0
        radius: K.Kit.rounding.large
        color: root.c.off
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
            color: Qt.alpha(root.c.strong, 0.08)

            Icon {
                id: searchIcon
                anchors.left: parent.left
                anchors.leftMargin: Tokens.spacing.s
                anchors.verticalCenter: parent.verticalCenter
                icon: Icons.magnifyingGlass
                size: 13
                color: root.c.weak
            }
            TextInput {
                id: search
                anchors.left: searchIcon.right
                anchors.leftMargin: Tokens.spacing.s
                anchors.right: parent.right
                anchors.rightMargin: Tokens.spacing.s
                anchors.verticalCenter: parent.verticalCenter
                clip: true
                color: root.c.strong
                selectionColor: root.c.accent
                selectedTextColor: root.c.overAccent
                font.family: Tokens.font.family
                font.pixelSize: Tokens.font.small
                onTextChanged: list.currentIndex = 0
                // consumed here: the settings view uses ↑/↓ to change pages
                Keys.onUpPressed: list.currentIndex = Math.max(0, list.currentIndex - 1)
                Keys.onDownPressed: list.currentIndex = Math.min(root.matches.length - 1, list.currentIndex + 1)
                Keys.onReturnPressed: if (root.matches.length > 0) root.pick(root.matches[list.currentIndex])
                Keys.onEnterPressed: if (root.matches.length > 0) root.pick(root.matches[list.currentIndex])
                Keys.onEscapePressed: root.open = false

                StyledText {
                    anchors.verticalCenter: parent.verticalCenter
                    visible: search.text === ""
                    text: `Search ${root.families.length} fonts`
                    font.pixelSize: Tokens.font.small
                    color: root.c.weak
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
                required property string modelData
                required property int index
                readonly property bool isCurrent: modelData === root.value
                readonly property bool isKey: index === list.currentIndex

                width: list.width
                height: 28
                radius: height / 2
                color: isCurrent ? (root.c.kind === "tone" ? Qt.alpha(root.c.accent, 0.2) : root.c.accent) : (rowMouse.containsMouse || isKey ? Qt.alpha(root.c.strong, 0.08) : "transparent")

                StyledText {
                    anchors.left: parent.left
                    anchors.leftMargin: Tokens.spacing.s
                    anchors.right: parent.right
                    anchors.rightMargin: Tokens.spacing.s
                    anchors.verticalCenter: parent.verticalCenter
                    elide: Text.ElideRight
                    text: row.modelData === "" ? root.emptyLabel : row.modelData
                    font.family: row.modelData === "" ? Tokens.font.family : row.modelData
                    font.pixelSize: Tokens.font.normal
                    color: row.isCurrent ? (root.c.kind === "tone" ? root.c.accent : root.c.overAccent) : root.c.strong
                }
                MouseArea {
                    id: rowMouse
                    anchors.fill: parent
                    hoverEnabled: true
                    cursorShape: Qt.PointingHandCursor
                    onClicked: root.pick(row.modelData)
                }
            }

            StyledText {
                anchors.centerIn: parent
                visible: root.matches.length === 0
                text: "No fonts found"
                font.pixelSize: Tokens.font.small
                color: root.c.weak
            }
        }
    }
}
