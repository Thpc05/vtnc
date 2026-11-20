import QtQuick
import "./styles/placeholder"

// The type: vtnc.not-built. A page that says, in the user's own language,
// that it hasn't been built yet.
Item {
    id: root

    property var widgetConfig: ({})

    readonly property string styleName: widgetConfig.style ?? "placeholder"
    readonly property string pageName: widgetConfig.pageName ?? ""

    Loader {
        anchors.fill: parent
        sourceComponent: {
            switch (root.styleName) {
            case "placeholder": return placeholderStyle;
            default: return placeholderStyle;
            }
        }
    }

    Component {
        id: placeholderStyle
        Placeholder { pageName: root.pageName }
    }
}
