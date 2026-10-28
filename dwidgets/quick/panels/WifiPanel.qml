import QtQuick
import qs.services
import qs.kit as K

// Wi-Fi (2026-10-16, the "hero" panel): the connected network on top (its strength, name and state;
// Disconnect, and the login page when the connection is limited), then the other networks by strength
// under "Networks" (rescan at its end). A click opens a row: Connect, and the password field when the
// network asks for one.
Item {
    id: root

    // the look of the Dwidget that opened the panel (look.panel)
    property var look: null
    // its Qwidget (the hero toggles it)
    property QtObject qwidget: null
    // the open row (its bssid: a hidden network's ssid is "", which matched "nothing open")
    property string openKey: ""

    readonly property PanelColors c: PanelColors {
        look: root.look
    }
    readonly property var networks: NetworkService.wifiEnabled ? NetworkService.friendlyWifiNetworks : []
    readonly property var connected: networks.find(n => n.active) ?? null
    readonly property var others: networks.filter(n => !n.active)

    function strengthIcon(s) {
        return s >= 75 ? "signal_wifi_4_bar" : s >= 50 ? "network_wifi_3_bar" : s >= 25 ? "network_wifi_2_bar" : "network_wifi_1_bar";
    }

    Component.onCompleted: if (NetworkService.wifiEnabled)
        NetworkService.rescanWifi()

    // a row open: the hero compact (no actions), so the open row fits under it
    PanelHero {
        id: hero
        width: parent.width
        look: root.look
        qwidget: root.qwidget
        markSize: root.openKey !== "" ? 32 : 44
        active: root.connected !== null
        symbol: !NetworkService.wifiEnabled ? "wifi_off" : root.connected ? root.strengthIcon(root.connected.strength) : "signal_wifi_0_bar"
        title: !NetworkService.wifiEnabled ? "Off" : root.connected ? (root.connected.ssid || "Hidden network") : NetworkService.wifiConnecting ? "Connecting…" : "Disconnected"
        subtitle: !NetworkService.wifiEnabled ? "Wi-Fi" : root.connected ? (NetworkService.wifiStatus === "limited" ? "Limited" : "Connected") : "Pick one below"
        actions: {
            if (!root.connected || root.openKey !== "")
                return [];
            const out = [
                {
                    text: "Disconnect",
                    icon: "link_off",
                    primary: true,
                    run: () => NetworkService.disconnectWifiNetwork()
                }
            ];
            if (NetworkService.wifiStatus === "limited")
                out.push({
                    icon: "public",
                    iconOnly: true,
                    run: () => NetworkService.openPublicWifiPortal()
                });
            return out;
        }
    }

    PanelSection {
        id: section
        anchors.top: hero.bottom
        anchors.topMargin: 8
        width: parent.width
        visible: NetworkService.wifiEnabled
        look: root.look
        text: "Networks"
        actionIcon: "refresh"
        busy: NetworkService.wifiScanning
        onAction: NetworkService.rescanWifi()
    }

    ListView {
        id: list
        anchors.top: section.bottom
        anchors.bottom: parent.bottom
        width: parent.width
        visible: NetworkService.wifiEnabled
        clip: true
        spacing: 0
        boundsBehavior: Flickable.StopAtBounds
        model: root.others

        delegate: PanelRow {
            id: row

            required property var modelData
            required property int index
            readonly property var network: modelData
            readonly property bool connecting: NetworkService.wifiConnecting && NetworkService.wifiConnectTarget === network

            width: ListView.view.width
            look: root.look
            position: index
            count: ListView.view.count
            open: root.openKey !== "" && root.openKey === network.bssid
            icon: root.strengthIcon(network.strength)
            title: network.ssid || "Hidden network"
            subtitle: connecting ? "Connecting…" : ""
            onClicked: root.openKey = open ? "" : network.bssid
            onGrown: ListView.view.positionViewAtIndex(index, ListView.Contain)
            trailing: [
                K.MaterialIcon {
                    visible: row.network.isSecure
                    text: "lock"
                    size: 13
                    color: row.weak
                }
            ]

            PasswordField {
                width: parent.width
                look: root.look
                visible: row.network.askingPassword
                onVisibleChanged: if (visible)
                    focusInput()
                onAccepted: text => NetworkService.changePassword(row.network, text)
            }
            ActionGroup {
                width: parent.width
                look: root.look
                actions: [
                    {
                        text: row.connecting ? "Connecting…" : "Connect",
                        icon: "link",
                        primary: true,
                        enabled: !row.connecting,
                        run: () => NetworkService.connectToWifiNetwork(row.network)
                    }
                ]
            }
        }

        K.StyledText {
            anchors.centerIn: parent
            visible: list.count === 0
            text: NetworkService.wifiScanning ? "Scanning…" : "No other networks"
            font.family: K.Kit.family
            font.pixelSize: 12
            color: root.c.weak
        }
    }
}
