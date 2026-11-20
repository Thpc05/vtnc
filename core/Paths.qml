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
}
