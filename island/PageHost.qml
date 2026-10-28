import QtQuick
import qs.theme

// Shows the island's pages (the idle DefaultView and the app views) inside the animated body.
// A switch is a "container transform": the pages never re-lay out while the island morphs;
// each keeps its own size, centered on the body and pinned to its top, and only its scale,
// opacity animate. With `pageScale` the page is scaled to the body's current width
// (never above 1, so the shape's bounce doesn't reach the content); without it the page keeps
// its size and the body's edges crop it. Fade through: the leaving page is gone before the
// entering one appears.
//
// API close to StackView's (what Island used before): currentItem, depth, busy, push, replace, pop.
Item {
    id: host

    required property Item initialItem
    // animated height of the island and the height it's going to (idle page vertical centering)
    property real fullHeight: height
    property real targetHeight: height
    // the idle island's height (the idle page is centred in it)
    property real restHeight: height
    // inner margin of app pages (the idle page and pages with `islandCentered: true`, the
    // transients, have none)
    property real appMargin: 16
    property bool pageScale: true
    // what moves the host onto whole screen pixels (the island's body sits at a half pixel when its width is
    // odd: a page there drew its pictures and text between pixels, the media disc wrapped its art, 2026-10-27)
    property real snapX: 0
    // whole pixels (snapX, Math.round) only while the island rests: moving, the pages glide on exact positions
    // (K.Kit.snap, 2026-10-28)
    property bool snap: true
    property int duration: 400

    // fade thresholds (fractions of the transition)
    readonly property real fadeOutEnd: 0.3
    readonly property real fadeInStart: 0.3
    readonly property real fadeInEnd: 0.8

    property Item currentItem: null
    readonly property int depth: currentItem && currentItem !== initialItem ? 2 : 1
    readonly property bool busy: transition.running

    property real progress: 1
    NumberAnimation {
        id: transition
        target: host
        property: "progress"
        from: 0
        to: 1
        duration: host.duration
    }

    function clamp01(v: real): real {
        return Math.max(0, Math.min(1, v));
    }
    function outQuart(t: real): real {
        return 1 - Math.pow(1 - t, 4);
    }
    function outCubic(t: real): real {
        return 1 - Math.pow(1 - t, 3);
    }
    readonly property real fadeOut: outQuart(clamp01(progress / fadeOutEnd))
    readonly property real fadeIn: outCubic(clamp01((progress - fadeInStart) / (fadeInEnd - fadeInStart)))

    // two holders that swap roles on every switch
    property Holder entering: holderA
    property Holder leaving: holderB

    function show(page: Item) {
        if (!page || page === currentItem)
            return;
        const wasEntering = entering;
        // a switch in the middle of another one: the half-shown page leaves from where it is
        const startOpacity = busy ? wasEntering.opacity : 1;
        leaving.release();
        leaving = wasEntering;
        leaving.startOpacity = startOpacity;
        leaving.startY = leaving.y;
        entering = wasEntering === holderA ? holderB : holderA;
        entering.take(page);
        currentItem = page;
        if (duration > 0) {
            transition.restart();
        } else {
            progress = 1;
            leaving.release();
        }
    }
    function push(page: Item) {
        show(page);
    }
    function replace(page: Item) {
        show(page);
    }
    function pop(item: Item) {
        show(initialItem);
    }

    onBusyChanged: if (!busy)
        leaving.release()

    Component.onCompleted: {
        entering.take(initialItem);
        currentItem = initialItem;
    }

    // hidden parent for pages that aren't shown
    Item {
        id: stash
        visible: false
    }

    Holder {
        id: holderA
    }
    Holder {
        id: holderB
    }

    component Holder: Item {
        id: holder

        property Item page: null
        readonly property bool isEntering: host.entering === holder
        readonly property bool isIdle: page !== null && page === host.initialItem
        // transient pages (OSD, notification cards): no margin, pinned to the top and never scaled.
        // Scaling text with the body's elastic width (or centring it in the bouncing height) makes
        // the characters wobble; the body just grows around them and its clip reveals them
        readonly property bool isTransient: page !== null && (page.islandCentered ?? false)
        readonly property real margin: isIdle || isTransient ? 0 : host.appMargin
        property real startOpacity: 1
        property real startY: 0

        function take(p: Item) {
            page = p;
            p.parent = holder;
            p.x = 0;
            p.y = 0;
            p.width = Qt.binding(() => p.implicitWidth);
            p.height = Qt.binding(() => p.implicitHeight);
            p.visible = true;
        }
        function release() {
            if (!page)
                return;
            page.visible = false;
            page.parent = stash;
            page = null;
        }

        visible: page !== null && opacity > 0
        enabled: isEntering
        width: page ? page.width : 0
        height: page ? page.height : 0
        transformOrigin: Item.Top
        // whole screen pixels: rounded in the host, plus the host's own fraction
        x: host.snap ? Math.round((host.width - width) / 2) + host.snapX : (host.width - width) / 2
        y: {
            if (!isIdle)
                return margin;
            // idle page: at its resting spot, centred in the idle island's height (whole pixels).
            // vtnc: not in the animated height (the elastic bounce moved the text by fractions of
            // a pixel after every morph: trembling), nor in the target height (it already counts
            // an opening app's padding a frame before the switch starts: a jump). The leaving one
            // stays where it was.
            if (!host.busy || isEntering)
                return Math.round(Math.max(0, host.restHeight - height) / 2);
            return startY;
        }
        scale: host.busy && host.pageScale && !isTransient && width > 0 ? Math.min(1, Math.max(0.01, (host.width - 2 * margin) / width)) : 1
        opacity: !host.busy ? (isEntering ? 1 : 0) : isEntering ? host.fadeIn : startOpacity * (1 - host.fadeOut)
    }
}
