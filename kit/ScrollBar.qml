import QtQuick
import QtQuick.Templates as T
import qs.theme

// A thin pill scroll bar (caelestia's StyledScrollBar, ported): secondary, 4 px; shown while the
// flickable moves (0.6), on hover (0.8) or dragged (1), hidden 600 ms after it stops. A wheel
// over it steps by 10 %; press / drag jumps the view there. Its position animates, so the view
// glides.
// Use: `ScrollBar.vertical: K.ScrollBar { flickable: list }` (QtQuick.Controls' attached property).
T.ScrollBar {
    id: root

    required property Flickable flickable
    property bool shouldBeActive
    property real nonAnimPosition
    property bool animating
    property bool updatingFromFlickable: false
    property bool updatingFromUser: false

    readonly property bool isVertical: orientation === Qt.Vertical

    function contentLength(): real {
        return isVertical ? flickable.contentHeight : flickable.contentWidth;
    }
    function viewLength(): real {
        return isVertical ? flickable.height : flickable.width;
    }
    function syncFromFlickable(): void {
        const contentLen = contentLength();
        const len = viewLength();
        if (contentLen > len) {
            const pos = isVertical ? flickable.contentY : flickable.contentX;
            nonAnimPosition = Math.max(0, Math.min(1, pos / (contentLen - len)));
        } else {
            nonAnimPosition = 0;
        }
    }
    function updateFlickable(newPos: real): void {
        const contentLen = contentLength();
        const len = viewLength();
        if (contentLen <= len)
            return;
        const maxContentPos = contentLen - len;
        const maxPos = 1 - size;
        const contentPos = maxPos > 0 ? (newPos / maxPos) * maxContentPos : 0;
        const finalPos = Math.max(0, Math.min(maxContentPos, contentPos));
        if (isVertical)
            flickable.contentY = finalPos;
        else
            flickable.contentX = finalPos;
    }

    onHoveredChanged: shouldBeActive = hovered || flickable.moving

    // keep nonAnimPosition in step with Qt's own position binding
    onPositionChanged: {
        if (updatingFromUser) {
            updatingFromUser = false;
            return;
        }
        if (position === nonAnimPosition) {
            animating = false;
            return;
        }
        if (!animating && !updatingFromFlickable && !fullMouse.pressed)
            nonAnimPosition = position;
    }

    Component.onCompleted: if (flickable)
        syncFromFlickable()

    implicitWidth: isVertical ? Kit.padding.extraSmall : 0
    implicitHeight: isVertical ? 0 : Kit.padding.extraSmall

    contentItem: StyledRect {
        opacity: {
            if (root.size === 1)
                return 0;
            if (fullMouse.pressed)
                return 1;
            if (mouse.containsMouse)
                return 0.8;
            if (root.policy === T.ScrollBar.AlwaysOn || root.shouldBeActive)
                return 0.6;
            return 0;
        }
        radius: Kit.rounding.full
        color: Colors.secondary

        MouseArea {
            id: mouse

            anchors.fill: parent
            cursorShape: Qt.PointingHandCursor
            hoverEnabled: true
            acceptedButtons: Qt.NoButton
        }

        Behavior on opacity {
            Anim {
                type: Anim.DefaultEffects
            }
        }
    }

    Connections {
        target: root.flickable

        function onContentYChanged() {
            if (root.isVertical)
                update();
        }
        function onContentXChanged() {
            if (!root.isVertical)
                update();
        }
        function update() {
            if (root.animating || fullMouse.pressed)
                return;
            root.updatingFromFlickable = true;
            root.syncFromFlickable();
            root.updatingFromFlickable = false;
        }
        function onMovingChanged() {
            if (root.flickable.moving)
                root.shouldBeActive = true;
            else
                hideDelay.restart();
        }
    }

    Timer {
        id: hideDelay

        interval: 600
        onTriggered: root.shouldBeActive = root.flickable.moving || root.hovered
    }

    MouseArea {
        id: fullMouse

        property int accumulated: 0

        anchors.fill: parent
        preventStealing: true

        function jumpTo(evPos: real): void {
            root.updatingFromUser = true;
            const rLen = root.isVertical ? root.height : root.width;
            const newPos = Math.max(0, Math.min(1 - root.size, evPos / rLen - root.size / 2));
            root.nonAnimPosition = newPos;
            root.updateFlickable(newPos);
        }

        // a step per wheel notch (120)
        onWheel: e => {
            const delta = root.isVertical ? e.angleDelta.y : (e.angleDelta.x || e.angleDelta.y);
            if (Math.sign(delta) !== Math.sign(accumulated))
                accumulated = 0;
            accumulated += delta;
            if (Math.abs(accumulated) < 120)
                return;
            accumulated = 0;
            root.animating = true;
            root.updatingFromUser = true;
            const newPos = delta > 0 ? Math.max(0, root.nonAnimPosition - 0.1) : Math.min(1 - root.size, root.nonAnimPosition + 0.1);
            root.nonAnimPosition = newPos;
            root.updateFlickable(newPos);
        }
        onPressed: e => {
            root.animating = true;
            jumpTo(root.isVertical ? e.y : e.x);
        }
        onPositionChanged: e => jumpTo(root.isVertical ? e.y : e.x)
    }

    Behavior on position {
        enabled: !fullMouse.pressed

        Anim {}
    }
}
