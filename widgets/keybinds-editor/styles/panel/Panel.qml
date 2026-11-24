import QtQuick

// The only style for vtnc.keybinds-editor. Everything the type hands it is
// listed here (decision 3.5b): consent, the keybind list, and the
// functions that are the only way this ever changes anything. The first
// free-text input in the Settings UI (everything else so far is chips/
// steppers over a closed set) — a key combo, a command and a description
// are all open text, so this introduces TextInput, committed only on
// onEditingFinished to avoid spawning a CliRunner process per keystroke.
Rectangle {
    id: root

    required property bool consentGiven
    required property var keybinds
    required property var setConsent
    required property var addKeybind
    required property var removeKeybind
    required property var updateKeybind

    color: "#262626"
    border.color: "#3a3a3a"
    border.width: 1
    radius: 4

    component Chip: Rectangle {
        id: chip
        property string label
        property bool active
        signal activated

        width: label.length * 7 + 20
        height: 22
        radius: 11
        color: active ? "#3a6ea5" : "#3a3a3a"

        Text {
            anchors.centerIn: parent
            text: chip.label
            color: "white"
            font.pixelSize: 12
        }

        MouseArea {
            anchors.fill: parent
            onClicked: chip.activated()
        }
    }

    // Committed on Enter/Tab or losing focus, never on every keystroke —
    // the CLI is a real process per call, not a binding.
    component EditableField: Rectangle {
        id: field
        property alias text: input.text
        property string placeholder: ""
        signal committed(string value)

        color: "#1b1b1b"
        border.color: input.activeFocus ? "#3a6ea5" : "#3a3a3a"
        border.width: 1
        radius: 3

        TextInput {
            id: input
            anchors.fill: parent
            anchors.margins: 6
            verticalAlignment: TextInput.AlignVCenter
            color: "white"
            font.pixelSize: 12
            clip: true
            selectByMouse: true
            onEditingFinished: field.committed(text)
        }

        Text {
            anchors.fill: input
            visible: input.text.length === 0 && !input.activeFocus
            text: field.placeholder
            color: "#777777"
            font.pixelSize: 12
            verticalAlignment: Text.AlignVCenter
        }
    }

    Column {
        anchors.fill: parent
        anchors.margins: 10
        spacing: 8

        Row {
            spacing: 8
            Text {
                text: "Hyprland integration:"
                color: "#cccccc"
                font.pixelSize: 12
                anchors.verticalCenter: parent.verticalCenter
            }
            Chip {
                label: root.consentGiven ? "on" : "off"
                active: root.consentGiven
                onActivated: root.setConsent(!root.consentGiven)
            }
            Text {
                text: root.consentGiven
                    ? "vtnc writes ~/.config/hypr/vtnc and reloads Hyprland on every change."
                    : "nothing is written to disk until this is on."
                color: "#999999"
                font.pixelSize: 11
                anchors.verticalCenter: parent.verticalCenter
            }
        }

        // vtnc owns only its own folder (decisions 7.2/10.3b), so it never
        // edits hyprland.lua — the one line that pulls the generated file in
        // is the user's to add, and without it everything here looks like it
        // worked while no shortcut actually binds. It names vtnc's own
        // init.lua, not a particular file, so later steps can add generated
        // files behind it without the user touching hyprland.lua again
        // (decision 7.6). Put it BELOW your own config: a Lua error aborts
        // the config from that point down and keeps everything already
        // applied, so a vtnc failure can then never cost you your own binds.
        // The pcall only keeps Hyprland quiet when the file isn't there yet.
        Text {
            text: "Add this line at the END of your hyprland.lua once, or nothing below takes effect:"
            color: "#999999"
            font.pixelSize: 11
        }

        Text {
            text: "pcall(require, \"vtnc\")"
            color: "#cccccc"
            font.pixelSize: 12
            font.family: "monospace"
        }

        Row {
            spacing: 8
            width: parent.width
            Text { text: "key"; color: "#999999"; font.pixelSize: 11; width: 110 }
            Text { text: "commands (; separated)"; color: "#999999"; font.pixelSize: 11; width: 180 }
            Text { text: "description"; color: "#999999"; font.pixelSize: 11; width: 110 }
        }

        Repeater {
            model: root.keybinds

            delegate: Row {
                id: keybindRow
                required property var modelData
                required property int index

                spacing: 8

                EditableField {
                    width: 110; height: 28
                    placeholder: "SUPER + Q"
                    text: keybindRow.modelData.key ?? ""
                    onCommitted: (value) => root.updateKeybind(keybindRow.index, { key: value })
                }

                EditableField {
                    width: 180; height: 28
                    placeholder: "command one; command two"
                    text: (keybindRow.modelData.commands ?? []).join("; ")
                    onCommitted: (value) => root.updateKeybind(keybindRow.index, {
                        commands: value.split(";").map((c) => c.trim()).filter((c) => c.length > 0),
                    })
                }

                EditableField {
                    width: 110; height: 28
                    placeholder: "optional"
                    text: keybindRow.modelData.description ?? ""
                    onCommitted: (value) => root.updateKeybind(keybindRow.index, { description: value })
                }

                Chip {
                    label: (keybindRow.modelData.enabled ?? true) ? "on" : "off"
                    active: keybindRow.modelData.enabled ?? true
                    onActivated: root.updateKeybind(keybindRow.index, { enabled: !(keybindRow.modelData.enabled ?? true) })
                }

                Chip {
                    label: "remove"
                    active: false
                    onActivated: root.removeKeybind(keybindRow.index)
                }
            }
        }

        Chip {
            label: "+ add keybind"
            active: false
            onActivated: root.addKeybind()
        }
    }
}
