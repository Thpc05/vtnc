pragma Singleton

import QtQml
import Quickshell

// Where vtnc's own config/state live — separate from the quickshell source
// folder (Quickshell.configDir points at ~/.config/quickshell/<name>, which
// is the shell's code, not vtnc's user-facing config). VTNC_CONFIG_DIR and
// VTNC_STATE_DIR override these for the disposable test environment.
QtObject {
    readonly property string home: Quickshell.env("HOME")

    readonly property string configDir: {
        const override = Quickshell.env("VTNC_CONFIG_DIR");
        return override ? override : home + "/.config/vtnc";
    }

    readonly property string stateDir: {
        const override = Quickshell.env("VTNC_STATE_DIR");
        return override ? override : home + "/.local/state/vtnc";
    }

    readonly property string configFile: configDir + "/config.json"

    // Onde moram os plugins instalados (decisao do Theo em 2026-11-24).
    // Em ~/.local/share e nao em ~/.config porque plugin e codigo baixado,
    // nao configuracao escrita pelo usuario: quem versiona a propria
    // config nao leva codigo de terceiro junto.
    readonly property string pluginDir: {
        const override = Quickshell.env("VTNC_PLUGIN_DIR");
        if (override) return override;
        const dataHome = Quickshell.env("XDG_DATA_HOME");
        return (dataHome ? dataHome : home + "/.local/share") + "/vtnc/plugins";
    }
}
