import QtQuick
import Quickshell
import qs.core
import qs.components
import qs.theme
import qs.iwidgets
import qs.kit as K

// The real widget in one style (live: same component, same data), for a stage painted in the island's
// body colour: the preview has no shape of its own, only the widget's width and clip.
// Hosts it in an IwidgetFrame, as island/WidgetSlot does (card variants included): the width follows the content on the slot's curve, `fillsSlot` widgets get
// the animated width, and a widget fading out to hidden keeps its last look.
// Hidden, or a widget with nothing to show right now (media without a player…), shows a note.
Rectangle {
    id: root

    required property string widgetId
    required property string style
    // the island mode this preview shows (widgets with per-mode options)
    property string mode: "compact"

    readonly property bool hidden: style === WidgetRegistry.hidden
    // the look being rendered: the last visible style while fading out to hidden
    property string shownStyle: WidgetRegistry.defaultStyle(widgetId, "compact")
    Component.onCompleted: {
        if (!hidden)
            shownStyle = style;
        contentWidth = targetContentWidth;
    }
    // compares `style` itself: the `hidden` binding may not have caught up yet when this runs (leaving
    // Hidden for a style other than the first showed the first one)
    onStyleChanged: if (style !== WidgetRegistry.hidden)
        shownStyle = style
    // another widget (the settings page reuses the preview): start from its own look
    onWidgetIdChanged: shownStyle = style === WidgetRegistry.hidden ? WidgetRegistry.defaultStyle(widgetId, "compact") : style

    readonly property Item widget: frame.widget
    readonly property real widgetWidth: frame.targetWidth
    readonly property bool empty: !hidden && widget !== null && widgetWidth <= 0.5
    readonly property bool showsNote: hidden || empty
    readonly property real padding: 12

    readonly property real targetContentWidth: showsNote ? note.implicitWidth : widgetWidth
    property real contentWidth: 0
    // the slot's curve (island/WidgetSlot.qml: K.Anim DefaultSpatial); `growing` = this change's direction
    property bool growing: true
    onTargetContentWidthChanged: {
        if (!K.Kit.anim.enabled) {
            contentWidth = targetContentWidth;
            return;
        }
        growing = targetContentWidth > contentWidth;
        widthAnim.to = targetContentWidth;
        widthAnim.restart();
    }
    K.Anim {
        id: widthAnim
        target: root
        property: "contentWidth"
        type: K.Anim.DefaultSpatial
    }

    implicitWidth: contentWidth + 2 * padding
    implicitHeight: 36
    radius: height / 2
    color: "transparent" // the stage is the island body
    clip: true

    IwidgetFrame {
        id: frame
        // only a preview: no clicks, hovers or wheel reach the widget (it would toggle, seek, switch
        // workspaces…)
        enabled: false
        anchors.verticalCenter: parent.verticalCenter
        // x, not anchors switched by `fills`: for a moment both left and horizontalCenter were set and Qt
        // wrote the width, breaking its binding (after a widget that fills its slot, the next one was
        // laid out in the old width from the left and clipped)
        x: fills ? root.padding : Math.round((root.width - width) / 2)
        width: fills ? root.contentWidth : implicitWidth
        fillWidth: width
        widgetId: root.widgetId
        style: root.shownStyle
        mode: root.mode
        growing: root.growing
        screen: Quickshell.screens.find(s => s.name === Runtime.activeScreen) ?? null
        opacity: root.showsNote ? 0 : 1
        visible: opacity > 0
        Behavior on opacity {
            K.Anim {
                type: K.Anim.FastEffects
            }
        }
    }

    Row {
        id: note
        anchors.centerIn: parent
        spacing: Tokens.spacing.xs
        opacity: root.showsNote ? 1 : 0
        visible: opacity > 0
        Behavior on opacity {
            K.Anim {
                type: K.Anim.FastEffects
            }
        }

        Icon {
            anchors.verticalCenter: parent.verticalCenter
            visible: root.hidden
            icon: Icons.eyeSlash
            size: 14
            color: Colors.outline
        }
        StyledText {
            anchors.verticalCenter: parent.verticalCenter
            text: root.hidden ? "Hidden" : "Nothing to show right now"
            font.pixelSize: Tokens.font.small
            color: Colors.outline
        }
    }
}
