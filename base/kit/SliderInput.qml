import QtQuick

// The kit slider's input (M3Slider): a relative drag (from where it was), a tap on the
// track jumps there, the wheel steps 5 %, and a tap on `iconItem` emits `iconClicked` instead.
// Positions run along the track from `startOffset` over `span` px (bottom → top when `vertical`).
// `moved` fires on user input only.
MouseArea {
    id: input

    property bool vertical: false
    property real value: 0
    property real startOffset: 0
    property real span: 1
    property Item iconItem: null

    property bool dragging: false
    property real startPos
    property real startValue

    signal moved(real value)
    signal iconClicked

    cursorShape: Qt.PointingHandCursor
    preventStealing: true

    function along(m) {
        return vertical ? height - m.y : m.x;
    }
    function onIcon(m) {
        if (!iconItem || !iconItem.visible)
            return false;
        const p = iconItem.mapToItem(input, 0, 0);
        return m.x >= p.x && m.x <= p.x + iconItem.width && m.y >= p.y && m.y <= p.y + iconItem.height;
    }
    function clamp01(v) {
        return Math.max(0, Math.min(1, v));
    }

    onPressed: m => {
        dragging = false;
        startPos = along(m);
        startValue = value;
    }
    onPositionChanged: m => {
        const d = along(m) - startPos;
        if (!dragging && Math.abs(d) < 4)
            return;
        dragging = true;
        moved(clamp01(startValue + d / Math.max(1, span)));
    }
    onReleased: m => {
        if (dragging) {
            dragging = false;
            return;
        }
        if (onIcon(m))
            iconClicked();
        else
            moved(clamp01((along(m) - startOffset) / Math.max(1, span)));
    }
    onWheel: w => moved(clamp01(value + (w.angleDelta.y > 0 ? 0.05 : -0.05)))
}
