import QtQuick
import qs.theme

// Settings side by side: its children (Sections, or a Column of Sections) get equal widths and
// line up at the top; the height is the tallest one.
//   Columns {
//       Section { … }
//       Column { spacing: Tokens.spacing.l; Section { … } Section { … } }
//   }
Item {
    id: root

    default property alias content: row.data
    property int spacing: Tokens.spacing.l

    width: parent?.width ?? 0
    implicitHeight: row.implicitHeight

    Row {
        id: row

        readonly property real columnWidth: children.length > 0 ? (width - root.spacing * (children.length - 1)) / children.length : width

        width: root.width
        spacing: root.spacing

        function bindWidths() {
            for (let i = 0; i < children.length; i++)
                children[i].width = Qt.binding(() => row.columnWidth);
        }

        onChildrenChanged: bindWidths()
        Component.onCompleted: bindWidths()
    }
}
