// The one global control the autohide step needs on the Settings Islands
// page: the trigger distance (decision 12.4 — global, never per-island,
// unlike autohide/autohideMode themselves, which are shown on each
// island's own vtnc.island-editor panel). Reads core/Config.qml, writes
// only through core/CliRunner.qml (decision 6.3's exception), same
// boundary as every other Settings control.
export default {
    type: "vtnc.autohide-settings",
    title: "Autohide settings",
    services: [],
    styles: ["panel"],
};
