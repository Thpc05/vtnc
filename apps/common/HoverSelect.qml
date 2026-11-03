import QtQuick

// Hover-to-select for scrolling lists/grids. Selecting on `entered` is wrong there:
// when the view scrolls (keyboard navigation), items slide under a still cursor and
// steal the selection. This only reports a hover when the cursor actually moved
// in screen coordinates.
//
//   HoverSelect { id: hover }
//   MouseArea { hoverEnabled: true; onPositionChanged: m => hover.moved(this, m, () => list.currentIndex = index) }
QtObject {
    property point last: Qt.point(NaN, NaN)

    function moved(item: Item, mouse: var, select: var) {
        const g = item.mapToGlobal(mouse.x, mouse.y);
        const first = isNaN(last.x);
        const same = g.x === last.x && g.y === last.y;
        last = g;
        if (!first && !same)
            select();
    }

    function reset() {
        last = Qt.point(NaN, NaN);
    }
}
