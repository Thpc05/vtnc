import QtQuick
import "../../core"
import "../../core/widget-registry.mjs" as Registry

// The type: vtnc.keybinds-editor. The Settings Keybinds page (0.507,
// decision 10.3b): the consent toggle plus the list of keybinds
// themselves. Reads core/Config.qml directly and writes nothing itself —
// every edit becomes a CliRunner.run() call (decision 6.3's exception,
// same boundary as vtnc.island-editor/vtnc.autohide-settings). Nothing
// here ever touches ~/.config/hypr: that only happens once consent is on
// and the running shell's core/HyprlandSync.qml reacts to this config
// changing.
Item {
    id: root

    property var widgetConfig: ({})

    readonly property string styleName: widgetConfig.style ?? Registry.defaultStyleOf("vtnc.keybinds-editor")
    readonly property var hyprland: Config.data.hyprland ?? ({ enabled: false, keybinds: [] })
    readonly property bool consentGiven: hyprland.enabled ?? false
    readonly property var keybinds: hyprland.keybinds ?? []

    function setConsent(value) {
        CliRunner.run(["hyprland", "set", "enabled", value ? "true" : "false"]);
    }

    function writeKeybinds(nextKeybinds) {
        CliRunner.run(["hyprland", "set", "keybinds", JSON.stringify(nextKeybinds)]);
    }

    function addKeybind() {
        const next = root.keybinds.slice();
        next.push({ key: "", commands: [], enabled: true, description: "" });
        writeKeybinds(next);
    }

    function removeKeybind(index) {
        const next = root.keybinds.slice();
        next.splice(index, 1);
        writeKeybinds(next);
    }

    // `patch` only ever carries the fields that changed — commands arrives
    // here already split from the editor's single semicolon-joined field.
    // Object.assign, not { ...keybind, ...patch } (QML's JS engine rejects
    // object-spread syntax, unlike the .mjs modules core/config-shape.mjs
    // freely uses it in).
    function updateKeybind(index, patch) {
        const next = root.keybinds.map((keybind, i) => i === index ? Object.assign({}, keybind, patch) : keybind);
        writeKeybinds(next);
    }

    onStyleNameChanged: root.loadStyle()

    // Qt.binding, nao o valor cru: as propriedades iniciais do setSource sao
    // atribuicoes, entao um valor direto congelaria o style no primeiro
    // quadro. Tudo o que o type publica (meta.js, `provides`) viaja assim.
    function loadStyle() {
        styleLoader.setSource(Registry.resolvedStylePath("vtnc.keybinds-editor", root.styleName), {
            consentGiven: Qt.binding(() => root.consentGiven),
            keybinds: Qt.binding(() => root.keybinds),
            setConsent: Qt.binding(() => root.setConsent),
            addKeybind: Qt.binding(() => root.addKeybind),
            removeKeybind: Qt.binding(() => root.removeKeybind),
            updateKeybind: Qt.binding(() => root.updateKeybind)
        });
    }

    Loader {
        id: styleLoader
        anchors.fill: parent
        Component.onCompleted: root.loadStyle()
    }
}
