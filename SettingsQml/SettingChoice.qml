import QtQuick
import "../ConfigValues"
import "../Ui"

// ═══════════════════════════════════════════
//  SETTING CHOICE — One of N, as pills. Exactly one is ever active.
//
//  Replaces the free text fields that used to hold these values. A
//  text field for a closed set is the worst of both worlds: it does
//  not tell you what the options are, and it happily accepts a typo
//  that silently breaks the feature — `scheme-vibrnat` would just make
//  matugen fail with nothing on screen to explain it.
//
//  The pills WRAP (Flow) instead of scrolling sideways: the transition
//  list has fourteen entries, and a row you have to scroll to read is
//  no better than the text field it replaced.
//
//  Layout is deliberately full width, below the label — unlike the
//  other controls, which sit to the right. Fourteen pills squeezed
//  into a 160px column would be unreadable.
// ═══════════════════════════════════════════
Item {
    id: root

    property string label: ""
    property string hint: ""
    // The options. Strings, matching exactly what the backend expects
    property var options: []
    property string value: ""

    // Same wiring as SettingRow — see the comment there
    property var store: null
    property string key: ""
    property var defaults: null
    property bool revertable: true

    readonly property var defaultValue:
        (defaults && key !== "") ? defaults[key] : undefined

    readonly property bool changed:
        revertable && defaultValue !== undefined && value !== defaultValue

    function apply(v) {
        if (store && key !== "")
            store[key] = v
    }

    function revert() {
        if (defaultValue !== undefined)
            apply(defaultValue)
    }

    width: parent ? parent.width : 0
    implicitHeight: cabecalho.implicitHeight + 6 + pilulas.implicitHeight + 12

    Item {
        id: calha

        anchors.left: parent.left
        anchors.top: parent.top
        anchors.topMargin: 6
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
        id: cabecalho

        anchors.left: calha.right
        anchors.leftMargin: 4
        anchors.right: parent.right
        anchors.top: parent.top
        anchors.topMargin: 4
        spacing: 2

        Text {
            width: parent.width
            text: root.label
            color: Theme.textPrimary
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

    Flow {
        id: pilulas

        anchors.left: cabecalho.left
        anchors.right: parent.right
        anchors.top: cabecalho.bottom
        anchors.topMargin: 6
        spacing: 5

        Repeater {
            model: root.options

            Hoverable {
                id: pilula

                required property var modelData

                readonly property bool ativa: root.value === modelData

                width: rotulo.implicitWidth + 18
                height: 26
                radius: height / 2
                onTapped: root.apply(modelData)

                // The active pill is a filled background UNDER the
                // hover layer, so pointing at the already-selected one
                // still gives feedback instead of going mute
                Rectangle {
                    anchors.fill: parent
                    z: -1
                    radius: parent.radius
                    color: pilula.ativa ? Theme.accent : Qt.rgba(1, 1, 1, 0.06)
                    Behavior on color { ColorAnimation { duration: Motion.instant } }
                }

                Text {
                    id: rotulo

                    anchors.centerIn: parent
                    text: pilula.modelData
                    color: pilula.ativa ? Theme.bg
                         : (pilula.hovered ? Theme.textPrimary : Theme.textSecondary)
                    font {
                        family: Theme.fontDisplay
                        pixelSize: 11
                        weight: pilula.ativa ? 600 : 400
                    }
                    Behavior on color { ColorAnimation { duration: Motion.instant } }
                }
            }
        }
    }
}
