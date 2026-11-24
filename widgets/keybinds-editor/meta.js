// The Settings Keybinds page's one widget (0.507): consent (decision
// 10.3b) plus the keybind list itself (decision 7.5). Reads core/Config.qml,
// writes only through core/CliRunner.qml (decision 6.3's exception), same
// boundary as every other Settings control.
export default {
    type: "vtnc.keybinds-editor",
    title: "Keybinds editor",
    services: [],
    styles: ["panel"],
};
