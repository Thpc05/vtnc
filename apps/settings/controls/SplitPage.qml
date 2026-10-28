import QtQuick
import qs.theme

// A settings page with a side panel: the main column and the side panel scroll on their own
// (both are Pages). `overlay` sits above both, unclipped (drag ghosts).
//   SplitPage {
//       Section { … }            // main column
//       side: Card { … }         // side panel (sideWidth wide)
//   }
Item {
    id: root

    default property alias content: mainCol.content
    property alias side: sideCol.content
    property int sideWidth: 320
    readonly property alias mainPage: mainCol
    readonly property alias sidePage: sideCol
    readonly property alias overlay: overlay

    Page {
        id: mainCol
        anchors.left: parent.left
        anchors.top: parent.top
        anchors.bottom: parent.bottom
        width: parent.width - root.sideWidth - Tokens.spacing.l
    }

    Page {
        id: sideCol
        anchors.right: parent.right
        anchors.top: parent.top
        anchors.bottom: parent.bottom
        width: root.sideWidth
    }

    Item {
        id: overlay
        anchors.fill: parent
        z: 100
    }
}
