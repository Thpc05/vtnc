import QtQuick
import Quickshell.Services.UPower
import qs.theme
import ".."
import "../panels"

// power-profiles-daemon through Quickshell's UPower module
Qwidget {
    readonly property var profiles: [PowerProfile.PowerSaver, PowerProfile.Balanced, PowerProfile.Performance]

    function name(p) {
        return p === PowerProfile.PowerSaver ? "Power saver" : p === PowerProfile.Performance ? "Performance" : "Balanced";
    }

    function glyph(p) {
        return p === PowerProfile.PowerSaver ? Icons.leaf : p === PowerProfile.Performance ? Icons.lightning : Icons.gauge;
    }

    // a choice, not on / off: no switch (its panel picks)
    switchable: false
    title: "Power profile"
    symbol: PowerProfiles.profile === PowerProfile.PowerSaver ? "eco" : PowerProfiles.profile === PowerProfile.Performance ? "bolt" : "balance"
    icon: glyph(PowerProfiles.profile)
    active: PowerProfiles.profile !== PowerProfile.Balanced
    status: name(PowerProfiles.profile)
    panel: Component {
        PowerPanel {}
    }

    // saver → balanced → performance → saver (performance only when the hardware has it)
    function toggle() {
        const list = PowerProfiles.hasPerformanceProfile ? profiles : profiles.slice(0, 2);
        const i = list.indexOf(PowerProfiles.profile);
        PowerProfiles.profile = list[(i + 1) % list.length];
    }
}
