import QtQuick
import Quickshell
import Quickshell.Widgets
import qs.theme
import qs.kit as K
import qs.dwidgets.media as DMedia

// One notification on the island (R1, 2026-10-11: the transient in the Iwidget language), drawn only with
// palette roles. `look`:
//  - shapes: the app's icon on a random accent M3 shape, the summary onSurface bold and the body
//    variant
//  - tones: the bare app icon, the summary in the tone bold and the body a weak tone of it
//  - tone: a symbol in the tone (no fill), summary and body in the tone
// Its actions are one connected button row (the main one filled; actionsRow below).
// A picture (a contact's photo, an album) replaces the lead in a circle. Critical swaps the tone for the
// error colour. `expanded` (hover, or always): the summary line gets the app and the time, the body up to
// three lines, the actions and a dismiss button. One layout whose text only moves (R1a, 2026-10-15): the
// body slides from the summary's line to below it and the summary makes room for the meta; only what's
// new (meta, dismiss, actions) fades in. The width never changes with it (the host sizes the card).
Item {
    id: root

    property var notification: null
    property string look: "shapes"
    property bool expanded: false
    // how it expands (island.notifications.animation, 2026-10-15): "slide" (the text moves to its place) or
    // "fade" (the text fades out, the layout swaps, it fades back in); the width never changes either way
    property string animation: "slide"
    readonly property bool fadeMode: animation === "fade"
    // the layout drawn now: follows `expanded` at once (slide), or at the fade's dip (fade). Not bound (a
    // binding made the fade's first expand jump): set when the card is made, then by onExpandedChanged
    property bool shown
    Component.onCompleted: {
        shown = expanded;
        placeBody();
    }
    // fade: the text's opacity while it swaps (1 otherwise)
    property real textOpacity: 1
    property var pal: K.Kit.bare
    property color tone: pal.accent
    property color overTone: pal.overAccent
    // "now", "5m"… (the host refreshes it)
    property string time: ""

    signal dismissed
    // a click on the card: the app's "default" action (when it has one)
    signal activated
    signal actionInvoked(string identifier)

    readonly property bool critical: notification?.critical ?? false
    readonly property color accent: critical ? Colors.error : tone
    readonly property color overAccentInk: critical ? Colors.overError : overTone
    readonly property color titleColor: look === "shapes" ? pal.over : accent
    // the weak tones read too faint in light: stronger there
    readonly property bool light: K.Kit.expressive.light
    readonly property color bodyColor: look === "shapes" ? pal.overVariant : look === "tones" ? Qt.alpha(accent, light ? 0.9 : 0.6) : Qt.alpha(accent, light ? 0.9 : 0.8)
    readonly property color metaColor: look === "shapes" ? pal.overVariant : Qt.alpha(accent, light ? 0.85 : 0.55)
    readonly property int titleWeight: look === "tone" ? 600 : 700

    readonly property string summary: notification?.summary ?? ""
    // (Notifications cleans it: no markup)
    readonly property string body: notification?.body ?? ""
    readonly property string appName: notification?.appName ?? ""
    // the shell's own notifications may name a Material symbol as their icon ("material:<name>", e.g. the
    // battery warnings; notify-send -n, or -i, which libnotify 0.8 sends as the image): drawn as the lead's
    // symbol, in every look, and never taken as a picture
    readonly property string symbolIcon: {
        for (const i of [notification?.appIcon ?? "", notification?.image ?? ""])
            if (i.startsWith("material:"))
                return i.slice(9);
        return "";
    }
    readonly property string picture: symbolIcon !== "" ? "" : notification?.image ?? ""
    readonly property string appIcon: {
        if (symbolIcon !== "")
            return "";
        const i = notification?.appIcon ?? "";
        if (i.startsWith("/"))
            return "file://" + i;
        if (i.startsWith("file:") || i.startsWith("data:") || i.startsWith("image:"))
            return i;
        return Quickshell.iconPath(i || appName.toLowerCase(), true);
    }
    readonly property var actions: notification?.actions ?? []

    readonly property int lead: 32
    readonly property int gap: 10
    readonly property int textSize: 13

    // the text column (right of the lead)
    readonly property real textX: lead + gap
    readonly property real textWidth: Math.max(0, width - textX)
    readonly property int dismissSize: 24
    readonly property bool hasBody: body !== ""
    readonly property bool hasActions: actions.length > 0

    // the summary's width: when it doesn't fit with what follows it (collapsed the body, expanded the meta
    // left of the dismiss), it keeps 60 % of the line and the rest elides
    // (measured with TextMetrics: an elided Text's implicitWidth depends on its own width; whole pixels)
    readonly property real collapsedSummaryWidth: Math.min(Math.ceil(summaryMetrics.advanceWidth), hasBody ? Math.max(Math.floor(textWidth * 0.6), Math.floor(textWidth) - Math.ceil(oneLineBody.advanceWidth) - 6) : Math.floor(textWidth))
    readonly property real firstLineWidth: Math.max(0, Math.floor(textWidth) - dismissSize - 6)
    // the meta: "App · time", or only the time when that doesn't fit next to the summary (at its 60 %); the
    // summary then sizes against what's shown
    readonly property string metaFull: [appName, time].filter(s => s !== "").join(" · ")
    readonly property bool metaFullFits: time === "" || Math.ceil(metaMetrics.advanceWidth) <= firstLineWidth - Math.min(Math.ceil(summaryMetrics.advanceWidth), Math.floor(firstLineWidth * 0.6)) - 6
    readonly property string metaShown: metaFullFits ? metaFull : time
    readonly property real metaNeed: Math.ceil((metaFullFits ? metaMetrics : timeMetrics).advanceWidth)
    readonly property real expandedSummaryWidth: Math.min(Math.ceil(summaryMetrics.advanceWidth), Math.max(Math.floor(firstLineWidth * 0.6), firstLineWidth - metaNeed - 6))
    readonly property real metaRoom: Math.max(0, firstLineWidth - expandedSummaryWidth - 6)
    // the body below the summary (expanded)
    readonly property real bodyTop: lead + 2
    readonly property real actionsTop: hasBody ? bodyTop + bodyMeasure.implicitHeight + 10 : lead + 6
    readonly property real expandedHeight: hasActions ? actionsTop + actionHeight : hasBody ? bodyTop + bodyMeasure.implicitHeight : lead

    // collapsing, the card keeps room for the body's first line while it rises back (it never disappears)
    implicitHeight: shown ? expandedHeight : bodyMove.running && hasBody ? Math.max(lead, Math.ceil(bodyY + oneLine.height)) : lead
    implicitWidth: 360

    // The body's place: on the summary's line (collapsed) or below it (expanded). It moves in two staggered
    // legs so it never crosses the summary line while wrapped: expanding it drops first and then slides
    // left, collapsing it slides right first and then rises. It stays wrapped (full width, clipped to the
    // text column) while it moves and goes back to one line once it's on the summary's line.
    readonly property real inlineX: textX + collapsedSummaryWidth + 6
    readonly property real inlineY: Math.round((lead - oneLine.height) / 2)
    property real bodyX: shown ? textX : inlineX
    property real bodyY: shown ? bodyTop : inlineY
    property bool bodyWrapped: shown
    function placeBody() {
        bodyMove.stop();
        bodyX = Qt.binding(() => root.shown ? root.textX : root.inlineX);
        bodyY = Qt.binding(() => root.shown ? root.bodyTop : root.inlineY);
        bodyWrapped = shown;
    }
    onExpandedChanged: {
        if (fadeMode && K.Kit.anim.enabled && visible) {
            bodyMove.stop();
            fadeSwap.restart();
            return;
        }
        fadeSwap.stop();
        textOpacity = 1;
        shown = expanded;
        if (!K.Kit.anim.enabled || !hasBody || !visible) {
            placeBody();
            return;
        }
        // from where it is (mid-move) or from the other place: the bindings would jump it there
        const fromX = bodyMove.running ? bodyX : expanded ? inlineX : textX;
        const fromY = bodyMove.running ? bodyY : expanded ? inlineY : bodyTop;
        bodyMove.stop();
        bodyX = fromX;
        bodyY = fromY;
        bodyWrapped = true;
        const toX = expanded ? textX : inlineX;
        const toY = expanded ? bodyTop : inlineY;
        // the first leg leaves the summary's line (down) or reaches its column (right), the second one the place
        legOne.property = expanded ? "bodyY" : "bodyX";
        legOne.to = expanded ? toY : toX;
        legTwo.property = expanded ? "bodyX" : "bodyY";
        legTwo.to = expanded ? toX : toY;
        bodyMove.start();
    }
    ParallelAnimation {
        id: bodyMove
        K.Anim {
            id: legOne
            target: root
            type: K.Anim.BodySpatial
        }
        SequentialAnimation {
            // how much the legs overlap: the less it waits, the more diagonal the path
            PauseAnimation {
                duration: K.Kit.anim.durations.expressiveDefaultSpatial * 0.2
            }
            K.Anim {
                id: legTwo
                target: root
                type: K.Anim.BodySpatial
            }
        }
        onFinished: root.placeBody()
    }
    // fade: out, the layout swaps (at once), back in
    SequentialAnimation {
        id: fadeSwap
        K.Anim {
            target: root
            property: "textOpacity"
            to: 0
            type: K.Anim.FastEffects
        }
        ScriptAction {
            script: {
                root.shown = root.expanded;
                root.placeBody();
            }
        }
        K.Anim {
            target: root
            property: "textOpacity"
            to: 1
            type: K.Anim.DefaultEffects
        }
    }
    // the new parts wait for the body to leave the summary's line (fading in); fading out they go at once
    readonly property int revealDelay: K.Kit.anim.durations.expressiveDefaultSpatial * 0.35

    // a click anywhere on the card (not on its buttons) runs the app's "default" action
    MouseArea {
        anchors.fill: parent
        enabled: root.notification?.hasDefault ?? false
        cursorShape: Qt.PointingHandCursor
        onClicked: root.activated()
    }

    // the lead ------------------------------------------------------------------------------------------
    Item {
        id: leadItem
        width: root.lead
        height: root.lead

        // a picture in a circle (a mask, the dashboard's Art: a ClippingRectangle at a half-pixel x wrapped
        // its picture, 2026-10-27)
        DMedia.Art {
            anchors.fill: parent
            visible: root.picture !== ""
            radius: width / 2
            source: root.picture
            placeholder: root.pal.off
            showNote: false
        }
        // shapes: the app's icon on an accent M3 shape (the workspaces' and the active window's Shapes) that
        // keeps morphing to the next one while it shows (the visualizer's Shapes), faster the more urgent:
        // every 2 s low, 1 s normal, 0.5 s critical. It starts from the notification's id, so a card made
        // again starts where it did, and consecutive notifications start on different shapes
        K.M3Shape {
            id: leadShape
            anchors.fill: parent
            visible: root.picture === "" && root.look === "shapes"
            color: root.accent
            // (120 is for big shapes; at 32 px 48 looks the same and the morph costs less)
            samples: 48
            readonly property var shapes: ["cookie4", "cookie6", "cookie7", "cookie9", "cookie12", "sunny", "softBurst", "clover4", "clover8"]
            property int step: 0
            // (7 is coprime with 9)
            shape: shapes[((root.notification?.id ?? 0) * 7 + step) % shapes.length]

            Timer {
                interval: [2000, 1000, 500][root.notification?.urgency ?? 1] ?? 1000
                repeat: true
                running: leadShape.visible && root.visible && K.Kit.anim.enabled
                onTriggered: leadShape.step++
            }
        }
        IconImage {
            readonly property int size: root.look === "shapes" ? 18 : 24
            x: Math.round((parent.width - size) / 2)
            y: Math.round((parent.height - size) / 2)
            implicitSize: size
            visible: root.picture === "" && root.look !== "tone" && root.appIcon !== ""
            source: root.appIcon
            asynchronous: true
        }
        // tone (or no icon): a symbol in the tone
        K.MaterialIcon {
            x: Math.round((parent.width - width) / 2)
            y: Math.round((parent.height - height) / 2)
            visible: root.picture === "" && (root.look === "tone" || root.appIcon === "")
            text: root.symbolIcon || (root.critical ? "warning" : "notifications")
            size: 20
            fill: root.critical || root.symbolIcon !== "" ? 1 : 0
            color: root.look === "shapes" ? root.overAccentInk : root.accent
        }
    }

    component Line: Text {
        font.family: K.Kit.family
        font.variableAxes: K.Kit.axes
        font.pixelSize: root.textSize
        elide: Text.ElideRight
        maximumLineCount: 1
        verticalAlignment: Text.AlignVCenter
        renderType: Tokens.font.renderType
    }

    TextMetrics {
        id: summaryMetrics
        font: summaryText.font
        text: root.summary
    }
    TextMetrics {
        id: metaMetrics
        font: meta.font
        text: root.metaFull
    }
    TextMetrics {
        id: timeMetrics
        font: meta.font
        text: root.time
    }
    TextMetrics {
        id: oneLineBody
        font.family: K.Kit.family
        font.variableAxes: K.Kit.axes
        font.pixelSize: root.textSize
        text: root.body.replace(/\n/g, " ")
    }
    // the expanded body's height (the shown one is on one line while collapsed)
    Text {
        id: bodyMeasure
        opacity: 0
        enabled: false
        width: root.textWidth
        text: root.body
        font: bodyText.font
        renderType: bodyText.renderType
        wrapMode: Text.Wrap
        maximumLineCount: 3
        elide: Text.ElideRight
    }

    // the summary: always on the first line, it only narrows for the meta
    Line {
        id: summaryText
        x: root.textX
        height: root.lead
        width: root.shown ? root.expandedSummaryWidth : root.collapsedSummaryWidth
        opacity: root.textOpacity
        Behavior on width {
            enabled: K.Kit.anim.enabled && !root.fadeMode
            K.Anim {
                type: K.Anim.BodySpatial
            }
        }
        text: root.summary
        font.weight: root.titleWeight
        color: root.titleColor
    }

    // app · time, after the summary (expanded), on the summary's baseline
    Line {
        id: meta
        x: root.textX + root.expandedSummaryWidth + 6
        y: Math.round(summaryText.y + summaryText.baselineOffset - baselineOffset)
        verticalAlignment: Text.AlignTop
        width: Math.min(implicitWidth, root.metaRoom)
        text: root.metaShown
        font.pixelSize: 11
        color: root.metaColor
        opacity: root.shown ? root.textOpacity : 0
        Behavior on opacity {
            id: metaFade
            enabled: K.Kit.anim.enabled && !root.fadeMode
            SequentialAnimation {
                PauseAnimation {
                    duration: metaFade.targetValue > 0 ? root.revealDelay : 0
                }
                K.Anim {
                    type: K.Anim.DefaultEffects
                }
            }
        }
        visible: opacity > 0
    }

    // dismiss (expanded)
    Item {
        id: close
        x: root.width - width
        y: Math.round((root.lead - height) / 2)
        width: root.dismissSize
        height: root.dismissSize
        opacity: root.shown ? root.textOpacity : 0
        Behavior on opacity {
            id: closeFade
            enabled: K.Kit.anim.enabled && !root.fadeMode
            SequentialAnimation {
                PauseAnimation {
                    duration: closeFade.targetValue > 0 ? root.revealDelay : 0
                }
                K.Anim {
                    type: K.Anim.DefaultEffects
                }
            }
        }
        visible: opacity > 0
        enabled: root.shown
        Rectangle {
            anchors.fill: parent
            radius: width / 2
            visible: root.look === "shapes"
            color: root.pal.off
        }
        K.StateLayer {
            radius: width / 2
            color: root.pal.over
            onClicked: root.dismissed()
        }
        K.MaterialIcon {
            x: Math.round((parent.width - width) / 2)
            y: Math.round((parent.height - height) / 2)
            text: "close"
            size: 16
            color: root.look === "shapes" ? root.pal.over : root.accent
        }
    }

    // the body: on the summary's line (one line, after it) collapsed, below it (up to three lines) expanded.
    // It moves between the two (bodyX / bodyY, above); it never fades. Clipped to the text column while it
    // travels wrapped
    Item {
        x: root.textX
        width: root.textWidth
        // collapsing, only the first line: the others would show as a sliver under the summary's line
        height: root.shown ? Math.max(root.height, root.expandedHeight) : Math.ceil(root.bodyY + oneLine.height)
        clip: root.bodyWrapped && !root.shown || bodyMove.running
        opacity: root.textOpacity

        Text {
            id: bodyText
            visible: root.hasBody
            // (never left of the column: the curve overshoots)
            x: Math.max(0, Math.round(root.bodyX - root.textX))
            y: Math.round(root.bodyY)
            width: root.bodyWrapped ? root.textWidth : Math.max(0, root.textWidth - root.collapsedSummaryWidth - 6)
            text: root.bodyWrapped ? root.body : root.body.replace(/\n/g, " ")
            font.family: K.Kit.family
            font.variableAxes: K.Kit.axes
            font.pixelSize: root.textSize
            renderType: Tokens.font.renderType
            color: root.bodyColor
            wrapMode: root.bodyWrapped ? Text.Wrap : Text.NoWrap
            maximumLineCount: root.bodyWrapped ? 3 : 1
            elide: Text.ElideRight
        }
    }
    // one line's height (the collapsed body is centred on the summary's line)
    Text {
        id: oneLine
        opacity: 0
        enabled: false
        text: "X"
        font: bodyText.font
        renderType: bodyText.renderType
    }

    // the actions (expanded), below the body: one connected row as wide as the card, under the lead too (an M3
    // Expressive connected button group): equal parts, round outside, small corners between them; the
    // first is the main one (filled), at most three. Labels elide; actions without one aren't buttons
    // (NotificationEntry). The colours per look: shapes on the card's off tone with the main one in the
    // accent; tones / tone in tints of the accent (tones: the main one filled)
    readonly property var shownActions: actions.slice(0, 3)
    readonly property int actionHeight: 32
    Item {
        id: actionsRow
        y: root.actionsTop
        width: Math.floor(root.width)
        height: root.actionHeight
        visible: root.hasActions && opacity > 0
        enabled: root.shown
        opacity: root.shown ? root.textOpacity : 0
        Behavior on opacity {
            id: actionsFade
            enabled: K.Kit.anim.enabled && !root.fadeMode
            SequentialAnimation {
                PauseAnimation {
                    duration: actionsFade.targetValue > 0 ? root.revealDelay : 0
                }
                K.Anim {
                    type: K.Anim.DefaultEffects
                }
            }
        }

        readonly property int gap: 2
        readonly property int count: root.shownActions.length
        readonly property real part: count > 0 ? (width - (count - 1) * gap) / count : 0

        Repeater {
            model: root.shownActions

            Item {
                id: action
                required property var modelData
                required property int index
                readonly property bool main: index === 0
                readonly property real outer: height / 2
                readonly property real inner: 4
                readonly property real leftRadius: index === 0 ? outer : inner
                readonly property real rightRadius: index === actionsRow.count - 1 ? outer : inner
                readonly property color fill: root.look === "shapes" ? (main ? root.accent : root.pal.off) : root.look === "tones" && main ? root.accent : Qt.alpha(root.accent, main ? 0.22 : 0.12)
                readonly property color ink: main && root.look !== "tone" ? root.overAccentInk : root.look === "shapes" ? root.pal.over : root.accent

                x: Math.round(index * (actionsRow.part + actionsRow.gap))
                width: Math.round((index + 1) * (actionsRow.part + actionsRow.gap) - actionsRow.gap) - x
                height: actionsRow.height

                Rectangle {
                    anchors.fill: parent
                    color: action.fill
                    topLeftRadius: action.leftRadius
                    bottomLeftRadius: action.leftRadius
                    topRightRadius: action.rightRadius
                    bottomRightRadius: action.rightRadius
                }
                K.StateLayer {
                    color: action.ink
                    topLeftRadius: action.leftRadius
                    bottomLeftRadius: action.leftRadius
                    topRightRadius: action.rightRadius
                    bottomRightRadius: action.rightRadius
                    onClicked: root.actionInvoked(action.modelData.identifier)
                }
                Line {
                    x: 10
                    width: parent.width - 20
                    height: parent.height
                    horizontalAlignment: Text.AlignHCenter
                    text: action.modelData.text
                    font.pixelSize: 12
                    font.weight: 600
                    color: action.ink
                }
            }
        }
    }
}
