import QtQuick
import qs.core
import qs.theme
import qs.kit as K
import qs.components
import qs.dwidgets

// One dashboard entry: loads its Dwidget, places it at the rect the layout engine gave it and
// handles the generic expand triggers (see dwidgets/README.md, "Expansion flow").
//  - x / y / width / height move to the rect on the island body's curve (K.Anim DefaultSpatial; R1 area 3,
//    2026-10-15, was ContentAnim)
//  - it comes in with the dashboard: a fade and a short rise, one after another in reading order
//  - the Dwidget renders the current mode's style (idle / expanded)
//  - click / hover events here; the Dwidget's own expandRequest (e.g. a Qwidget panel) counts only
//    when the entry has an event (expandable)
//  - over: the expanded cell is raised; the cells it covers fade out (as it really covers them, so they
//    come back as it shrinks off them) and the others dim
//  - takeover: the other cells fade out (their rect doesn't move)
//  - over / takeover: the other cells are blocked while one is expanded; a click on them collapses it
Item {
    id: cell

    required property var entry
    required property Item grid

    // { x, y, w, h, z, hidden } in cells
    readonly property var rect: grid.solved.rects[entry.uid] ?? ({
            x: 0,
            y: 0,
            w: 1,
            h: 1,
            z: 0,
            hidden: true
        })
    readonly property bool expanded: grid.expandedUid === entry.uid
    // none while editing, or while the Dwidget's panel is its face (a toggle at 3x3 and up, 2026-10-27)
    readonly property string trigger: grid.editing || (loader.item?.panelFace ?? false) ? "none" : DwidgetRegistry.trigger(entry)
    readonly property bool expandable: trigger !== "none"
    // stays on top while it shrinks back, until another cell expands
    readonly property bool raised: expanded || grid.lastExpandedUid === entry.uid
    onRaisedChanged: if (raised)
        grid.raisedCell = cell
    // over: under the raised cell as it is drawn now (it doesn't hide its neighbours with a backing,
    // which a translucent island would show through)
    readonly property Item over: grid.mode === "over" && !raised ? grid.raisedCell : null
    readonly property bool covered: over !== null && over.x < x + width - 1 && x < over.x + over.width - 1 && over.y < y + height - 1 && y < over.y + over.height - 1
    readonly property bool dimmed: grid.expandedUid !== "" && !expanded && grid.mode === "over"
    // a simple box instead of the real Dwidget (the grid asks, or the Dwidget opts out of previews)
    readonly property bool simple: grid.simple || (grid.editing && DwidgetRegistry.widgets[entry.id]?.preview === false)

    x: grid.px(rect.x)
    y: grid.px(rect.y)
    width: grid.span(rect.w)
    height: grid.span(rect.h)
    z: raised ? 1 : 0
    clip: true
    enabled: !rect.hidden && !covered
    opacity: shade * enter

    // hidden / dimmed (the entrance is apart, so this fade doesn't chase it)
    // (over: every other cell dims alike, the covered ones too; user, 2026-10-17)
    property real shade: rect.hidden ? 0 : dimmed ? 0.4 : 1
    Behavior on shade {
        K.Anim {
            type: K.Anim.FastEffects
        }
    }

    Behavior on x {
        K.Anim {}
    }
    Behavior on y {
        K.Anim {}
    }
    Behavior on width {
        K.Anim {}
    }
    Behavior on height {
        K.Anim {}
    }

    // the entrance, each time the dashboard opens: hidden until its turn (not in the settings preview,
    // nor without animations)
    readonly property bool enters: K.Kit.anim.enabled && !grid.editing
    property real enter: enters ? 0 : 1
    SequentialAnimation {
        id: entrance
        // a little before the island's page starts fading in (PageHost: 30 % of the switch), then 35 ms
        // apart (the island's page fade and this one multiply: a later start leaves the body empty)
        PauseAnimation {
            duration: K.Kit.anim.durations.expressiveDefaultSpatial * 0.15 + 35 * cell.grid.rank(cell.entry.uid)
        }
        K.Anim {
            target: cell
            property: "enter"
            to: 1
            type: K.Anim.FastSpatial
        }
    }
    function playEntrance() {
        entrance.stop();
        if (!enters) {
            enter = 1;
            return;
        }
        enter = 0;
        entrance.start();
    }
    Component.onCompleted: playEntrance()
    Connections {
        target: cell.grid
        function onEntering() {
            cell.playEntrance();
        }
    }

    transform: Translate {
        y: Math.round((1 - cell.enter) * 8)
    }

    DwidgetFace {
        anchors.fill: parent
        visible: cell.simple
        widgetId: cell.entry.id
        size: cell.rect.w + "x" + cell.rect.h
    }

    Loader {
        id: loader
        anchors.fill: parent
        active: !cell.simple
        sourceComponent: DwidgetRegistry.component(cell.entry.id)
        onLoaded: {
            // one style in both states (expanding, only for the Dwidgets that need it, grows the rect)
            item.style = Qt.binding(() => cell.entry.idle?.style ?? "");
            item.size = Qt.binding(() => ({
                        w: cell.rect.w,
                        h: cell.rect.h
                    }));
            item.targetWidth = Qt.binding(() => cell.grid.span(cell.rect.w));
            item.targetHeight = Qt.binding(() => cell.grid.span(cell.rect.h));
            item.expanded = Qt.binding(() => cell.expanded);
            item.expandable = Qt.binding(() => cell.expandable);
            item.trigger = Qt.binding(() => cell.trigger);
            item.options = Qt.binding(() => cell.entry.options ?? ({}));
            item.editing = Qt.binding(() => cell.grid.editing);
            // the entry's uid, for a Dwidget that keeps something of its own (the Image's folder pick)
            if (item.hasOwnProperty("uid"))
                item.uid = Qt.binding(() => cell.entry.uid);
        }
    }

    // over / takeover: while another cell is expanded this one takes no input; a click on it only
    // collapses that cell (so a toggle next to it doesn't flip)
    MouseArea {
        anchors.fill: parent
        z: 2
        visible: cell.grid.expandedUid !== "" && !cell.expanded && cell.grid.mode !== "push"
        acceptedButtons: Qt.AllButtons
        hoverEnabled: true
        onClicked: cell.grid.expandRequest(cell.grid.expandedUid, false)
        onWheel: w => w.accepted = true
    }

    // the Dwidget's own expanded size (`expandSize`, optional)
    readonly property string wantedSize: loader.item?.expandSize ?? ""
    onWantedSizeChanged: grid.want(entry.uid, wantedSize)

    Connections {
        target: loader.item
        ignoreUnknownSignals: true
        function onExpandRequest(on) {
            // the Dwidget's own request (a toggle's event, a Qwidget's panel): when it expands at all
            if (DwidgetRegistry.expands(cell.entry.id) && !cell.grid.editing)
                cell.grid.expandRequest(cell.entry.uid, on);
        }
    }

    // click: toggles (taps taken by the Dwidget's own controls don't count)
    TapHandler {
        enabled: cell.trigger === "click"
        gesturePolicy: TapHandler.ReleaseWithinBounds
        onTapped: cell.grid.expandRequest(cell.entry.uid, !cell.expanded)
    }

    // double click: toggles. Dwidgets whose own click does something (a toggle) handle the double
    // click themselves (their controls take the taps) and ask through expandRequest
    TapHandler {
        enabled: cell.trigger === "doubleclick"
        gesturePolicy: TapHandler.ReleaseWithinBounds
        onDoubleTapped: cell.grid.expandRequest(cell.entry.uid, !cell.expanded)
    }

    // hover: expands after a short hold, collapses after a short leave (so crossing a gap or
    // the cell moving under the pointer doesn't flicker)
    HoverHandler {
        id: hover
        enabled: cell.trigger === "hover"
        onHoveredChanged: {
            if (hovered) {
                leaveTimer.stop();
                if (!cell.expanded)
                    enterTimer.restart();
            } else {
                enterTimer.stop();
                if (cell.expanded)
                    leaveTimer.restart();
            }
        }
    }
    Timer {
        id: enterTimer
        interval: 150
        onTriggered: cell.grid.expandRequest(cell.entry.uid, true)
    }
    Timer {
        id: leaveTimer
        interval: 250
        onTriggered: if (!hover.hovered)
            cell.grid.expandRequest(cell.entry.uid, false)
    }
}
