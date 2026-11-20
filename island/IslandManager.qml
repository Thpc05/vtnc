import QtQuick
import Quickshell
import "../core/grid.mjs" as Grid

// Creates one Island per (screen, configured island) pair — by default an
// island appears on every monitor (decision 1c.4; picking a subset is a
// Monitors-page feature, out of scope for 0.51).
Item {
    id: root

    required property var configRef

    Variants {
        model: Quickshell.screens

        Item {
            id: screenRoot
            required property var modelData
            readonly property var screen: modelData
            readonly property real cellPx: Grid.cellSizePx(root.configRef.data, screen.name)

            Variants {
                model: root.configRef.data.islands ?? []

                Island {
                    required property var modelData
                    islandConfig: modelData
                    configRef: root.configRef
                    cellPx: screenRoot.cellPx
                    screen: screenRoot.screen
                }
            }
        }
    }
}
