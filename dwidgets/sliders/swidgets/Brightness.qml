import QtQuick
import qs.services
import ".."

// The focused screen's monitor (else the first), or all of them while synced; the icon toggles sync
// (filled = synced).
Swidget {
    readonly property var monitor: {
        const list = Brightness.monitors;
        const focused = AxctlService.focusedMonitor?.name ?? "";
        return list.find(m => m && m.screen && m.screen.name === focused) ?? list[0] ?? null;
    }

    value: monitor?.brightness ?? 0
    ready: monitor?.ready ?? false
    symbol: "light_mode"
    iconFill: Brightness.syncBrightness ? 1 : 0

    function set(v) {
        if (Brightness.syncBrightness)
            Brightness.monitors.forEach(m => m?.ready && m.setBrightness(v));
        else if (monitor?.ready)
            monitor.setBrightness(v);
    }
    function iconClicked() {
        Brightness.syncBrightness = !Brightness.syncBrightness;
        // turning sync on evens the monitors out at this one's level
        if (Brightness.syncBrightness && monitor?.ready)
            set(monitor.brightness);
    }
}
