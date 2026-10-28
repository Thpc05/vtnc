import QtQuick
import qs.core
import qs.theme
import qs.kit as K
import qs.components
import qs.dwidgets
import qs.apps.dashboard as Dash
import "../../controls"
import "../../../../dwidgets/layout.js" as Engine
import "../../../../dwidgets/quick/qwidgets.js" as Qw
import "../../../../dwidgets/sliders/swidgets.js" as Sw

// Dashboard → Layout: the layout editor (dwidgets/README.md, "Settings editor").
//  - canvas: the real dashboard (Dwidgets render only; simple boxes when it's scaled down a lot)
//    with one spare column and row to grow into; drag a Dwidget to move it (an outline shows
//    where it lands, the ones it lands on are pushed down on drop); the corner knob resizes it
//    to the nearest size its style allows
//  - Off: Dwidgets not on the dashboard, with their settings kept; drag them in and out
//  - detail panel: style, size, how it expands, duplicate, remove / add
// The canvas is the main column; the side panel has Off on top and the selected Dwidget below.
// Every edit rewrites dashboard.widgets with the positions from the layout engine (what's saved
// is what's shown).
SplitPage {
    id: page

    readonly property var all: Store.dashboard.widgets ?? []
    readonly property var placed: all.filter(e => !e.off)
    readonly property var offEntries: all.filter(e => e.off)

    // the first placed one; a Dwidget handed over from before the app closed (the Image's Browse…, which
    // closes Settings while the chooser is open) when it's still there
    property string selectedUid: {
        const back = Store.appGet("settings", "layoutUid", "");
        return all.some(e => e.uid === back) ? back : placed[0]?.uid ?? all[0]?.uid ?? "";
    }
    readonly property var selected: all.find(e => e.uid === selectedUid) ?? null

    // a usage tip under a Dwidget's title in the detail panel, on its own card (2026-10-17, user)
    readonly property var tips: ({
            media: "Right-click it to pick which player it shows"
        })

    // Dwidget-specific options in the detail panel: id → Component
    readonly property var options: ({
            quick: quickOptions,
            sliders: sliderOptions,
            calendar: calendarOptions,
            media: mediaOptions,
            wifi: toggleOptions,
            bluetooth: toggleOptions,
            mixer: mixerOptions,
            colorScheme: toggleOptions,
            powerProfile: toggleOptions,
            wallpaper: toggleOptions,
            notifications: summaryOptions,
            clipboard: summaryOptions,
            notes: summaryOptions,
            dino: summaryOptions,
            image: imageOptions,
            clock: clockOptions,
            visualizer: visualizerOptions
        })

    Component {
        id: mixerOptions
        LookOptions {
            entry: page.selected
            showGap: false
            showMixer: true
            onEdited: o => page.edit(page.selected.uid, {
                    options: o
                })
        }
    }
    Component {
        id: clockOptions
        LookOptions {
            entry: page.selected
            showGap: false
            showWeight: false
            showLabels: false
            showClock: true
            shapesHint: "Shapes: the mark behind the time takes a random shape each time the dashboard opens. Off: a circle"
            onEdited: o => page.edit(page.selected.uid, {
                    options: o
                })
        }
    }
    Component {
        id: visualizerOptions
        LookOptions {
            entry: page.selected
            showGap: false
            showWeight: false
            showLabels: false
            showShapes: false
            showVisualizer: true
            onEdited: o => page.edit(page.selected.uid, {
                    options: o
                })
        }
    }
    Component {
        id: imageOptions
        ImageOptions {
            entry: page.selected
            onEdited: o => page.edit(page.selected.uid, {
                    options: o
                })
        }
    }

    Component {
        id: summaryOptions
        LookOptions {
            entry: page.selected
            showGap: false
            showWeight: false
            showLabels: false
            shapesHint: "Shapes: the mark takes a random shape each time the dashboard opens (in sync with the others). Off: a circle"
            onEdited: o => page.edit(page.selected.uid, {
                    options: o
                })
        }
    }

    Component {
        id: toggleOptions
        LookOptions {
            entry: page.selected
            showGap: false
            onEdited: o => page.edit(page.selected.uid, {
                    options: o
                })
        }
    }
    Component {
        id: mediaOptions
        LookOptions {
            entry: page.selected
            showGap: false
            showWeight: false
            showLabels: false
            showMedia: true
            showShapes: false
            onEdited: o => page.edit(page.selected.uid, {
                    options: o
                })
        }
    }
    Component {
        id: calendarOptions
        LookOptions {
            entry: page.selected
            showGap: false
            showLabels: false
            showCalendar: true
            weightTo: 900
            weightHint: "The days' (Auto: the look's)"
            onEdited: o => page.edit(page.selected.uid, {
                    options: o
                })
        }
    }
    Component {
        id: quickOptions
        Column {
            width: parent?.width ?? 0

            LookOptions {
                entry: page.selected
                onEdited: o => page.edit(page.selected.uid, {
                        options: o
                    })
            }
            ItemsOptions {
                entry: page.selected
                catalog: Qw
                entries: Qw.QWIDGETS
                heading: "Qwidgets"
                hint: "Drag to reorder, click one to remove it or pick its app. Any of them may repeat: build your own Session, Tools or apps Dwidget. Wi-Fi and Bluetooth can also be their own Dwidgets, with their panels"
                onEdited: o => page.edit(page.selected.uid, {
                        options: o
                    })
            }
        }
    }
    Component {
        id: sliderOptions
        Column {
            width: parent?.width ?? 0

            LookOptions {
                entry: page.selected
                showGap: false
                showWeight: false
                showLabels: false
                showSlider: true
                showShapes: false
                onEdited: o => page.edit(page.selected.uid, {
                        options: o
                    })
            }
            ItemsOptions {
                entry: page.selected
                catalog: Sw
                entries: Sw.SWIDGETS
                heading: "Swidgets"
                hint: "The sliders it shows: drag to reorder, click one to remove it"
                onEdited: o => page.edit(page.selected.uid, {
                        options: o
                    })
            }
        }
    }

    // drag state (a ghost carries the Drag, like the island widget chips)
    property var dragEntry: null
    property bool dragActive: false
    // resize preview: { uid, size } while the knob is dragged
    property var resizing: null

    readonly property real pitch: grid.cell + grid.gap
    // the canvas has one spare column and row to drop into
    readonly property int canvasCols: Math.max(4, grid.solved.cols + 1)
    readonly property int canvasRows: Math.max(3, grid.solved.rows + 1)
    readonly property real canvasWidth: grid.span(canvasCols)
    readonly property real canvasHeight: grid.span(canvasRows)
    readonly property real canvasScale: Math.min(1, (mainPage.width - 2 * Tokens.spacing.l - Tokens.spacing.m) / canvasWidth)

    // a style's sizes as Segmented options, smallest first (by width + height; ties keep the
    // catalog's order, whose first size is the default)
    function sizeOptions(id, styleId) {
        const st = DwidgetRegistry.styles(id ?? "").find(s => s.id === styleId);
        const cells = z => z.split("x").reduce((a, n) => a + Number(n), 0);
        return (st?.sizes ?? []).slice().sort((a, b) => cells(a) - cells(b)).map(z => ({
                    value: z,
                    label: z.replace("x", "×")
                }));
    }

    // edits -----------------------------------------------------------------------
    function copyOf(e) {
        return JSON.parse(JSON.stringify(e));
    }

    function write(list) {
        Store.dashboard.widgets = list;
    }

    function sizeOf(size) {
        return DwidgetRegistry.parseSize(size) ?? ({
                w: 1,
                h: 1
            });
    }

    // put `uid` on the dashboard at x/y with idle size `size` (from the grid, from Off, or a resize),
    // with `changes` applied to it; the others are re-placed around it by the layout engine
    function place(uid, x, y, size, changes) {
        const s = sizeOf(size);
        const items = placed.map(e => {
            const z = sizeOf(e.idle.size);
            return {
                uid: e.uid,
                x: e.x,
                y: e.y,
                w: z.w,
                h: z.h
            };
        });
        const pos = Engine.drop(items, uid, x, y, s.w, s.h);
        write(all.map(e => {
            const c = copyOf(e);
            if (c.uid === uid) {
                Object.assign(c, changes ?? {});
                c.idle = Object.assign({}, c.idle, {
                    size: size
                });
                c.off = false;
            }
            if (pos[c.uid]) {
                c.x = pos[c.uid].x;
                c.y = pos[c.uid].y;
            }
            return c;
        }));
    }

    function update(uid, changes) {
        write(all.map(e => e.uid === uid ? Object.assign(copyOf(e), changes) : copyOf(e)));
    }

    // a copy (uid ≠ id: Duplicate's `<id>-2`…) is deleted instead of going to Off: only the original
    // may be off (2026-10-11, as the island)
    function isCopy(e) {
        return !!e && e.uid !== e.id;
    }
    function takeOff(uid) {
        const e = all.find(x => x.uid === uid);
        if (!e || e.off)
            return;
        if (isCopy(e)) {
            write(all.filter(x => x.uid !== uid).map(copyOf));
            if (page.selectedUid === uid)
                page.selectedUid = all.find(x => x.uid === e.id)?.uid ?? placed[0]?.uid ?? "";
        } else {
            update(uid, {
                off: true
            });
        }
    }

    // add an off entry at the first free spot
    function addToDashboard(uid) {
        const e = all.find(x => x.uid === uid);
        if (!e)
            return;
        const s = sizeOf(e.idle.size);
        const items = placed.map(p => Object.assign({
                uid: p.uid,
                x: p.x,
                y: p.y
            }, sizeOf(p.idle.size)));
        const spot = Engine.firstFree(items, s.w, s.h, grid.solved.cols);
        place(uid, spot.x, spot.y, e.idle.size);
    }

    // a change to the look ({ idle: {…} }) or the options. The look is re-validated (a style that
    // doesn't allow the size falls back to its first size); on the dashboard it goes through the
    // engine (a bigger size pushes)
    function edit(uid, changes) {
        const e = all.find(x => x.uid === uid);
        if (!e)
            return;
        const next = copyOf(e);
        if (changes.idle)
            next.idle = DwidgetRegistry.validMode(e.id, Object.assign({}, e.idle, changes.idle), e.idle);
        if (changes.expandOn !== undefined)
            next.expandOn = changes.expandOn;
        if (changes.options !== undefined)
            next.options = changes.options;
        if (e.off)
            update(uid, next);
        else
            place(uid, e.x, e.y, next.idle.size, next);
    }

    // a copy with its own uid (`<id>-2`…), placed on the dashboard at the first free spot (never off)
    function duplicate(uid) {
        const e = all.find(x => x.uid === uid);
        if (!e)
            return;
        let n = 2;
        while (all.some(x => x.uid === e.id + "-" + n))
            n++;
        const c = Object.assign(copyOf(e), {
            uid: e.id + "-" + n,
            off: true
        });
        // add it (off, so the engine doesn't see it yet), then place it like "Add"
        const list = all.map(copyOf);
        list.splice(list.findIndex(x => x.uid === uid) + 1, 0, c);
        const s = sizeOf(c.idle.size);
        const items = placed.map(p => Object.assign({
                uid: p.uid,
                x: p.x,
                y: p.y
            }, sizeOf(p.idle.size)));
        const spot = Engine.firstFree(items, s.w, s.h, grid.solved.cols);
        const pos = Engine.drop(items, c.uid, spot.x, spot.y, s.w, s.h);
        write(list.map(x => {
            if (x.uid === c.uid)
                x.off = false;
            if (pos[x.uid]) {
                x.x = pos[x.uid].x;
                x.y = pos[x.uid].y;
            }
            return x;
        }));
        page.selectedUid = c.uid;
    }

    // drag ------------------------------------------------------------------------
    function startDrag(entry, grabX, grabY) {
        const s = sizeOf(entry.idle.size);
        page.dragEntry = entry;
        ghost.width = grid.span(s.w) * page.canvasScale;
        ghost.height = grid.span(s.h) * page.canvasScale;
        ghost.grab = Qt.point(Math.min(grabX, ghost.width), Math.min(grabY, ghost.height));
    }

    function moveGhost(item, mx, my) {
        const p = item.mapToItem(ghost.parent, mx, my);
        ghost.x = p.x - ghost.grab.x;
        ghost.y = p.y - ghost.grab.y;
    }

    function endDrag() {
        page.dragActive = false;
        page.dragEntry = null;
    }

    StyledText {
        width: parent.width
        leftPadding: Tokens.spacing.s
        wrapMode: Text.Wrap
        text: "Drag a Dwidget to move it; the ones it lands on move down. The corner knob resizes it to the sizes its style allows. Drop it on Off to take it off the dashboard: Off keeps one of each Dwidget with its settings (extra copies are removed)."
        font.pixelSize: Tokens.font.small
        color: Colors.overSurfaceVariant
    }

    // canvas ------------------------------------------------------------------------
    Card {
        id: canvasCard

        width: parent.width
        height: viewport.height + 2 * Tokens.spacing.l
        color: K.Kit.expressive.container // pane

        Item {
            id: viewport
            x: Tokens.spacing.l
            y: Tokens.spacing.l
            width: page.canvasWidth * page.canvasScale
            height: page.canvasHeight * page.canvasScale

            Item {
                id: canvas
                width: page.canvasWidth
                height: page.canvasHeight
                scale: page.canvasScale
                transformOrigin: Item.TopLeft

                // cell guides
                Repeater {
                    model: page.canvasCols * page.canvasRows

                    Rectangle {
                        required property int index
                        x: grid.px(index % page.canvasCols)
                        y: grid.px(Math.floor(index / page.canvasCols))
                        width: grid.cell
                        height: grid.cell
                        radius: K.Kit.rounding.medium
                        color: "transparent"
                        border.width: 1
                        border.color: Colors.outlineVariant
                        opacity: 0.5
                    }
                }

                // the island body behind the grid, as big as the dashboard
                Rectangle {
                    width: grid.implicitWidth
                    height: grid.implicitHeight
                    radius: K.Kit.rounding.large
                    color: K.Kit.expressive.page
                }

                Dash.DashboardGrid {
                    id: grid
                    width: implicitWidth
                    height: implicitHeight
                    entries: page.all
                    editing: true
                    simple: page.canvasScale < 0.6
                    cell: Math.max(40, Store.dashboard.cell || 80)
                    gap: Math.max(0, Store.dashboard.gap ?? 8)
                    mode: Store.dashboard.expandMode || "over"
                }

                // one handle per placed entry: select, drag, resize
                Repeater {
                    model: grid.placed

                    Item {
                        id: handle

                        required property var modelData
                        readonly property var rect: grid.solved.rects[modelData.uid] ?? ({
                                x: 0,
                                y: 0,
                                w: 1,
                                h: 1
                            })
                        readonly property bool selected: page.selectedUid === modelData.uid
                        readonly property bool dragged: page.dragActive && page.dragEntry?.uid === modelData.uid

                        x: grid.px(rect.x)
                        y: grid.px(rect.y)
                        width: grid.span(rect.w)
                        height: grid.span(rect.h)
                        z: selected ? 2 : 1

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

                        // placeholder look while its ghost is dragged
                        Rectangle {
                            anchors.fill: parent
                            radius: K.Kit.rounding.large
                            color: K.Kit.expressive.page
                            opacity: handle.dragged ? 0.6 : 0
                        }

                        Rectangle {
                            anchors.fill: parent
                            anchors.margins: -3
                            radius: K.Kit.rounding.large + 3
                            color: "transparent"
                            border.width: 2
                            border.color: Colors.primary
                            opacity: handle.selected ? 1 : (move.containsMouse ? 0.4 : 0)
                            Behavior on opacity {
                                K.Anim {
                                    type: K.Anim.FastEffects
                                }
                            }
                        }

                        MouseArea {
                            id: move

                            property point pressPos

                            anchors.fill: parent
                            hoverEnabled: true
                            preventStealing: true
                            acceptedButtons: Qt.LeftButton | Qt.RightButton
                            cursorShape: handle.dragged ? Qt.ClosedHandCursor : Qt.OpenHandCursor

                            onPressed: m => {
                                // a right click sends it to Off (2026-10-17, user)
                                if (m.button === Qt.RightButton) {
                                    page.takeOff(handle.modelData.uid);
                                    return;
                                }
                                pressPos = Qt.point(m.x, m.y);
                                page.startDrag(handle.modelData, m.x * page.canvasScale, m.y * page.canvasScale);
                            }
                            onPositionChanged: m => {
                                if (!pressed)
                                    return;
                                if (!page.dragActive && Math.hypot(m.x - pressPos.x, m.y - pressPos.y) > 6 / page.canvasScale)
                                    page.dragActive = true;
                                if (page.dragActive)
                                    page.moveGhost(move, m.x, m.y);
                            }
                            onReleased: m => {
                                if (m.button === Qt.RightButton)
                                    return;
                                const wasDrag = page.dragActive;
                                if (wasDrag)
                                    ghost.Drag.drop();
                                page.endDrag();
                                if (!wasDrag)
                                    page.selectedUid = handle.modelData.uid;
                            }
                            onCanceled: page.endDrag()
                        }

                        // resize knob (bottom-right corner)
                        Rectangle {
                            id: knob

                            readonly property int size: 16

                            x: parent.width - size / 2 - 2
                            y: parent.height - size / 2 - 2
                            width: size
                            height: size
                            radius: size / 2
                            color: Colors.primary
                            border.width: 2
                            border.color: K.Kit.expressive.page
                            visible: handle.selected && !handle.dragged
                            scale: resize.containsMouse || resize.pressed ? 1.25 : 1
                            Behavior on scale {
                                K.Anim {
                                    type: K.Anim.FastSpatial
                                }
                            }

                            MouseArea {
                                id: resize
                                anchors.fill: parent
                                anchors.margins: -4
                                hoverEnabled: true
                                preventStealing: true
                                cursorShape: Qt.SizeFDiagCursor

                                onPositionChanged: m => {
                                    if (!pressed)
                                        return;
                                    const p = mapToItem(handle, m.x, m.y);
                                    const w = Math.max(1, Math.round((p.x + grid.gap) / page.pitch));
                                    const h = Math.max(1, Math.round((p.y + grid.gap) / page.pitch));
                                    const style = DwidgetRegistry.styles(handle.modelData.id).find(s => s.id === handle.modelData.idle.style);
                                    page.resizing = {
                                        uid: handle.modelData.uid,
                                        size: Engine.nearestSize(style?.sizes ?? [handle.modelData.idle.size], w, h)
                                    };
                                }
                                onReleased: {
                                    const r = page.resizing;
                                    page.resizing = null;
                                    if (r && r.size && r.size !== handle.modelData.idle.size) {
                                        const e = handle.modelData;
                                        Qt.callLater(() => page.place(e.uid, e.x, e.y, r.size));
                                    }
                                }
                                onCanceled: page.resizing = null
                            }
                        }

                        // the size it will take
                        Rectangle {
                            readonly property var target: page.resizing?.uid === handle.modelData.uid ? page.sizeOf(page.resizing.size) : null
                            visible: target !== null
                            width: target ? grid.span(target.w) : 0
                            height: target ? grid.span(target.h) : 0
                            radius: K.Kit.rounding.large
                            color: Qt.alpha(Colors.primary, 0.12)
                            border.width: 2
                            border.color: Colors.primary

                            StyledText {
                                anchors.centerIn: parent
                                text: (page.resizing?.size ?? "").replace("x", "×")
                                font.weight: Font.Bold
                                color: Colors.primary
                            }
                        }
                    }
                }

                // where a dragged Dwidget lands
                Rectangle {
                    id: indicator

                    property int cellX: 0
                    property int cellY: 0
                    readonly property var target: page.dragEntry ? page.sizeOf(page.dragEntry.idle.size) : ({
                            w: 1,
                            h: 1
                        })

                    visible: drop.containsDrag
                    z: 3
                    x: grid.px(cellX)
                    y: grid.px(cellY)
                    width: grid.span(target.w)
                    height: grid.span(target.h)
                    radius: K.Kit.rounding.large
                    color: Qt.alpha(Colors.primary, 0.12)
                    border.width: 2
                    border.color: Colors.primary
                }

                DropArea {
                    id: drop

                    anchors.fill: parent
                    keys: ["vtnc-dwidget"]

                    // the cell under the dragged Dwidget's top-left corner
                    function track(drag) {
                        indicator.cellX = Math.max(0, Math.round((drag.x - ghost.grab.x / page.canvasScale) / page.pitch));
                        indicator.cellY = Math.max(0, Math.round((drag.y - ghost.grab.y / page.canvasScale) / page.pitch));
                    }

                    onEntered: drag => track(drag)
                    onPositionChanged: drag => track(drag)
                    onDropped: drag => {
                        const e = page.dragEntry;
                        const x = indicator.cellX;
                        const y = indicator.cellY;
                        // after the release handler finished (rewriting the list rebuilds the handles)
                        if (e)
                            Qt.callLater(() => {
                                page.place(e.uid, x, y, e.idle.size);
                                page.selectedUid = e.uid;
                            });
                    }
                }
            }
        }
    }

    // a mode's title in the detail panel
    component ModeHeader: Column {
        id: modeHeader

        property string text
        property string detail

        width: parent?.width ?? 0
        topPadding: Tokens.spacing.m
        spacing: 1

        StyledText {
            text: modeHeader.text
            font.pixelSize: Tokens.font.small
            font.weight: Font.Bold
            color: Colors.primary
        }
        StyledText {
            width: parent.width
            wrapMode: Text.Wrap
            text: modeHeader.detail
            font.pixelSize: Tokens.font.small
            color: Colors.outline
        }
    }

    // a small labelled button (the detail panel's actions)
    component ActionButton: Rectangle {
        id: action

        property string icon
        property string text
        signal clicked

        implicitWidth: actionRow.implicitWidth + 2 * Tokens.spacing.s
        implicitHeight: 28
        radius: height / 2
        color: actionMouse.containsMouse ? K.Kit.expressive.high : K.Kit.expressive.off
        Behavior on color {
            K.CAnim {}
        }

        Row {
            id: actionRow
            anchors.centerIn: parent
            spacing: Tokens.spacing.xs

            Icon {
                anchors.verticalCenter: parent.verticalCenter
                icon: action.icon
                size: 14
                color: Colors.primary
            }
            StyledText {
                anchors.verticalCenter: parent.verticalCenter
                text: action.text
                font.pixelSize: Tokens.font.small
            }
        }

        MouseArea {
            id: actionMouse
            anchors.fill: parent
            hoverEnabled: true
            cursorShape: Qt.PointingHandCursor
            onClicked: action.clicked()
        }
    }

    // off ---------------------------------------------------------------------------
    component OffChip: Rectangle {
        id: chip

        required property var entry
        readonly property var info: DwidgetRegistry.widgets[entry.id] ?? ({})
        readonly property bool selected: page.selectedUid === entry.uid
        readonly property bool dragged: page.dragActive && page.dragEntry?.uid === entry.uid

        implicitWidth: row.implicitWidth + 2 * Tokens.spacing.s
        implicitHeight: 32
        radius: height / 2
        color: mouse.containsMouse ? K.Kit.expressive.high : K.Kit.expressive.off
        border.width: selected ? 2 : 0
        border.color: Colors.primary
        opacity: dragged ? 0.3 : 1

        Row {
            id: row
            anchors.verticalCenter: parent.verticalCenter
            x: Tokens.spacing.s
            spacing: Tokens.spacing.s

            Icon {
                anchors.verticalCenter: parent.verticalCenter
                icon: Icons[chip.info.icon] ?? Icons.squaresFour
                size: 16
                color: Colors.primary
            }
            StyledText {
                anchors.verticalCenter: parent.verticalCenter
                // a copy is tagged ("media-2" → "Media · copy 2")
                text: (chip.info.title ?? chip.entry.id) + (page.isCopy(chip.entry) ? " · copy " + (chip.entry.uid.startsWith(chip.entry.id + "-") ? chip.entry.uid.slice(chip.entry.id.length + 1) : "") : "")
                font.pixelSize: Tokens.font.small
                font.weight: Font.DemiBold
            }
            StyledText {
                anchors.verticalCenter: parent.verticalCenter
                text: chip.entry.idle.size.replace("x", "×")
                font.pixelSize: Tokens.font.small - 2
                color: Colors.outline
            }
        }

        MouseArea {
            id: mouse

            property point pressPos

            anchors.fill: parent
            hoverEnabled: true
            preventStealing: true
            cursorShape: chip.dragged ? Qt.ClosedHandCursor : Qt.PointingHandCursor

            onPressed: m => {
                pressPos = Qt.point(m.x, m.y);
                // held by its first cell's centre
                page.startDrag(chip.entry, grid.cell * page.canvasScale / 2, grid.cell * page.canvasScale / 2);
            }
            onPositionChanged: m => {
                if (!pressed)
                    return;
                if (!page.dragActive && Math.hypot(m.x - pressPos.x, m.y - pressPos.y) > 6)
                    page.dragActive = true;
                if (page.dragActive)
                    page.moveGhost(mouse, m.x, m.y);
            }
            onReleased: {
                const wasDrag = page.dragActive;
                if (wasDrag)
                    ghost.Drag.drop();
                page.endDrag();
                if (!wasDrag)
                    page.selectedUid = chip.entry.uid;
            }
            onCanceled: page.endDrag()
        }
    }

    // detail panel ------------------------------------------------------------------
    // side panel: Off on top (compact), then the selected Dwidget
    side: [
        Card {
            id: offCard

            width: parent.width
            height: offHeader.height + Math.max(32, offFlow.implicitHeight, offEmpty.visible ? offEmpty.implicitHeight : 0) + Tokens.spacing.m
            color: offDrop.containsDrag ? K.Kit.expressive.high : K.Kit.expressive.container
            Behavior on color {
                K.CAnim {}
            }

            StyledText {
                id: offHeader
                height: 30
                leftPadding: Tokens.spacing.m
                verticalAlignment: Text.AlignVCenter
                text: "Off"
                font.pixelSize: Tokens.font.small
                font.weight: Font.Bold
                color: Colors.outline
            }

            StyledText {
                id: offEmpty
                visible: page.offEntries.length === 0
                x: Tokens.spacing.m
                y: offHeader.height
                width: parent.width - 2 * Tokens.spacing.m
                wrapMode: Text.Wrap
                text: "Drop a Dwidget here to take it off the dashboard"
                font.pixelSize: Tokens.font.small
                color: Colors.outline
            }

            Flow {
                id: offFlow
                x: Tokens.spacing.s
                y: offHeader.height
                width: parent.width - 2 * Tokens.spacing.s
                spacing: 4

                Repeater {
                    model: page.offEntries

                    OffChip {
                        required property var modelData
                        entry: modelData
                    }
                }
            }

            DropArea {
                id: offDrop
                anchors.fill: parent
                keys: ["vtnc-dwidget"]
                onDropped: drag => {
                    const e = page.dragEntry;
                    if (e && !e.off)
                        Qt.callLater(() => page.takeOff(e.uid));
                }
            }
        },
        Card {
            id: detail

            readonly property var entry: page.selected
            readonly property var info: entry ? DwidgetRegistry.widgets[entry.id] ?? ({}) : ({})
            readonly property var styles: entry ? DwidgetRegistry.styles(entry.id) : []
            // the style tree: the top styles, the current one's, and its variants
            readonly property var groups: styles.filter(s => !s.group)
            readonly property string group: styles.find(s => s.id === entry?.idle?.style)?.group ?? entry?.idle?.style ?? ""
            readonly property var variants: styles.filter(s => s.id === group || s.group === group)

            width: parent?.width ?? 0
            height: (entry ? detailColumn.implicitHeight : emptyHint.implicitHeight) + 2 * Tokens.spacing.m
            color: K.Kit.expressive.container // pane

            StyledText {
                id: emptyHint
                visible: detail.entry === null
                x: Tokens.spacing.l
                y: Tokens.spacing.m
                width: parent.width - 2 * Tokens.spacing.l
                wrapMode: Text.Wrap
                text: "Select a Dwidget to edit it"
                font.pixelSize: Tokens.font.small
                color: Colors.outline
            }

            Column {
                id: detailColumn
                visible: detail.entry !== null
                x: Tokens.spacing.l
                y: Tokens.spacing.m
                width: parent.width - 2 * Tokens.spacing.l
                spacing: 0

                // header: icon, title, where it is
                Row {
                    spacing: Tokens.spacing.s

                    Icon {
                        anchors.verticalCenter: parent.verticalCenter
                        icon: Icons[detail.info.icon] ?? Icons.squaresFour
                        size: 18
                        color: Colors.primary
                    }
                    StyledText {
                        anchors.verticalCenter: parent.verticalCenter
                        text: detail.info.title ?? ""
                        font.pixelSize: Tokens.font.large
                        font.weight: Font.Bold
                    }
                }
                StyledText {
                    topPadding: 2
                    text: (detail.entry?.off ? "Off" : "On the dashboard") + (page.isCopy(detail.entry) ? " · copy (taking it off deletes it)" : "")
                    font.pixelSize: Tokens.font.small
                    color: Colors.outline
                }

                // its tip, on its own card
                Item {
                    id: tipBox
                    readonly property string tip: page.tips[detail.entry?.id] ?? ""
                    visible: tip !== ""
                    width: parent.width
                    height: visible ? tipCard.height + Tokens.spacing.s : 0

                    Rectangle {
                        id: tipCard
                        y: Tokens.spacing.s
                        width: parent.width
                        height: tipRow.implicitHeight + 2 * Tokens.spacing.s
                        radius: K.Kit.rounding.medium
                        color: K.Kit.expressive.high

                        Row {
                            id: tipRow
                            x: Tokens.spacing.m
                            anchors.verticalCenter: parent.verticalCenter
                            spacing: Tokens.spacing.s

                            Icon {
                                anchors.verticalCenter: parent.verticalCenter
                                icon: Icons.info
                                size: 16
                                color: Colors.primary
                            }
                            StyledText {
                                anchors.verticalCenter: parent.verticalCenter
                                width: tipCard.width - 2 * Tokens.spacing.m - 16 - Tokens.spacing.s
                                text: tipBox.tip
                                wrapMode: Text.Wrap
                                font.pixelSize: Tokens.font.small
                                color: Colors.overSurfaceVariant
                            }
                        }
                    }
                }

                // actions
                Row {
                    topPadding: Tokens.spacing.s
                    bottomPadding: Tokens.spacing.xs
                    spacing: Tokens.spacing.xs

                    ActionButton {
                        icon: detail.entry?.off ? Icons.plus : page.isCopy(detail.entry) ? Icons.trash : Icons.minus
                        text: detail.entry?.off ? "Add" : page.isCopy(detail.entry) ? "Delete copy" : "Take off"
                        onClicked: detail.entry.off ? page.addToDashboard(detail.entry.uid) : page.takeOff(detail.entry.uid)
                    }
                    ActionButton {
                        icon: Icons.copy
                        text: "Duplicate"
                        // the copy goes on the dashboard
                        onClicked: page.duplicate(detail.entry.uid)
                    }
                }

                // the look (the canvas and its knob edit the size too)
                ModeHeader {
                    text: "Look"
                    detail: "The style and its size; the canvas knob resizes too"
                }
                // a tree: the style (the catalog's styles without a `group`), then its variants
                // (itself and the styles grouped under it, by their `variant` label)
                SettingRow {
                    label: "Style"
                    visible: detail.groups.length > 1
                    Segmented {
                        options: detail.groups.map(s => ({
                                    value: s.id,
                                    label: s.title
                                }))
                        value: detail.group
                        onSelected: v => page.edit(detail.entry.uid, {
                                idle: {
                                    style: v
                                }
                            })
                    }
                }
                SettingRow {
                    label: "Variant"
                    visible: detail.variants.length > 1
                    Segmented {
                        options: detail.variants.map(s => ({
                                    value: s.id,
                                    label: s.variant ?? s.title
                                }))
                        value: detail.entry?.idle?.style ?? ""
                        onSelected: v => page.edit(detail.entry.uid, {
                                idle: {
                                    style: v
                                }
                            })
                    }
                }
                SettingRow {
                    label: "Size"
                    Segmented {
                        options: page.sizeOptions(detail.entry?.id, detail.entry?.idle?.style)
                        value: detail.entry?.idle?.size ?? ""
                        onSelected: v => page.edit(detail.entry.uid, {
                                idle: {
                                    size: v
                                }
                            })
                    }
                }

                // only the Dwidgets with an expand event (Wi-Fi / Bluetooth / Mixer): what expands them
                SettingRow {
                    label: "Expand on"
                    visible: DwidgetRegistry.hasEvent(detail.entry?.id ?? "")
                    Segmented {
                        options: [
                            {
                                value: "doubleclick",
                                label: "Double click"
                            },
                            {
                                value: "click",
                                label: "Click"
                            },
                            {
                                value: "hover",
                                label: "Hover"
                            },
                            {
                                value: "none",
                                label: "Never"
                            }
                        ]
                        value: DwidgetRegistry.trigger(detail.entry ?? null)
                        onSelected: v => page.edit(detail.entry.uid, {
                                expandOn: v
                            })
                    }
                }

                // Dwidget-specific options (a null component loads nothing)
                Loader {
                    width: parent.width
                    sourceComponent: page.options[detail.entry?.id ?? ""] ?? null
                }
            }
        }
    ]

    DwidgetFace {
        id: ghost

        property point grab

        parent: page.overlay
        z: 100
        visible: page.dragActive
        widgetId: page.dragEntry?.id ?? ""
        size: page.dragEntry?.idle?.size ?? ""
        highlighted: true
        opacity: 0.9

        Drag.active: page.dragActive
        Drag.keys: ["vtnc-dwidget"]
        Drag.source: ghost
        Drag.hotSpot.x: grab.x
        Drag.hotSpot.y: grab.y
    }
}
