import QtQuick
import qs.services
import qs.kit as K

// Bluetooth (2026-10-16, the "hero" panel): the connected device on top (its name, state and battery;
// Disconnect / Forget), then the others (paired first) under "Devices", with discovery at its end
// (it also runs while the panel is open). A click opens a row: Connect, Pair or Forget.
Item {
    id: root

    // the look of the Dwidget that opened the panel (look.panel)
    property var look: null
    // its Qwidget (the hero toggles it)
    property QtObject qwidget: null
    // the open row (address)
    property string openAddress: ""

    readonly property PanelColors c: PanelColors {
        look: root.look
    }
    readonly property var devices: BluetoothService.enabled ? BluetoothService.friendlyDeviceList : []
    readonly property var connected: devices.find(d => d?.connected) ?? null
    readonly property var others: devices.filter(d => d !== connected)

    Component.onCompleted: {
        BluetoothService.initialize();
        if (BluetoothService.enabled) {
            BluetoothService.updateDevices();
            BluetoothService.startDiscovery();
        }
    }
    Component.onDestruction: BluetoothService.stopDiscovery()

    // a row open: the hero compact (no actions), so the open row fits under it
    PanelHero {
        id: hero
        width: parent.width
        look: root.look
        qwidget: root.qwidget
        markSize: root.openAddress !== "" ? 32 : 44
        active: root.connected !== null
        symbol: !BluetoothService.enabled ? "bluetooth_disabled" : root.connected ? "bluetooth_connected" : "bluetooth"
        title: !BluetoothService.enabled ? "Off" : root.connected ? root.connected.name : "No device"
        subtitle: !BluetoothService.enabled ? "Bluetooth" : root.connected ? (root.connected.batteryAvailable ? root.connected.battery + "% · connected" : "Connected") : "Pick one below"
        actions: root.connected && root.openAddress === "" ? [
            {
                text: "Disconnect",
                icon: "link_off",
                primary: true,
                run: () => root.connected.disconnect()
            },
            {
                icon: "delete",
                iconOnly: true,
                run: () => root.connected.forget()
            }
        ] : []
    }

    PanelSection {
        id: section
        anchors.top: hero.bottom
        anchors.topMargin: 8
        width: parent.width
        visible: BluetoothService.enabled
        look: root.look
        text: "Devices"
        actionIcon: "refresh"
        busy: BluetoothService.discovering
        onAction: BluetoothService.startDiscovery()
    }

    ListView {
        id: list
        anchors.top: section.bottom
        anchors.bottom: parent.bottom
        width: parent.width
        visible: BluetoothService.enabled
        clip: true
        spacing: 0
        boundsBehavior: Flickable.StopAtBounds
        model: root.others

        delegate: PanelRow {
            id: row

            required property var modelData
            required property int index
            // null for a moment when a device goes away (its object is destroyed before the row)
            readonly property var device: modelData

            width: ListView.view.width
            look: root.look
            current: device?.connected ?? false
            open: !!device && root.openAddress === device.address
            icon: device?.connected ? "bluetooth_connected" : "bluetooth"
            title: device?.name ?? ""
            subtitle: device?.connecting ? "Connecting…" : (device?.connected ? "Connected" : (device?.paired ? "" : "New"))
            onClicked: root.openAddress = open ? "" : (device?.address ?? "")
            onGrown: ListView.view.positionViewAtIndex(index, ListView.Contain)
            trailing: [
                K.StyledText {
                    visible: row.device?.batteryAvailable ?? false
                    text: (row.device?.battery ?? 0) + "%"
                    font.family: K.Kit.family
                    font.pixelSize: 11
                    color: row.weak
                }
            ]

            ActionGroup {
                width: parent.width
                look: root.look
                actions: {
                    const d = row.device;
                    if (!d)
                        return [];
                    const out = [
                        {
                            text: d.connected ? "Disconnect" : "Connect",
                            icon: d.connected ? "link_off" : "link",
                            primary: true,
                            run: () => d.connected ? d.disconnect() : d.connect()
                        }
                    ];
                    out.push(d.paired ? {
                        icon: "delete",
                        iconOnly: true,
                        run: () => {
                            root.openAddress = "";
                            d.forget();
                        }
                    } : {
                        text: "Pair",
                        icon: "add_link",
                        run: () => d.pair()
                    });
                    return out;
                }
            }
        }

        K.StyledText {
            anchors.centerIn: parent
            visible: list.count === 0
            text: BluetoothService.discovering ? "Searching…" : "No other devices"
            font.family: K.Kit.family
            font.pixelSize: 12
            color: root.c.weak
        }
    }
}
