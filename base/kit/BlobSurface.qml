import QtQuick

// The shell's liquid surface (stage 8, 2026-10-11; our own shader, after caelestia's merged SDF
// boxes): the screen frame (`frameThickness` px with `frameRounding` inner corners; 0 / 0 still
// counts: the screen's edge, for the shapes to merge into) and up to four K.Blob shapes, each
// flowing into what's before it with its `smoothing` radius (shaders/blob.frag). Filled with `color`, the
// frame with `frameColor`.
ShaderEffect {
    id: root

    property color color: "black"
    // the frame's colour (blended into `color` across the merge)
    property color frameColor: color
    property bool frame: true
    property real frameThickness: 0
    property real frameRounding: 0
    property list<QtObject> blobs

    // the uniforms (blob.frag)
    readonly property vector2d itemSize: Qt.vector2d(width, height)
    readonly property vector4d frameInner: frame ? Qt.vector4d(width / 2, height / 2, Math.max(0, width / 2 - frameThickness), Math.max(0, height / 2 - frameThickness)) : Qt.vector4d(0, 0, -1, -1)
    readonly property real frameRadius: frameRounding

    function box(b: QtObject): vector4d {
        return b && b.shown ? Qt.vector4d(b.x + b.width / 2, b.y + b.height / 2, b.width / 2, b.height / 2) : Qt.vector4d(0, 0, -1, -1);
    }
    function radii(b: QtObject): vector4d {
        return b ? Qt.vector4d(b.topLeftRadius, b.topRightRadius, b.bottomRightRadius, b.bottomLeftRadius) : Qt.vector4d(0, 0, 0, 0);
    }

    readonly property vector4d box0: box(blobs[0] ?? null)
    readonly property vector4d radii0: radii(blobs[0] ?? null)
    readonly property real smooth0: blobs[0]?.smoothing ?? 0
    readonly property vector4d box1: box(blobs[1] ?? null)
    readonly property vector4d radii1: radii(blobs[1] ?? null)
    readonly property real smooth1: blobs[1]?.smoothing ?? 0
    readonly property vector4d box2: box(blobs[2] ?? null)
    readonly property vector4d radii2: radii(blobs[2] ?? null)
    readonly property real smooth2: blobs[2]?.smoothing ?? 0
    readonly property vector4d box3: box(blobs[3] ?? null)
    readonly property vector4d radii3: radii(blobs[3] ?? null)
    readonly property real smooth3: blobs[3]?.smoothing ?? 0

    // the version busts the shader cache (Qt keeps a loaded shader by its URL for the whole process: a
    // reload kept the old one); bump it whenever blob.frag changes
    fragmentShader: Qt.resolvedUrl("shaders/blob.frag.qsb") + "?v=3"
}
