import QtQuick
import Quickshell
import Quickshell.Hyprland
import qs.core
import qs.services
import qs.kit as K

// Workspaces of this screen's monitor, in one of three looks (stage 7, 2026-10-08; redone 2026-10-15):
//  - tones (Two tones) / tone (Tone): each workspace's label (dot, number, roman, Japanese) and its
//    windows (category symbols, app icons or shapes; caelestia's), the focused one on a sliding pill
//    (TonesStyle.qml; the old Shapes style became the windows' "shapes")
//  - pagination (M3 Expressive's page indicator): a dot each, the active one a long accent pill
// They show 1…N: per island mode (island.workspaces.compactCount / expandedCount) a fixed N, or 0 =
// dynamic (only the occupied ones and the active one); the active one is always in. Each
// can sit on the island card (a "Card" variant: `pal` is then Kit.islandCard). The wheel moves between
// workspaces.
Item {
    id: root

    property string style: "shapes"
    // curve direction shared with the island row (see WidgetSlot)
    property bool growing: true
    property ShellScreen screen: null
    // from the frame: the island mode and the palette (the card's, or the bare island's)
    property string mode: "compact"
    property var pal: K.Kit.bare

    readonly property HyprlandMonitor monitor: Hypr.monitorFor(screen)
    readonly property int activeId: monitor?.activeWorkspace?.id ?? 1

    // the occupied workspaces on this monitor and the active one
    readonly property var used: {
        const list = Hypr.workspaces.filter(w => w.id > 0 && (!monitor || w.monitor === monitor) && (Hypr.isOccupied(w.id) || w.id === activeId)).map(w => w.id);
        if (!list.includes(activeId))
            list.push(activeId);
        return list.sort((a, b) => a - b);
    }
    // the mode's count: 0 = dynamic (only the occupied ones and the active one), N = 1…N always plus
    // the occupied / active ones beyond N
    readonly property int count: (mode === "expanded" ? Store.island.workspaces?.expandedCount : Store.island.workspaces?.compactCount) ?? 0
    // a count: 1…N always, plus the occupied / active ones past N (as dynamic, with a floor; user)
    readonly property var range: {
        if (count <= 0)
            return used;
        const out = Array.from({
            length: count
        }, (_, i) => i + 1);
        for (const id of used)
            if (id > count)
                out.push(id);
        return out;
    }

    // the style's final width (for the island layout; implicitWidth animates towards it)
    readonly property real targetWidth: view.item?.targetWidth ?? 0
    implicitWidth: view.item?.implicitWidth ?? 0
    implicitHeight: view.item?.implicitHeight ?? 0

    WheelHandler {
        acceptedDevices: PointerDevice.Mouse | PointerDevice.TouchPad
        onWheel: e => Hypr.focusWorkspaceRelative(e.angleDelta.y < 0 ? 1 : -1)
    }

    Loader {
        id: view
        anchors.verticalCenter: parent.verticalCenter
        sourceComponent: root.style === "pagination" ? pagination : tones
    }
    Component {
        id: tones
        TonesStyle {
            ws: root
            two: root.style !== "tone"
        }
    }
    Component {
        id: pagination
        PaginationStyle {
            ws: root
        }
    }
}
