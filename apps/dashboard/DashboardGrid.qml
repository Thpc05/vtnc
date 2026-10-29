import QtQuick
import qs.core
import "../../dwidgets/layout.js" as Layout

// The dashboard grid: runs the layout engine (dwidgets/layout.js) over the entries and places a
// Cell per entry. Its implicit size is the grid's bounding box, so the island body morphs to it.
// Cells → px: an entry at x spans from x·(cell + gap), and w cells are w·cell + (w − 1)·gap wide.
Item {
    id: root

    // dashboard.widgets: [{ uid, id, idle: {style, size}, expanded: {style, size}, x, y, expandOn, off, options }]
    property var entries: []
    // the entries on the dashboard (off ones wait in the settings editor's Off area)
    readonly property var placed: entries.filter(e => !e.off)
    property int cell: 80
    property int gap: 8
    // over · push · takeover
    property string mode: "over"
    property string expandedUid: ""
    // the last entry expanded (it stays raised while it shrinks back), and its cell (over: the cells
    // under it fade out)
    property string lastExpandedUid: ""
    property Item raisedCell: null
    // settings preview: triggers off, Dwidgets render only
    property bool editing: false
    // every cell as a simple box (DwidgetFace) instead of the real Dwidget
    property bool simple: false

    signal expandRequest(string uid, bool on)
    // the dashboard opened: the cells come in (the page is kept between opens)
    signal entering
    function enter() {
        entering();
    }

    onExpandedUidChanged: if (expandedUid !== "")
        lastExpandedUid = expandedUid

    // the entries in cells, for the engine
    readonly property var items: placed.map(e => {
        const s = DwidgetRegistry.parseSize(e.idle?.size) ?? ({
                w: 1,
                h: 1
            });
        return {
            uid: e.uid,
            x: e.x,
            y: e.y,
            w: s.w,
            h: s.h
        };
    })
    // a Dwidget's own expanded size, when it asks for one (Quick configs: the Mixer's panel is taller than
    // the others'); uid → "WxH"
    property var wantedSizes: ({})
    function want(uid: string, size: string) {
        const w = Object.assign({}, wantedSizes);
        if (size)
            w[uid] = size;
        else
            delete w[uid];
        wantedSizes = w;
    }
    readonly property var expandedItem: {
        const e = placed.find(e => e.uid === expandedUid);
        const s = e ? DwidgetRegistry.parseSize(wantedSizes[e.uid] || DwidgetRegistry.expandedSize(e)) : null;
        return s ? {
            uid: e.uid,
            w: s.w,
            h: s.h
        } : null;
    }
    readonly property var solved: Layout.solve(items, expandedItem, mode)

    // an entry's turn in the entrance: reading order (rows, then columns)
    readonly property var ranks: {
        const r = solved.rects;
        const order = placed.map(e => e.uid).filter(u => r[u]).sort((a, b) => r[a].y - r[b].y || r[a].x - r[b].x);
        const ranks = {};
        order.forEach((u, i) => ranks[u] = i);
        return ranks;
    }
    function rank(uid: string): int {
        return ranks[uid] ?? 0;
    }

    function px(n: int): int {
        return n * (cell + gap);
    }

    function span(n: int): int {
        return n > 0 ? n * cell + (n - 1) * gap : 0;
    }

    implicitWidth: span(solved.cols)
    implicitHeight: span(solved.rows)

    // a click on the empty grid collapses the expanded entry
    MouseArea {
        anchors.fill: parent
        z: -1
        enabled: root.expandedUid !== ""
        onClicked: root.expandRequest(root.expandedUid, false)
    }

    Repeater {
        model: root.placed
        delegate: Cell {
            required property var modelData
            entry: modelData
            grid: root
        }
    }
}
