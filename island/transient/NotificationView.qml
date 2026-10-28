import QtQuick
import QtQuick.Controls
import qs.core
import qs.theme
import qs.services
import qs.kit as K
import "../../dwidgets/quick" as DQ

// Notification transient (2026-10-15, vtnc's own; was ambxst's): the current popup's card
// (Notifications.popupList) and, with several, dots beside it; the wheel goes through them (the card
// slides up or down), a middle click dismisses, hovering expands it (or always: island.notifications
// .expand) and holds the timers. A new one comes to the front unless you're hovering one.
// NotificationPresenter decides when it shows and ends it when popupList is empty.
// island.notifications.presentation: "replace" (a transient page, the island becomes the card) or "grow"
// (Island hangs it under its idle content or app, as wide as the island: `fixedWidth`).
Item {
    id: root

    // transient page API (see Island.transientComponents)
    property var payload: ({})
    readonly property bool islandCentered: true
    readonly property bool islandRoomy: true
    // set by Island (the width limit depends on it)
    property var screen: null

    readonly property int padding: 14
    // the space above the card: under the island's content (grow) it's tighter
    property int topPadding: padding
    // grow: the island's width (the card fills it); 0 = as wide as the content (replace)
    property real fixedWidth: 0

    readonly property var popups: Notifications.popupList
    readonly property bool several: popups.length > 1
    property var current: null
    readonly property int currentIndex: Math.max(0, popups.indexOf(current))
    // the newest id seen (what's newer is a new arrival)
    property int newestSeen: 0

    // the card's tone (island.notifications.color, as the Quick configs')
    DQ.ToneColors {
        id: colors
        role: Store.island.notifications?.color || "primary"
    }

    // Width: replacing, the collapsed line's (lead, "summary  body", the dots' room) between
    // island.notifications.minWidth and .maxWidth, never past 90 % of the screen; growing, the island's
    // (Island widens a narrower island to `minIslandWidth`, the replacing width). Expanding never changes it.
    readonly property int dotsSpace: 16
    readonly property real minCardWidth: Store.island.notifications?.minWidth || 260
    readonly property real maxCardWidth: Math.max(minCardWidth, Math.min(Store.island.notifications?.maxWidth || 720, (screen?.width ?? 1920) * 0.9 - 2 * padding))
    readonly property real contentCardWidth: {
        if (!current)
            return minCardWidth;
        const text = summaryMetrics.advanceWidth + (current.body !== "" ? bodyMetrics.advanceWidth + 6 : 0);
        // lead + gap (NotificationCard), the dots' room (always kept, so it doesn't jump) and some slack
        // (the drawn text runs a bit wider than the metrics)
        return Math.ceil(32 + 10 + text + 8 + dotsSpace + 16);
    }
    readonly property real fitWidth: Math.max(minCardWidth, Math.min(maxCardWidth, contentCardWidth))
    readonly property real cardWidth: fixedWidth > 0 ? Math.max(0, fixedWidth - 2 * padding) : fitWidth
    readonly property real minIslandWidth: fitWidth + 2 * padding

    TextMetrics {
        id: summaryMetrics
        font.family: K.Kit.family
        font.variableAxes: K.Kit.axes
        font.pixelSize: 13
        font.weight: Font.Bold
        text: root.current?.summary ?? ""
    }
    TextMetrics {
        id: bodyMetrics
        font.family: K.Kit.family
        font.variableAxes: K.Kit.axes
        font.pixelSize: 13
        text: (root.current?.body ?? "").replace(/\n/g, " ")
    }

    implicitWidth: cardWidth + 2 * padding
    implicitHeight: stack.implicitHeight + topPadding + padding

    // Hover. It drops for a frame when a card is replaced or the window resizes, and each drop would swap
    // the layouts (and sizes) and feed itself: entering is at once, leaving waits a moment. Going through
    // them counts as hovering too.
    HoverHandler {
        id: hover
        onHoveredChanged: {
            if (hovered) {
                hoverLeave.stop();
                root.hoverHeld = true;
            } else {
                hoverLeave.restart();
            }
        }
    }
    property bool hoverHeld: false
    Timer {
        id: hoverLeave
        interval: 250
        onTriggered: root.hoverHeld = false
    }
    property bool browsing: false
    Timer {
        id: browseHold
        interval: K.Kit.anim.durations.expressiveDefaultSpatial + 50
        onTriggered: root.browsing = false
    }
    readonly property bool hovered: hoverHeld || browsing
    readonly property bool expanded: Store.island.notifications?.expand === "always" || hovered
    onHoveredChanged: hovered ? Notifications.pauseAllTimers() : Notifications.resumeAllTimers()

    // the card's time ("now", "5m"…), redrawn every minute
    property int minute: 0
    Timer {
        interval: 60000
        repeat: true
        running: root.visible && root.current !== null
        onTriggered: root.minute++
    }

    // which card shows ---------------------------------------------------------
    function show(n, transition) {
        if (stack.depth === 0)
            stack.push(cardComponent, {
                notification: n
            }, StackView.Immediate);
        else
            stack.replace(cardComponent, {
                notification: n
            }, transition);
        current = n;
    }

    function sync() {
        const list = popups;
        const newest = list.length > 0 ? list[list.length - 1] : null;
        if (!newest) {
            stack.clear(StackView.Immediate);
            current = null;
            return;
        }
        const arrived = newest.id > newestSeen;
        newestSeen = Math.max(newestSeen, newest.id);
        if (!current) {
            show(newest, StackView.Immediate);
        } else if (!list.includes(current)) {
            // the shown one went: the one now at its place comes up (the one before it, if it was the last)
            const old = stack.currentItem?.index ?? 0;
            const i = Math.min(old, list.length - 1);
            show(list[i], i < old ? StackView.PopTransition : StackView.PushTransition);
        } else if (arrived && !hovered && newest !== current) {
            show(newest, StackView.PushTransition);
        }
        if (stack.currentItem)
            stack.currentItem.index = list.indexOf(current);
    }

    function step(by) {
        if (!several)
            return;
        browsing = true;
        browseHold.restart();
        const i = (currentIndex + by + popups.length) % popups.length;
        show(popups[i], by > 0 ? StackView.PushTransition : StackView.PopTransition);
        stack.currentItem.index = i;
    }

    Connections {
        target: Notifications
        function onPopupListChanged() {
            root.sync();
        }
    }
    // (the card is kept while hidden: the island's page stack hides the page for a moment while it shows,
    // and a card made again each time restarted it)
    Component.onCompleted: sync()

    // the dismiss fly-off: the card slides half off to the right and fades, then it's discarded
    SequentialAnimation {
        id: flyOff
        property Item card: null
        property int nid: -1
        ParallelAnimation {
            K.Anim {
                target: flyOff.card
                property: "x"
                to: (flyOff.card?.width ?? 0) * 0.5
                type: K.Anim.FastSpatial
            }
            K.Anim {
                target: flyOff.card
                property: "opacity"
                to: 0
                type: K.Anim.FastEffects
            }
        }
        ScriptAction {
            script: Notifications.discardNotification(flyOff.nid)
        }
    }
    function dismiss(n) {
        if (!n || flyOff.running)
            return;
        const card = stack.currentItem;
        if (!K.Kit.anim.enabled || card?.notification !== n) {
            Notifications.discardNotification(n.id);
            return;
        }
        flyOff.card = card;
        flyOff.nid = n.id;
        flyOff.start();
    }

    // wheel: through them; middle click: dismiss (left clicks go to the card)
    MouseArea {
        anchors.fill: parent
        acceptedButtons: Qt.MiddleButton
        onWheel: w => root.step(w.angleDelta.y > 0 ? -1 : 1)
        onClicked: root.dismiss(root.current)
    }

    // the card and the dots are one group in the middle: with one notification the dots' room is split
    // around the card; when they appear the card slides left by half of it and they fade in
    Item {
        id: group
        x: root.padding
        y: root.topPadding
        width: root.cardWidth
        height: stack.implicitHeight

        property real cardX: root.several ? 0 : root.dotsSpace / 2
        Behavior on cardX {
            enabled: K.Kit.anim.enabled
            K.Anim {
                type: K.Anim.BodySpatial
            }
        }

        StackView {
            id: stack
            x: group.cardX
            width: group.width - root.dotsSpace
            implicitHeight: currentItem?.implicitHeight ?? 0
            height: implicitHeight
            clip: true

            // next: the new one comes up from below; previous: down from above
            pushEnter: Transition {
                K.Anim {
                    property: "y"
                    from: stack.height
                    to: 0
                    type: K.Anim.BodySpatial
                }
                K.Anim {
                    property: "opacity"
                    from: 0
                    to: 1
                    type: K.Anim.DefaultEffects
                }
            }
            pushExit: Transition {
                K.Anim {
                    property: "y"
                    from: 0
                    to: -stack.height
                    type: K.Anim.BodySpatial
                }
                K.Anim {
                    property: "opacity"
                    from: 1
                    to: 0
                    type: K.Anim.DefaultEffects
                }
            }
            popEnter: Transition {
                K.Anim {
                    property: "y"
                    from: -stack.height
                    to: 0
                    type: K.Anim.BodySpatial
                }
                K.Anim {
                    property: "opacity"
                    from: 0
                    to: 1
                    type: K.Anim.DefaultEffects
                }
            }
            popExit: Transition {
                K.Anim {
                    property: "y"
                    from: 0
                    to: stack.height
                    type: K.Anim.BodySpatial
                }
                K.Anim {
                    property: "opacity"
                    from: 1
                    to: 0
                    type: K.Anim.DefaultEffects
                }
            }
        }

        // the dots: one per popup, the current one full; at most three in view, scrolling with it
        Item {
            x: group.cardX + stack.width + 8
            width: 8
            height: 32
            y: Math.round((stack.height - height) / 2)
            opacity: root.several ? 1 : 0
            clip: true
            Behavior on opacity {
                enabled: K.Kit.anim.enabled
                K.Anim {
                    type: K.Anim.DefaultEffects
                }
            }

            Column {
                spacing: 4
                y: -Math.max(0, Math.min(root.popups.length - 3, root.currentIndex - 1)) * 12
                Behavior on y {
                    enabled: K.Kit.anim.enabled
                    K.Anim {
                        type: K.Anim.BodySpatial
                    }
                }

                Repeater {
                    model: root.popups

                    Rectangle {
                        required property var modelData
                        required property int index
                        readonly property bool on: index === root.currentIndex
                        width: 8
                        height: 8
                        radius: 4
                        color: modelData.critical ? Colors.error : on ? colors.tone : Qt.alpha(colors.tone, 0.3)
                        scale: on ? 1 : 0.5
                        Behavior on color {
                            K.CAnim {}
                        }
                        Behavior on scale {
                            enabled: K.Kit.anim.enabled
                            K.Anim {
                                type: K.Anim.FastSpatial
                            }
                        }
                    }
                }
            }
        }
    }

    // one notification: NotificationCard in island.notifications' look
    Component {
        id: cardComponent

        NotificationCard {
            // its place in popupList when it was shown (where the next one comes from when it goes)
            property int index: 0
            width: stack.width
            look: Store.island.notifications?.style || "shapes"
            tone: colors.tone
            overTone: colors.overTone
            expanded: root.expanded
            animation: Store.island.notifications?.animation || "slide"
            time: notification ? (root.minute, Notifications.age(notification.time)) : ""
            onDismissed: root.dismiss(notification)
            onActivated: Notifications.invokeAction(notification.id, "default")
            onActionInvoked: identifier => Notifications.invokeAction(notification.id, identifier)
        }
    }
}
