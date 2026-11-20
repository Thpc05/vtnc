import QtQuick
import "./styles/default"

// The type: vtnc.square. A dumb widget — a square with text — that exists
// to prove the type/style split (decision 3.1/3.5) with the least possible
// code. No services: it names none because it needs none.
Item {
    id: root

    // Set by Page.qml's Loader once instantiated.
    property var widgetConfig: ({})

    readonly property string styleName: widgetConfig.style ?? "default"
    readonly property string text: widgetConfig.text ?? "square"

    Loader {
        anchors.fill: parent
        sourceComponent: {
            switch (root.styleName) {
            case "default": return defaultStyle;
            default: return defaultStyle;
            }
        }
    }

    Component {
        id: defaultStyle
        Default {
            text: root.text
        }
    }
}
