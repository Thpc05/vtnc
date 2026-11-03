import QtQuick

// One shape of a K.BlobSurface (stage 8): a rounded box in the surface's coordinates, its four radii,
// the radius it merges into the shapes before it with (0 = a plain union). Hidden or empty = not drawn.
QtObject {
    property bool visible: true
    property real x: 0
    property real y: 0
    property real width: 0
    property real height: 0
    property real topLeftRadius: 0
    property real topRightRadius: 0
    property real bottomRightRadius: 0
    property real bottomLeftRadius: 0
    property real smoothing: 0

    readonly property bool shown: visible && width > 0 && height > 0
}
