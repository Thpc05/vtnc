import QtQuick
import qs.theme
import qs.kit as K

// Scrollable settings page: a column of Sections.
// The mouse wheel scrolls `wheelStep` px per notch with a short smooth animation
// (Flickable's own wheel scrolling is slow for long pages); touchpads scroll 1:1.
Flickable {
    id: root

    default property alias content: column.data
    property real wheelStep: 200

    contentWidth: width
    contentHeight: column.implicitHeight + Tokens.spacing.m
    clip: true
    boundsBehavior: Flickable.StopAtBounds

    readonly property real maxY: Math.max(0, contentHeight - height)

    function scrollBy(dy: real, animate: bool) {
        const from = scrollAnim.running ? scrollAnim.to : contentY;
        const to = Math.max(0, Math.min(maxY, from + dy));
        scrollAnim.stop();
        if (animate) {
            scrollAnim.to = to;
            scrollAnim.start();
        } else {
            contentY = to;
        }
    }

    NumberAnimation {
        id: scrollAnim
        target: root
        property: "contentY"
        duration: 220
        easing.type: Easing.OutCubic
    }

    // controls with their own wheel handling (Stepper, Cycler) take the event first
    WheelHandler {
        acceptedDevices: PointerDevice.Mouse | PointerDevice.TouchPad
        onWheel: e => {
            if (e.pixelDelta.y !== 0)
                root.scrollBy(-e.pixelDelta.y, false);
            else
                root.scrollBy(-e.angleDelta.y / 120 * root.wheelStep, true);
        }
    }

    // the scroll indicator's gutter only on a page that scrolls (a short one reaches the header's edge)
    readonly property bool scrolls: column.implicitHeight + Tokens.spacing.m > height

    Column {
        id: column
        width: root.width - (root.scrolls ? Tokens.spacing.m : 0)
        spacing: Tokens.spacing.l
    }

    // thin scroll indicator
    Rectangle {
        visible: root.contentHeight > root.height
        x: root.width - 4
        y: root.contentY + root.visibleArea.yPosition * root.height
        width: 4
        height: root.visibleArea.heightRatio * root.height
        radius: 2
        color: Qt.alpha(K.Kit.appLook.panel.strong, 0.2)
    }
}
