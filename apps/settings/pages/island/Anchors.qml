import QtQuick
import qs.core
import qs.theme
import "../../controls"

// Island → Anchors: how the island's three sections (left / center / right, Island → Layout) sit, per
// island mode side by side (island.anchors.compact / expanded, 2026-10-15): the centre kept in the middle
// or packed, the gaps inside and between them, and a card behind each.
Page {
    // (not a Repeater: Columns sizes its children, and the Repeater would count as one)
    Columns {
        AnchorsMode {
            mode: "compact"
            title: "Compact"
        }
        AnchorsMode {
            mode: "expanded"
            title: "Expanded"
        }
    }
}
