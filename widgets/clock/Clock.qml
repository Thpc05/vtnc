import QtQuick
import "../../services"
import "./styles/digital"
import "./styles/compact"

// The type: vtnc.clock. Consumes the clock service (decision 5.2b) and
// wears one of two styles, chosen only by config (decision 3.1/3.5).
Item {
    id: root

    // Set by Page.qml's Loader once instantiated.
    property var widgetConfig: ({})

    readonly property string styleName: widgetConfig.style ?? "digital"
    readonly property string time: {
        const clock = ServiceRegistry.get("clock");
        return clock ? clock.time : "";
    }

    Component.onCompleted: ServiceRegistry.acquire("clock")
    Component.onDestruction: ServiceRegistry.release("clock")

    Loader {
        anchors.fill: parent
        sourceComponent: {
            switch (root.styleName) {
            case "compact": return compactStyle;
            default: return digitalStyle;
            }
        }
    }

    Component {
        id: digitalStyle
        Digital { time: root.time }
    }

    Component {
        id: compactStyle
        Compact { time: root.time }
    }
}
