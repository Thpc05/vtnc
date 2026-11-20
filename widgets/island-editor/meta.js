// The Settings control for one island (decision 8.3 — the Settings page is
// made of real widgets, only not user-editable themselves). Every change
// goes out through core/CliRunner.qml to the real cli/vtnc binary; this
// type never touches core/Config.qml for writing, only for reading back
// the live state.
export default {
    type: "vtnc.island-editor",
    title: "Island editor",
    services: [],
    styles: ["panel"],
};
