import QtQuick
import qs.core
import qs.components
import qs.theme

// Transient page for kinds without a view of their own (debug: `shell transient <kind>`).
// Transient pages get `payload` (updated in place) and size the island themselves; `islandCentered`
// makes PageHost center them like the idle page instead of pinning them at the app margin.
Item {
    id: root

    property var payload: ({})
    readonly property bool islandCentered: true

    implicitWidth: row.implicitWidth + 2 * 20
    implicitHeight: Store.island.heightExpanded

    Row {
        id: row
        anchors.centerIn: parent
        spacing: Tokens.spacing.s

        Icon {
            anchors.verticalCenter: parent.verticalCenter
            icon: Icons.info
            size: 18
            color: Colors.primary
        }
        StyledText {
            anchors.verticalCenter: parent.verticalCenter
            text: root.payload?.text ?? "Transient"
            font.weight: Font.DemiBold
        }
    }
}
