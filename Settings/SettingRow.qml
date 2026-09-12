import QtQuick
import "../Config"
import "../Ui"

// ═══════════════════════════════════════════
//  SETTING ROW — The base of every settings row: label on the left,
//  control on the right, optional hint underneath.
//
//  It does not know how to edit anything: the concrete controls
//  (SettingSlider, SettingToggle, …) inherit from this and fill in
//  `control`.
//
//  REVERT: a row whose value differs from the factory default grows a
//  small accent arrow to the LEFT of the label. It only appears when
//  there is something to revert — a button that is always there says
//  nothing, and a settings screen full of arrows is noise.
//
//  Not every row wants it. Colors are the clear case: with matugen on,
//  the palette follows the wallpaper, so every color would sit
//  permanently "changed" and the arrow would be lit forever without
//  meaning anything. Those rows set `revertable: false` — they still
//  have defaults (that is what seeds a fresh machine), they just do
//  not advertise the difference.
// ═══════════════════════════════════════════
Item {
    id: root

    property string label: ""
    // Thin line under the label, for what is not obvious
    property string hint: ""
    // Control declared by the concrete child, pinned right
    default property alias control: controlHost.data
    // How much width the control takes (the label gets the rest)
    property real controlWidth: 160

    // ── BINDING ──
    // Three things instead of four handlers per row: where to write
    // (`store`, e.g. Theme.data), which field (`key`), and where the
    // factory value lives (`defaults`, e.g. Defaults.theme).
    //
    // Reading stays EXPLICIT in each row (`value: Theme.radiusIsland`)
    // because a dynamic key lookup is not reactive — QML cannot know
    // which property changed. Writing can be generic, and is.
    property var store: null
    property string key: ""
    property var defaults: null

    // The value being shown — each concrete control binds this to its
    // own (`currentValue: value`). It is what `changed` compares
    property var currentValue: undefined
    // Rows whose value legitimately drifts (colors) opt out
    property bool revertable: true

    readonly property var defaultValue:
        (defaults && key !== "") ? defaults[key] : undefined

    readonly property bool changed:
        revertable
        && defaultValue !== undefined
        && currentValue !== undefined
        && currentValue !== defaultValue

    // Every control writes through here
    function apply(v) {
        if (store && key !== "")
            store[key] = v
    }

    function revert() {
        if (defaultValue !== undefined)
            apply(defaultValue)
    }

    width: parent ? parent.width : 0
    implicitHeight: Math.max(36, labelCol.implicitHeight + 16)

    // The arrow lives in a fixed-width gutter that is always reserved,
    // even when empty: letting it push the label sideways would make
    // the whole column jump every time a value returns to default
    Item {
        id: calha

        anchors.left: parent.left
        anchors.verticalCenter: parent.verticalCenter
        width: 18
        height: 18

        Hoverable {
            id: btRevert

            anchors.fill: parent
            visible: root.changed
            onTapped: root.revert()

            Text {
                anchors.centerIn: parent
                text: "󰦛"
                color: Theme.accent
                font { family: Theme.fontIcon; pixelSize: 12 }
                opacity: btRevert.hovered ? 1 : 0.75
                Behavior on opacity { Smooth { duration: Motion.instant } }
            }
        }
    }

    Column {
        id: labelCol

        anchors.left: calha.right
        anchors.leftMargin: 4
        anchors.verticalCenter: parent.verticalCenter
        anchors.right: controlHost.left
        anchors.rightMargin: 16
        spacing: 2

        Text {
            width: parent.width
            text: root.label
            color: Theme.textPrimary
            elide: Text.ElideRight
            font { family: Theme.fontDisplay; pixelSize: 13 }
        }

        Text {
            width: parent.width
            visible: root.hint !== ""
            text: root.hint
            color: Theme.textMuted
            wrapMode: Text.WordWrap
            font { family: Theme.fontDisplay; pixelSize: 11 }
        }
    }

    Item {
        id: controlHost

        anchors.right: parent.right
        anchors.verticalCenter: parent.verticalCenter
        width: root.controlWidth
        height: parent.height
    }
}
