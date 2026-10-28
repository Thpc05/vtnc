pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Services.UPower
import qs.theme

Singleton {
    id: root

    readonly property UPowerDevice device: UPower.displayDevice

    readonly property bool available: device !== null && device.isLaptopBattery
    readonly property real percentage: available ? device.percentage * 100 : 0
    readonly property bool charging: available && device.state === UPowerDeviceState.Charging
    readonly property bool pluggedIn: available && (device.state === UPowerDeviceState.Charging || device.state === UPowerDeviceState.FullyCharged || device.state === UPowerDeviceState.PendingCharge)
    readonly property bool low: available && !pluggedIn && percentage <= 20

    readonly property string timeToEmpty: available && device.timeToEmpty > 0 ? formatTime(device.timeToEmpty) : ""
    readonly property string timeToFull: available && device.timeToFull > 0 ? formatTime(device.timeToFull) : ""

    readonly property string icon: {
        if (!available)
            return Icons.batteryEmpty;
        // the bolt whenever the charger is in (charging, full or held at a charge limit)
        if (pluggedIn)
            return Icons.batteryCharging;
        if (percentage > 75)
            return Icons.batteryFull;
        if (percentage > 50)
            return Icons.batteryHigh;
        if (percentage > 25)
            return Icons.batteryMedium;
        if (percentage > 5)
            return Icons.batteryLow;
        return Icons.batteryEmpty;
    }

    function formatTime(seconds: real): string {
        const h = Math.floor(seconds / 3600);
        const m = Math.floor((seconds % 3600) / 60);
        return h > 0 ? `${h}h ${m}m` : `${m}m`;
    }
}
