import QtQuick
import Quickshell.Hyprland
import "../../ConfigValues"
import "../../Ui"

// ═══════════════════════════════════════════
//  WORKSPACES — Dots dos workspaces do Hyprland.
//  Focado = cápsula accent alargada (estilo iOS);
//  clique num dot troca de workspace.
// ═══════════════════════════════════════════
Row {
    id: root

    spacing: 7

    // Ordenados por id; ignora specials (id negativo)
    readonly property var list: [...Hyprland.workspaces.values]
        .filter(w => w.id > 0)
        .sort((a, b) => a.id - b.id)
    readonly property int count: list.length

    Repeater {
        model: root.list

        Rectangle {
            required property var modelData

            readonly property bool focused: modelData.focused

            anchors.verticalCenter: parent.verticalCenter
            width: focused ? 22 : 8
            height: 8
            radius: 4
            color: focused
                ? Theme.accent
                : (dotHover.hovered ? Theme.textSecondary : Theme.textMuted)

            Behavior on width { Settle { duration: 250 } }
            Behavior on color { ColorAnimation { duration: Motion.instant } }

            HoverHandler { id: dotHover }
            TapHandler { onTapped: Hyprland.dispatch("workspace " + modelData.id) }
        }
    }
}
