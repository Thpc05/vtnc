import QtQuick
import qs.theme
import qs.kit as K

// Row of big icon buttons: each a bare icon (no card at rest, user), the current one (it follows the
// hover) in the apps' look (`look`, K.Kit.appStyle; 2026-10-17, as a Qwidget's "on" mark):
//  - shapes: an accent M3 shape, the workspaces Iwidget's focus shape (user): one shape that slides to
//    the current button and morphs to a random other on every move; a new one (no morph) each time the
//    app opens (`reshuffle()`); at rest the icon in overSurfaceVariant. A text button (the recording's
//    Stop) keeps the rounded pill
//  - tones: a rounded square in the tone (primary); at rest the icon in the weak tone
//  - tone: no fill ever: the icon in the tone, filled and heavier; at rest the weak tone
// "error" actions take the error colour for the tone. A state layer ripple; arrows/Tab move,
// Enter/Space trigger, hover selects. Below, a caption shows the current action's label.
//
// actions: [{ id, icon, label, text, variant: "primary" | "error", live, enabled }, { separator: true }, ...]
//  - text: shown next to the icon (wider button, like ActionGrid items with text)
//  - variant "error": red content even when not selected, red highlight when selected
//  - live: pulsing dot before the text (e.g. an ongoing recording)
FocusScope {
    id: root

    property var actions: []
    property int buttonSize: 48
    property int iconSize: 20
    property int spacing: Tokens.spacing.s
    property int separatorWidth: Tokens.spacing.m
    property bool showCaption: true
    property string look: K.Kit.appStyle
    readonly property bool weakRest: look !== "shapes"

    property int currentIndex: firstValid()

    signal triggered(var action)

    readonly property var current: actions[currentIndex] ?? null

    // the Shapes look's M3 shape (the workspaces Iwidget's set, iwidgets/workspaces/TonesStyle.qml)
    readonly property var shapes: ["cookie4", "cookie6", "cookie7", "cookie9", "cookie12", "sunny", "softBurst", "clover4", "clover8"]
    function pick(): string {
        const kinds = shapes.filter(k => k !== shape);
        return kinds[Math.floor(Math.random() * kinds.length)];
    }
    property string shape: ""
    Component.onCompleted: shape = pick()
    property bool instant: false
    function reshuffle() {
        instant = true;
        shape = pick();
        Qt.callLater(() => root.instant = false);
    }
    onCurrentIndexChanged: shape = pick()
    readonly property Item currentItem: repeater.count > 0 ? repeater.itemAt(currentIndex) : null

    function isValid(i: int): bool {
        const a = actions[i];
        return a !== undefined && !a.separator && a.enabled !== false;
    }

    function firstValid(): int {
        for (let i = 0; i < actions.length; i++)
            if (isValid(i))
                return i;
        return 0;
    }

    function step(dir: int) {
        const n = actions.length;
        let i = currentIndex;
        for (let k = 0; k < n; k++) {
            i = (i + dir + n) % n;
            if (isValid(i)) {
                currentIndex = i;
                return;
            }
        }
    }

    function trigger(i: int) {
        if (isValid(i))
            triggered(actions[i]);
    }

    implicitWidth: row.implicitWidth
    implicitHeight: row.implicitHeight + (showCaption ? caption.implicitHeight + Tokens.spacing.s : 0)

    Keys.onPressed: e => {
        if (e.key === Qt.Key_Right || e.key === Qt.Key_Tab || e.key === Qt.Key_Down)
            step(1);
        else if (e.key === Qt.Key_Left || e.key === Qt.Key_Backtab || e.key === Qt.Key_Up)
            step(-1);
        else if (e.key === Qt.Key_Return || e.key === Qt.Key_Enter || e.key === Qt.Key_Space)
            trigger(currentIndex);
        else
            return;
        e.accepted = true;
    }

    // Shapes: the current button's M3 shape, one for the row so it slides and morphs between them
    K.M3Shape {
        id: blob
        readonly property Item at: root.currentItem
        visible: root.look === "shapes" && at !== null && !at.hasText && !at.modelData.separator
        x: at ? at.x : 0
        width: root.buttonSize
        height: root.buttonSize
        samples: 60
        animate: !root.instant
        shape: root.shape || "cookie7"
        color: at && at.isError ? Colors.error : Colors.primary
        Behavior on x {
            enabled: !root.instant
            K.Anim {
                type: K.Anim.FastSpatial
            }
        }
        Behavior on color {
            K.CAnim {}
        }
    }

    Row {
        id: row
        spacing: root.spacing

        Repeater {
            id: repeater
            model: root.actions

            Item {
                id: button
                required property var modelData
                required property int index

                readonly property bool isCurrent: index === root.currentIndex
                readonly property bool enabled_: modelData.enabled !== false
                readonly property bool isError: modelData.variant === "error"
                readonly property bool hasText: (modelData.text ?? "") !== ""
                // the tone: primary, or error for the actions that end something
                readonly property color tone: isError ? Colors.error : Colors.primary
                readonly property color overTone: isError ? Colors.overError : Colors.overPrimary
                readonly property bool filled: isCurrent && root.look !== "tone"
                // Shapes: the row's M3 shape draws it (a text button keeps its own pill)
                readonly property bool ownFill: root.look !== "shapes" || hasText
                readonly property color fg: filled ? overTone : isCurrent ? tone : isError ? Colors.error : root.weakRest ? Qt.alpha(tone, K.Kit.expressive.light ? 0.85 : 0.62) : Colors.overSurfaceVariant

                width: modelData.separator ? root.separatorWidth - root.spacing : (hasText ? content.implicitWidth + 2 * Tokens.spacing.m : root.buttonSize)
                height: root.buttonSize
                opacity: enabled_ ? 1 : 0.4
                Behavior on width {
                    K.Anim {
                        type: K.Anim.FastSpatial
                    }
                }

                // the button: no card at rest (user); the current one filled in the look (Tone: never)
                Rectangle {
                    id: shape
                    anchors.fill: parent
                    visible: !button.modelData.separator
                    radius: root.look === "shapes" ? (mouse.pressed ? Math.round(height * 0.18) : button.isCurrent ? height / 2 : Math.round(height * 0.3)) : Math.round(height * 0.3)
                    color: button.filled && button.ownFill ? button.tone : Qt.alpha(button.tone, 0)

                    Behavior on radius {
                        K.Anim {
                            type: K.Anim.FastSpatial
                        }
                    }
                    Behavior on color {
                        K.CAnim {}
                    }
                }

                Row {
                    id: content
                    anchors.centerIn: parent
                    visible: !button.modelData.separator
                    spacing: Tokens.spacing.s
                    scale: mouse.pressed ? 0.92 : 1
                    Behavior on scale {
                        K.Anim {
                            type: K.Anim.FastSpatial
                        }
                    }

                    Rectangle {
                        id: liveDot
                        visible: button.modelData.live === true
                        anchors.verticalCenter: parent.verticalCenter
                        width: 8
                        height: 8
                        radius: 4
                        color: button.fg
                        SequentialAnimation on opacity {
                            running: liveDot.visible
                            loops: Animation.Infinite
                            NumberAnimation { to: 0.25; duration: 700; easing.type: Easing.InOutSine }
                            NumberAnimation { to: 1; duration: 700; easing.type: Easing.InOutSine }
                        }
                    }

                    StyledText {
                        visible: button.hasText
                        anchors.verticalCenter: parent.verticalCenter
                        // digits sit ~1.5 px high when the line box is centred (cap height)
                        anchors.verticalCenterOffset: 1
                        text: button.modelData.text ?? ""
                        color: button.fg
                        font.family: Tokens.font.family
                        // tabular digits: a running timer doesn't jiggle
                        font.features: ({
                                "tnum": 1
                            })
                        font.pixelSize: Tokens.font.normal
                        font.weight: Font.Bold
                        Behavior on color {
                            K.CAnim {}
                        }
                    }

                    Icon {
                        anchors.verticalCenter: parent.verticalCenter
                        icon: button.modelData.icon ?? ""
                        size: root.iconSize
                        fill: button.isCurrent ? 1 : 0
                        weight: button.isCurrent && root.look === "tone" ? 600 : 400
                        color: button.fg
                        Behavior on color {
                            K.CAnim {}
                        }
                    }
                }

                // Tone: no fill, so a dot under the current icon (a glyph without a filled form barely changes)
                Rectangle {
                    visible: root.look === "tone" && button.isCurrent && !button.modelData.separator
                    anchors.horizontalCenter: parent.horizontalCenter
                    anchors.bottom: parent.bottom
                    anchors.bottomMargin: 5
                    width: 4
                    height: 4
                    radius: 2
                    color: button.tone
                }

                K.StateLayer {
                    id: mouse
                    visible: !button.modelData.separator
                    disabled: !button.enabled_
                    radius: shape.radius
                    color: button.fg
                    // hover moves the selection, which already shows it: only the ripple
                    stateOpacity: 0
                    onEntered: root.currentIndex = button.index
                    onClicked: root.trigger(button.index)
                }
            }
        }
    }

    StyledText {
        id: caption
        visible: root.showCaption
        anchors.top: row.bottom
        anchors.topMargin: Tokens.spacing.s
        anchors.horizontalCenter: parent.horizontalCenter
        text: root.current?.label ?? ""
        color: root.weakRest ? (root.current?.variant === "error" ? Colors.error : Colors.primary) : Colors.overSurfaceVariant
        font.pixelSize: Tokens.font.small
        font.weight: Font.DemiBold
    }
}
