import QtQuick
import qs.core
import qs.components
import qs.theme
import "../../../theme/colorRoles.js" as Roles

// One colour token of the shell's mapping (Store.theme.colors[mode][token], theme/colorRoles.js) in the
// mode being shown: its swatch, its name, where it comes from ("Auto" by default) and a reset; a click
// opens the source picker below (`open`, toggled by the page so one is open at a time, or on its own).
Column {
    id: row

    required property string token
    property string title: Roles.BY_TOKEN[token]?.title ?? token
    // the shell's own mode (picking one in Appearance switches the shell)
    readonly property string mode: Store.theme.light ? "light" : "dark"
    readonly property string spec: Store.theme.colors?.[mode]?.[token] ?? ""
    property bool open: false
    // a click on the row (the page decides what opens); without a handler it toggles itself
    signal toggled

    // set (or with "" reset) the spec in the shown mode; the object is reassigned to save
    function setSpec(spec: string) {
        const all = {
            dark: Object.assign({}, Store.theme.colors?.dark),
            light: Object.assign({}, Store.theme.colors?.light)
        };
        if (spec === "")
            delete all[mode][token];
        else
            all[mode][token] = spec;
        Store.theme.colors = all;
    }

    width: parent?.width ?? 0
    spacing: Tokens.spacing.s
    bottomPadding: open ? Tokens.spacing.s : 0

    Item {
        width: parent.width
        height: 34

        Rectangle {
            id: swatch
            anchors.verticalCenter: parent.verticalCenter
            width: 22
            height: 22
            radius: 6
            color: Colors.resolveFor(row.mode, row.token)
            border.width: 1
            border.color: Colors.outlineVariant
        }
        StyledText {
            anchors.left: swatch.right
            anchors.leftMargin: Tokens.spacing.m
            anchors.verticalCenter: parent.verticalCenter
            text: row.title
        }
        Row {
            anchors.right: parent.right
            anchors.verticalCenter: parent.verticalCenter
            spacing: Tokens.spacing.s

            StyledText {
                anchors.verticalCenter: parent.verticalCenter
                text: Roles.describe(row.spec)
                font.pixelSize: Tokens.font.small
                color: row.spec === "" ? Colors.outline : Colors.primary
            }
            IconButton {
                anchors.verticalCenter: parent.verticalCenter
                visible: row.spec !== ""
                icon: Icons.arrowCounterClockwise
                size: 14
                onClicked: row.setSpec("")
            }
            Icon {
                anchors.verticalCenter: parent.verticalCenter
                icon: row.open ? Icons.caretDown : Icons.caretRight
                size: 12
                color: Colors.outline
            }
        }
        MouseArea {
            anchors.fill: parent
            anchors.rightMargin: row.spec !== "" ? 50 : 0
            cursorShape: Qt.PointingHandCursor
            onClicked: row.toggled()
        }
    }
    Loader {
        width: parent.width
        active: row.open
        visible: active
        sourceComponent: ColorSourcePicker {
            mode: row.mode
            spec: row.spec
            onPicked: s => row.setSpec(s)
        }
    }
}
