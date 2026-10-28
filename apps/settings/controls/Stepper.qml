import QtQuick
import qs.components
import qs.theme
import qs.dwidgets.quick.panels
import qs.kit as K

// Number with − / + buttons. Scroll also changes it; click the number to type a value.
// `specialValueText`: shown instead of `from` (e.g. 0 = "Theme"); stepping up from it jumps to
// `firstValue`, stepping down from `firstValue` goes back to it.
Rectangle {
    id: root

    property real value: 0
    property real step: 1
    property real from: 0
    property real to: 100
    property int decimals: 0
    property string suffix: ""
    property string specialValueText: ""
    property real firstValue: from + step
    readonly property bool special: specialValueText !== "" && value === from
    // the unit as shown: "%" and "×" stick to the number, the others ("px", "ms") keep their space
    readonly property string unit: /^\s*[%×]$/.test(suffix) ? suffix.trim() : suffix
    // the apps' look (R1.5, 2026-10-17): the idle fill, strong text
    readonly property PanelColors c: PanelColors {
        look: K.Kit.appLook
    }

    signal edited(real value)

    function clamp(v: real): real {
        const r = Math.max(from, Math.min(to, v));
        return Number(r.toFixed(decimals));
    }

    function change(dir: int) {
        let v = clamp(value + dir * step);
        if (specialValueText !== "") {
            if (special && dir > 0)
                v = clamp(Math.max(firstValue, from + step));
            else if (dir < 0 && value <= firstValue)
                v = from;
        }
        if (v !== value)
            edited(v);
    }

    implicitWidth: 132
    implicitHeight: 30
    radius: height / 2
    color: c.off

    WheelHandler {
        onWheel: e => root.change(e.angleDelta.y > 0 ? 1 : -1)
    }

    IconButton {
        anchors.left: parent.left
        anchors.leftMargin: 4
        anchors.verticalCenter: parent.verticalCenter
        icon: Icons.minus
        size: 16
        color: root.c.strong
        active: root.value > root.from
        onClicked: root.change(-1)
    }

    TextInput {
        id: input
        anchors.centerIn: parent
        width: parent.width - 60
        horizontalAlignment: TextInput.AlignHCenter
        color: root.c.strong
        selectionColor: root.c.accent
        selectedTextColor: root.c.overAccent
        // numbers in Rubik, tabular (the shell's numbers; was the mono font)
        font.family: K.Kit.clockFamily
        font.pixelSize: Tokens.font.small
        font.weight: Font.Medium
        font.features: ({
                "tnum": 1
            })
        validator: DoubleValidator {}

        // show the formatted value unless the user is typing
        Binding on text {
            when: !input.activeFocus
            value: root.special ? root.specialValueText : root.value.toFixed(root.decimals) + root.unit
        }
        onActiveFocusChanged: {
            if (activeFocus) {
                text = root.value.toFixed(root.decimals);
                selectAll();
            }
        }
        onEditingFinished: {
            const v = parseFloat(text);
            // only real changes (losing focus must not write a stale value back)
            if (!isNaN(v) && root.clamp(v) !== root.value)
                root.edited(root.clamp(v));
            focus = false;
        }
    }

    IconButton {
        anchors.right: parent.right
        anchors.rightMargin: 4
        anchors.verticalCenter: parent.verticalCenter
        icon: Icons.plus
        size: 16
        color: root.c.strong
        active: root.value < root.to
        onClicked: root.change(1)
    }
}
