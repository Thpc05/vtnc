import QtQuick
import Quickshell
import Quickshell.Wayland
import qs.core
import qs.services

// Tiled windows give way to the frame: an invisible, click-through strip on each screen edge
// whose exclusive zone is the frame's thickness (as caelestia's Exclusions). Off while a window
// is fullscreen (the frame collapses then) or the frame is off. The top one sits under the
// island's own reservation (ReserveWindow), which stacks on it.
Scope {
    id: root

    required property ShellScreen screen
    readonly property int thickness: Store.frame.enabled && !Hypr.hasFullscreen(screen) ? Math.max(0, Store.frame.thickness) : 0

    component Edge: PanelWindow {
        screen: root.screen
        color: "transparent"
        WlrLayershell.namespace: "vtnc:frame"
        WlrLayershell.layer: WlrLayer.Bottom
        mask: Region {}
        implicitWidth: 1
        implicitHeight: 1
        exclusiveZone: root.thickness
        visible: root.thickness > 0
    }

    Edge {
        anchors {
            top: true
            left: true
            right: true
        }
    }
    Edge {
        anchors {
            bottom: true
            left: true
            right: true
        }
    }
    Edge {
        anchors {
            left: true
            top: true
            bottom: true
        }
    }
    Edge {
        anchors {
            right: true
            top: true
            bottom: true
        }
    }
}
