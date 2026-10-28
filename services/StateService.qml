pragma Singleton

import QtQuick
import Quickshell
import qs.core

// Compat StateService (a key/value store):
// values live in ~/.local/state/vtnc/state.json under apps.state.
Singleton {
    id: root

    readonly property bool initialized: Store.ready
    signal stateLoaded

    onInitializedChanged: if (initialized)
        stateLoaded()

    function get(key, defaultValue) {
        return Store.appGet("state", key, defaultValue);
    }

    function set(key, value) {
        Store.appSet("state", key, value);
    }
}
