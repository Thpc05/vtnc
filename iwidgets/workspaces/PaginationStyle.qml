import QtQuick
import qs.core
import qs.services
import qs.theme
import qs.components
import qs.kit as K

// Workspaces "pagination" (C; M3 Expressive's page indicator): 1…N, a dot each (occupied in the accent,
// empty weak), 5 px apart, the active one under an accent pill (20 px, a little taller than the dots)
// with 4 px clear on each side: that room moves with it, the dots sliding a little in step (none hides;
// a new workspace's dot grows in as the row widens). It moves as a worm (2026-10-09, user,
// after trying liquid and jump): the pill's leading edge shoots ahead over the dots in between and the
// trailing one catches up (the row's width never changes, so the island doesn't move).
// Its own look: it takes none of the Two tones / Tone options (the app icons option went, 2026-10-15).
Item {
    id: root

    required property Item ws
    readonly property var ids: ws.range
    readonly property int dot: 8
    // the pill at rest, and how far it clears its neighbours' dots (the dots between themselves keep
    // `gap`): `room` is the extra space on each side of the active dot
    readonly property int pill: 20
    readonly property int clear: 4
    readonly property real room: pill / 2 + clear + dot / 2 - (dot + gap)
    // room at each end for the pill's overhang past the first / last dot
    readonly property real restPad: (pill - dot) / 2
    // the active pill a little taller than the dots
    readonly property int pillHeight: 10
    readonly property int gap: 5

    readonly property int activeIndex: Math.max(0, ids.indexOf(ws.activeId))

    // final width: the slots
    readonly property real targetWidth: 2 * restPad + ids.length * (dot + gap) - gap + 2 * room
    implicitWidth: targetWidth
    implicitHeight: 20

    Loader {
        id: look
        anchors.fill: parent
        sourceComponent: plainLook
    }

    // plain -------------------------------------------------------------------------------------------
    Component {
        id: plainLook

        Item {
            id: plain

            // dot i's centre: 13 px apart (dot + gap), with `room` more on each side of the active one so
            // the pill clears its neighbours by `clear` (always reserved, so the row's width is fixed)
            function centre(i: int): real {
                const a = root.activeIndex;
                return root.restPad + root.dot / 2 + i * (root.dot + root.gap) + (i >= a ? root.room : 0) + (i > a ? root.room : 0);
            }
            // one dot per workspace, kept alive while its workspace is listed: the list is synced item
            // by item (a JS array model rebuilds every dot on any change — switching to or from an empty
            // workspace made them all vanish and come back, user). A workspace that leaves the list
            // stays as `leaving` while its dot shrinks out, then goes; one that (re)appears grows in.
            ListModel {
                id: dots
            }
            function sync() {
                const ids = root.ids;
                for (let i = 0; i < dots.count; i++) {
                    const it = dots.get(i);
                    const listed = ids.includes(it.ws);
                    if (it.leaving === listed)
                        dots.setProperty(i, "leaving", !listed);
                }
                // new ones, in order (leaving ones keep their place)
                for (const id of ids) {
                    let at = dots.count;
                    let found = false;
                    for (let i = 0; i < dots.count; i++) {
                        const w = dots.get(i).ws;
                        if (w === id) {
                            found = true;
                            break;
                        }
                        if (w > id) {
                            at = i;
                            break;
                        }
                    }
                    if (!found)
                        dots.insert(at, {
                            ws: id,
                            leaving: false
                        });
                }
            }
            function drop(ws: int) {
                for (let i = 0; i < dots.count; i++)
                    if (dots.get(i).ws === ws && dots.get(i).leaving) {
                        dots.remove(i);
                        return;
                    }
            }
            Connections {
                target: root
                function onIdsChanged() {
                    plain.sync();
                }
            }
            // only a dot added after the start (a new workspace) grows in
            property bool settled: false
            Component.onCompleted: {
                sync();
                settled = true;
            }

            // the dots (and the clicks): always there, sliding a little as the pill's room moves; they
            // aim at the final layout (root.ids), a leaving one stays put while it shrinks
            Repeater {
                model: dots

                Item {
                    id: cell
                    required property int ws
                    required property bool leaving
                    readonly property int modelData: ws
                    readonly property int listIndex: root.ids.indexOf(ws)
                    readonly property bool occupied: Hypr.isOccupied(modelData)

                    x: plain.centre(Math.max(0, listIndex)) - width / 2
                    width: root.dot + root.gap
                    height: 20
                    Behavior on x {
                        enabled: !cell.leaving
                        NumberAnimation {
                            duration: 280
                            easing.type: Easing.InOutCubic
                        }
                    }

                    // grows in (a new workspace) and shrinks out (one leaving the list); no fade
                    property real grow: 1
                    Component.onCompleted: if (plain.settled) {
                        grow = 0;
                        growIn.start();
                    }
                    onLeavingChanged: {
                        if (leaving) {
                            // stay where it was while it goes
                            x = x;
                            growIn.stop();
                            shrinkOut.start();
                        } else {
                            shrinkOut.stop();
                            x = Qt.binding(() => plain.centre(Math.max(0, cell.listIndex)) - cell.width / 2);
                            growIn.start();
                        }
                    }
                    NumberAnimation {
                        id: growIn
                        target: cell
                        property: "grow"
                        to: 1
                        duration: 300
                        easing.type: Easing.InOutCubic
                    }
                    SequentialAnimation {
                        id: shrinkOut
                        NumberAnimation {
                            target: cell
                            property: "grow"
                            to: 0
                            duration: 300
                            easing.type: Easing.InOutCubic
                        }
                        ScriptAction {
                            script: plain.drop(cell.ws)
                        }
                    }

                    Rectangle {
                        x: Math.round((parent.width - width) / 2)
                        y: Math.round((parent.height - height) / 2)
                        width: root.dot
                        height: root.dot
                        scale: cell.grow
                        radius: height / 2
                        color: cell.occupied || cell.modelData === root.ws.activeId ? root.ws.pal.accent : Qt.alpha(root.ws.pal.over, 0.3)
                        Behavior on color {
                            K.CAnim {}
                        }
                    }

                    MouseArea {
                        anchors.fill: parent
                        cursorShape: Qt.PointingHandCursor
                        onClicked: Hypr.focusWorkspace(cell.modelData)
                    }
                }
            }

            // the worm: the pill travels over the dots, its leading edge shooting ahead and the trailing
            // one catching up (they swap with the direction)
            Rectangle {
                id: worm
                readonly property real restL: plain.centre(root.activeIndex) - root.pill / 2
                // plain values (not bindings), set at the start without animating, then moved by
                // onRestLChanged (which reads the old edge to pick the leading one)
                property real edgeL: 0
                property real edgeR: 0
                property bool ready: false
                property bool rightward: true
                Component.onCompleted: {
                    edgeL = restL;
                    edgeR = restL + root.pill;
                    ready = true;
                }
                readonly property int leadMs: 180
                readonly property int trailMs: 380

                x: edgeL
                y: Math.round((parent.height - height) / 2)
                width: edgeR - edgeL
                height: root.pillHeight
                radius: height / 2
                color: root.ws.pal.accent

                Behavior on edgeL {
                    enabled: worm.ready
                    NumberAnimation {
                        duration: worm.rightward ? worm.trailMs : worm.leadMs
                        easing.type: Easing.InOutCubic
                    }
                }
                Behavior on edgeR {
                    enabled: worm.ready
                    NumberAnimation {
                        duration: worm.rightward ? worm.leadMs : worm.trailMs
                        easing.type: Easing.InOutCubic
                    }
                }

                onRestLChanged: {
                    rightward = restL > edgeL;
                    edgeL = restL;
                    edgeR = restL + root.pill;
                }
            }
        }
    }
}
