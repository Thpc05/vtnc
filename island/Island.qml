// The StackView pages come from vtnc's apps system (apps/AppRegistry).
import QtQuick
import QtQuick.Controls
import QtQuick.Effects
import Quickshell
import qs.core
import qs.services
import qs.theme
import qs.components
import qs.kit as K
import qs.apps
import "transient" as Transient

Item {
    id: root

    required property ShellScreen screen
    readonly property string screenName: screen?.name ?? ""
    // "island" (floating) or "default" (the notch, attached to the top edge): island.style
    readonly property string notchTheme: Store.island.style === "island" ? "island" : "default"

    // vtnc state ---------------------------------------------------------------
    readonly property bool appOpen: Runtime.isAppOpenOn(screenName)
    // transient state (OSD / notification) shown over the idle island or over the app, see Runtime
    readonly property var activeTransient: Runtime.transientOn(screenName)
    readonly property bool transientActive: activeTransient !== null
    // a notification with island.notifications.presentation "grow" doesn't replace the page: it hangs
    // under it (the idle content or an app, `attachment` below), as wide as the island, which keeps
    // expanding on hover
    readonly property bool notificationGrows: Store.island.notifications?.presentation === "grow"
    readonly property bool transientAttached: activeTransient?.kind === "notification" && notificationGrows
    // a transient that takes the page's place (OSD, a "replace" notification)
    readonly property bool pageTransient: transientActive && !transientAttached
    onNotificationGrowsChanged: syncPage()
    // the app's page is what the island shows (not covered by a transient)
    readonly property bool showingApp: appOpen && !pageTransient
    property bool hoverExpanded: false
    // flash: auto-expand for a moment when the track changes (island.flash.media)
    property bool flashExpanded: false
    readonly property bool expanded: !appOpen && !pageTransient && (hoverExpanded || flashExpanded || Runtime.isPinned(screenName))
    // for the notification presenter (island.notifications.compact / expanded)
    onExpandedChanged: Runtime.setIslandExpanded(screenName, expanded)

    // Auto-hide (island.autohide + island.autohide_nv):
    //  1 fullscreen window · 2 fullscreen or any window on the monitor's workspace · 3 always.
    // While hidden, hovering the top strip (island.autohide_px, see IslandWindow) reveals it;
    // it hides again island.autohide_delay ms after the pointer leaves (showing waits island.autohide_show_delay ms).
    readonly property var workspaceId: Hypr.monitorFor(screen)?.activeWorkspace?.id
    readonly property bool autohideWanted: {
        if (!Store.island.autohide)
            return false;
        switch (Store.island.autohide_nv) {
        case 3:
            return true;
        case 2:
            return Hypr.hasFullscreen(screen) || (workspaceId !== undefined && Hypr.isOccupied(workspaceId));
        default:
            return Hypr.hasFullscreen(screen);
        }
    }
    // set by IslandWindow's activation strip
    property bool stripHovered: false
    readonly property bool pointerInside: hover.hovered || stripHovered

    // slid away by auto-hide; an open app, a transient (OSD, notification) or the pointer
    // bring it back. The expanded state (IPC-pinned or flash) is hidden too.
    // Hiding waits island.autohide_delay ms. Showing waits island.autohide_show_delay ms
    // (pointer, or the auto-hide condition ending: empty workspace, fullscreen left);
    // an app or a transient shows it right away.
    // a transient reveals it at once, like an app
    // (the volume shown as its widget, volumeFlash below, too: it stands in for the OSD transient)
    readonly property bool concealWanted: !appOpen && !transientActive && !volumeFlash && !pointerInside && autohideWanted
    property bool concealed: false
    // closing an app (or a window showing up right after, e.g. from the launcher) hides after
    // appCloseDelay instead of island.autohide_delay, so the idle island doesn't show in between
    readonly property int appCloseDelay: 100
    readonly property int appCloseGrace: 1000
    property real appClosedAt: 0
    function scheduleConceal() {
        revealTimer.stop();
        const afterApp = Date.now() - appClosedAt < appCloseGrace;
        concealTimer.interval = afterApp ? appCloseDelay : Math.max(0, Store.island.autohide_delay);
        concealTimer.restart();
    }
    onConcealWantedChanged: {
        if (concealWanted) {
            scheduleConceal();
            return;
        }
        concealTimer.stop();
        // (activeTransient itself: transientActive may not be updated yet in this handler)
        const immediate = appOpen || activeTransient !== null;
        if (concealed && !immediate && Store.island.autohide_show_delay > 0)
            revealTimer.restart();
        else
            concealed = false;
    }
    Timer {
        id: revealTimer
        interval: Math.max(0, Store.island.autohide_show_delay)
        onTriggered: root.concealed = root.concealWanted
    }
    Component.onCompleted: {
        idleRefWidth = defaultView.implicitWidth;
        Runtime.setIslandExpanded(screenName, expanded);
        concealed = concealWanted;
        startConceal(false); // initial state without animations
    }
    Timer {
        id: concealTimer
        onTriggered: root.concealed = root.concealWanted
    }

    // vtnc: while the island morphs (app open/close/switch) hover is ignored: no expansion,
    // no hover effects, and the hover handler is off until the animation ends.
    // Otherwise closing an app under the cursor stops at "expanded" before going back to compact.
    readonly property bool morphing: notchContainer.stackView.busy || morphTimer.running
    Timer {
        id: morphTimer
        interval: K.Kit.anim.durations.expressiveDefaultSpatial
    }
    onAppOpenChanged: {
        // the order against onConcealWantedChanged isn't guaranteed: reschedule here too
        if (!appOpen) {
            appClosedAt = Date.now();
            if (concealWanted && !concealed)
                scheduleConceal();
        }
        morphTimer.restart();
        root.resetHover();
        root.syncPage();
    }
    onTransientActiveChanged: {
        // back from a transient: hide the short way too (see appCloseDelay)
        if (!transientActive) {
            appClosedAt = Date.now();
            if (concealWanted && !concealed)
                scheduleConceal();
        }
    }
    // the page swaps (an attached notification leaves the page and the hover alone)
    onPageTransientChanged: {
        morphTimer.restart();
        root.resetHover();
    }
    // every update (new payload, same kind = in place) restarts the timer
    onActiveTransientChanged: {
        if (transientTimer.running)
            transientTimer.restart();
        root.syncPage();
    }

    // the transient's time on screen, paused while the pointer is over the island
    HoverHandler {
        id: bodyHover
    }
    Timer {
        id: transientTimer
        interval: root.activeTransient?.duration ?? 0
        running: root.transientActive && interval > 0 && !bodyHover.hovered
        onTriggered: Runtime.endTransient(root.screenName, root.activeTransient?.kind ?? "")
    }
    onMorphingChanged: {
        if (morphing)
            root.resetHover();
        notchContainer.updateChildHover();
    }

    function resetHover() {
        expandTimer.stop();
        collapseTimer.stop();
        hoverExpanded = false;
    }
    // the screen frame's top thickness (IslandWindow, animated; 0 without a frame): the island
    // hangs from the frame's inner edge
    property real frameTop: 0
    // island style floats `margin` px below the edge (the frame's inner edge)
    readonly property real topGap: (root.notchTheme === "island" ? Store.island.margin : 0) + frameTop

    // vtnc (stage 8): the body is drawn by the window's blob surface (IslandWindow, K.BlobSurface),
    // with the frame, as one liquid shape under one shadow; these give it the body's shape, in the
    // island's coordinates (before its transforms). The notch's flares are the surface's merge
    // radius (`flare`), shrinking with the body as it retracts.
    readonly property real bodyLeft: notchContainer.x + (notchContainer.width - notchRect.width) / 2
    readonly property real bodyTop: notchContainer.y
    readonly property real bodyWidth: notchRect.width
    readonly property real bodyHeight: notchContainer.bodyHeight
    readonly property real flare: notchStyle ? Math.min(notchContainer.cornerSize, notchContainer.bodyHeight) : 0
    readonly property real flareSize: notchContainer.cornerSize
    property real bodyRadius: notchRect.islandRadius
    Behavior on bodyRadius {
        id: radiusBehavior
        enabled: K.Kit.anim.enabled
        K.Anim {
            type: K.Anim.BodySpatial
        }
    }
    readonly property real slideY: slide.y
    readonly property real hopY: hop.y
    readonly property real bodyXScale: Math.max(0, 1 + concealWidth * concealProgress) // never mirrored by the overshoot

    implicitWidth: notchContainer.width
    implicitHeight: notchContainer.implicitHeight + topGap

    // Hide / show (autohide), "anchored elastic body":
    //  - notch style: the body retracts into the top edge and grows back out of it (height
    //    morph, flares shrink with it), so it never detaches from the edge;
    //  - island style (floating): slides up / down, fading only at the end of the hide.
    // Both on the kit's expressive spatial curve (its own overshoot is the bounce; stage 8).
    // (explicit animations, not Behaviors: a Behavior whose easing depends on `concealed`
    // reads it before it updates)
    readonly property bool notchStyle: root.notchTheme === "default"
    opacity: 1

    onConcealedChanged: startConceal(true)
    onNotchStyleChanged: startConceal(false)

    function startConceal(animate: bool) {
        concealFade.stop();
        retractAnim.stop();
        slideAnim.stop();
        const anim = animate && K.Kit.anim.enabled;
        if (notchStyle) {
            slide.y = 0;
            opacity = 1;
            animateTo(retractAnim, root, "hiddenAmount", concealed ? retractTarget : 0, anim);
        } else {
            hiddenAmount = 0;
            animateTo(slideAnim, slide, "y", concealed ? concealOffset : 0, anim);
            if (!concealed || !anim)
                opacity = concealed ? 0 : 1;
            else
                concealFade.start();
        }
    }

    function animateTo(animation, target, property, to, anim) {
        if (!anim) {
            target[property] = to;
            return;
        }
        animation.to = to;
        animation.start();
    }

    // the body is moving (its size, the hide, the hop) or a page is switching: the content then follows it on exact
    // positions, and lands on whole pixels once it rests (K.Kit.snap, 2026-10-28)
    readonly property bool moving: widthAnim.running || heightAnim.running || hopAnim.running || slideAnim.running || retractAnim.running || stackViewInternal.busy

    // notch: how many px of the body are retracted into the edge (0 = fully shown)
    property real hiddenAmount: 0
    readonly property real retractTarget: notchContainer.implicitHeight + 8
    K.Anim {
        id: retractAnim
        target: root
        property: "hiddenAmount"
        type: K.Anim.BodySpatial
        // the hide can start while an app still morphs back: its `to` was the app's size
        onFinished: if (root.concealed)
            root.hiddenAmount = root.retractTarget
    }
    // stay fully retracted if the island grows while hidden
    onRetractTargetChanged: if (concealed && notchStyle && !retractAnim.running)
        hiddenAmount = retractTarget

    // island: slide + fade that starts late (solid while it moves away)
    readonly property real concealOffset: -(Math.max(notchContainer.height, 50) + 16 + topGap)

    // both styles change width while hiding by island.autohide_width % (negative narrows) and back, with the same bounce:
    // progress 0 = shown, 1 = hidden (it goes past 0/1 while the curve overshoots)
    readonly property real concealProgress: notchStyle ? (retractTarget > 0 ? hiddenAmount / retractTarget : 0) : (concealOffset !== 0 ? slide.y / concealOffset : 0)
    readonly property real concealWidth: Math.max(-100, Math.min(100, Store.island.autohide_width)) / 100
    transform: [
        Translate {
            id: slide
        },
        // the island style's hop (below)
        Translate {
            id: hop
        },
        Scale {
            origin.x: root.width / 2
            xScale: root.bodyXScale
        }
    ]
    // vtnc: island style only, when the island shrinks (an app closing, a transient ending, the
    // expanded island collapsing) it hops up a little and drops back (stage 8: K.Anim curves; the
    // blob surface lets it lick the edge as it rises)
    function hopUp() {
        if (root.notchTheme !== "island" || !K.Kit.anim.enabled || !K.Kit.anim.bounce || root.concealed)
            return;
        hopAnim.restart();
    }
    SequentialAnimation {
        id: hopAnim
        K.Anim {
            target: hop
            property: "y"
            to: -4
            type: K.Anim.FastEffects
        }
        K.Anim {
            target: hop
            property: "y"
            to: 0
            type: K.Anim.BodySpatial
        }
    }

    K.Anim {
        id: slideAnim
        target: slide
        property: "y"
        type: K.Anim.BodySpatial
        onFinished: if (root.concealed)
            slide.y = root.concealOffset
    }
    onConcealOffsetChanged: if (concealed && !notchStyle && !slideAnim.running)
        slide.y = concealOffset
    SequentialAnimation {
        id: concealFade
        PauseAnimation {
            duration: K.Kit.anim.durations.expressiveDefaultSpatial * 0.7
        }
        K.Anim {
            target: root
            property: "opacity"
            to: 0
            type: K.Anim.FastEffects
        }
    }

    // hover expansion (vtnc)
    HoverHandler {
        id: hover
        enabled: !root.morphing && !root.appOpen && !root.pageTransient
        onHoveredChanged: {
            notchContainer.isHovered = hovered;
            if (hovered) {
                collapseTimer.stop();
                expandTimer.restart();
            } else {
                expandTimer.stop();
                collapseTimer.restart();
            }
        }
    }

    Timer {
        id: expandTimer
        interval: Store.island.hoverDelay
        onTriggered: root.hoverExpanded = Store.island.expandOnHover
    }

    Timer {
        id: collapseTimer
        interval: Store.island.collapseDelay
        onTriggered: root.hoverExpanded = false
    }

    // widgets hidden in compact but shown for a moment (media on a new track)
    property var flashedWidgets: []

    Timer {
        id: flashTimer
        interval: Store.island.flash.duration
        onTriggered: {
            root.flashExpanded = false;
            root.flashedWidgets = [];
        }
    }

    // show widget `id` for a moment (island.flash.duration) even if it's hidden in compact
    function flashWidget(id: string) {
        if (!flashedWidgets.includes(id))
            flashedWidgets = flashedWidgets.concat([id]);
        flashTimer.restart();
    }

    // the volume OSD as its widget (osd.volumeWidget, transient/OsdSource.qml): the volume Iwidget for
    // a moment (osd.duration, kept while the pointer is over the island), even if it's hidden in the
    // island's mode; it reveals an auto-hidden island, as the OSD transient would
    property bool volumeFlash: false
    readonly property var shownFlashes: volumeFlash && !flashedWidgets.includes("volume") ? flashedWidgets.concat(["volume"]) : flashedWidgets
    Timer {
        id: volumeFlashTimer
        interval: Store.osd.duration > 0 ? Store.osd.duration : 1500
        onTriggered: {
            if (root.pointerInside)
                restart();
            else
                root.volumeFlash = false;
        }
    }
    Connections {
        target: Runtime
        function onVolumeFlashed(screenName) {
            if (screenName !== root.screenName)
                return;
            root.volumeFlash = true;
            volumeFlashTimer.restart();
        }
    }

    // the bell rings ("widget" notifications): if it's hidden in the current mode, show it for a
    // moment so it can shake (NotificationIndicator waits for it to appear)
    Connections {
        target: Runtime
        function onBellRang(screenName) {
            if (screenName !== root.screenName)
                return;
            // the bells on the island (there may be several): flash them when none shows in this mode
            const bells = (Store.island.widgets ?? []).filter(w => w.id === "notifications" && w.section !== "off");
            if (bells.length > 0 && bells.every(b => b[root.expanded ? "expanded" : "compact"] === WidgetRegistry.hidden))
                root.flashWidget("notifications");
        }
    }

    Connections {
        target: MprisController.activePlayer
        function onTrackTitleChanged() {
            const p = MprisController.activePlayer;
            if (!Store.island.flash.media || root.appOpen || !p || !p.trackTitle)
                return;
            // media in the island but hidden in compact: just show that widget for a moment;
            // otherwise expand the whole island
            const medias = (Store.island.widgets ?? []).filter(w => w.id === "media" && w.section !== "off");
            if (medias.length > 0 && medias.every(m => m.compact === WidgetRegistry.hidden))
                root.flashWidget("media");
            else
                root.flashExpanded = true;
            flashTimer.restart();
        }
    }

    Keys.onEscapePressed: {
        if (root.currentApp?.closeOnEsc ?? true)
            Runtime.closeApp();
    }

    // ---------------------------------------------------------------------------
    // Notch.qml
    Item {
        id: notchContainer

        y: root.topGap
        anchors.horizontalCenter: parent.horizontalCenter
        anchors.alignWhenCentered: false
        width: implicitWidth
        height: implicitHeight

        property var stackView: stackViewInternal
        // visible height of the notch body (retracts into the edge when hidden, notch style)
        readonly property real bodyHeight: Math.max(0, implicitHeight - root.hiddenAmount)
        property bool isExpanded: stackViewInternal.depth > 1
        property bool parentHovered: false
        property bool isHovered: false

        onParentHoveredChanged: updateChildHover()
        onIsHoveredChanged: updateChildHover()

        function updateChildHover() {
            if (stackViewInternal.currentItem) {
                const h = !root.morphing && (isHovered || parentHovered);
                if (stackViewInternal.currentItem.hasOwnProperty("notchHovered")) {
                    stackViewInternal.currentItem.notchHovered = h;
                }
                if (stackViewInternal.currentItem.hasOwnProperty("parentHoverActive")) {
                    stackViewInternal.currentItem.parentHoverActive = h;
                }
            }
        }

        // app padding / minimum width / big radius: only while the app itself is shown
        readonly property bool screenNotchOpen: root.showingApp
        // big radius: an app, a transient page that asks for it (`islandRoomy`, e.g. a card) or an
        // attached notification
        readonly property bool roomy: screenNotchOpen || (root.pageTransient && (stackViewInternal.currentItem?.islandRoomy ?? false)) || root.transientAttached
        // fully rounded (radius = half the height): a transient page that asks for it (`islandPill`,
        // e.g. the OSD folding into a circle)
        readonly property bool pill: root.pageTransient && (stackViewInternal.currentItem?.islandPill ?? false)

        // vtnc: idle height comes from the island settings instead of fixed 44/36
        readonly property int idleHeight: Store.island.height
        // the page's part of the body; an attached notification adds its own below it
        readonly property int pageHeight: Math.max(stackContainer.height, idleHeight)
        readonly property real attachmentHeight: root.transientAttached && attachmentLoader.item ? attachmentLoader.item.implicitHeight : 0
        property int defaultHeight: pageHeight + Math.ceil(attachmentHeight)
        // the height it's going to got smaller: the island style hops (Island.hopUp)
        property int lastDefaultHeight: 0
        onDefaultHeightChanged: {
            if (defaultHeight < lastDefaultHeight)
                root.hopUp();
            lastDefaultHeight = defaultHeight;
        }
        property int islandHeight: defaultHeight

        readonly property string position: "top"

        // Corner size calculation for dynamic width (only for default theme)
        // the body's rounding: the island's own (Island → General → Shape → Rounding) or the theme's (2026-10-28)
        readonly property int roundness: (Store.island.rounding ?? -1) >= 0 ? Math.round(16 * Store.island.rounding) : Tokens.roundness
        readonly property int cornerSize: roundness > 0 ? roundness + 4 : 0
        readonly property int totalCornerWidth: root.notchTheme === "default" ? cornerSize * 2 : 0

        // the body's width (no flares): an app is at least 290 wide, an attached notification widens a
        // narrower island to its minimum
        readonly property real bodyTargetWidth: Math.max(stackContainer.width, screenNotchOpen ? 290 - totalCornerWidth : 0, root.transientAttached ? (attachmentLoader.item?.minIslandWidth ?? 0) : 0)
        implicitWidth: bodyTargetWidth + totalCornerWidth
        implicitHeight: root.notchTheme === "default" ? defaultHeight : (root.notchTheme === "island" ? islandHeight : defaultHeight)

        // vtnc: the size also animates in idle (compact ↔ expanded, widgets appearing), with the
        // kit's expressive spatial curve (its overshoot is the bounce; stage 8, was ambxst's OutBack).
        Behavior on implicitWidth {
            id: widthBehavior
            enabled: K.Kit.anim.enabled
            K.Anim {
                id: widthAnim
                type: K.Anim.BodySpatial
            }
        }

        Behavior on implicitHeight {
            id: heightBehavior
            enabled: K.Kit.anim.enabled
            K.Anim {
                id: heightAnim
                type: K.Anim.BodySpatial
            }
        }

        // Contenedor del notch (solo visual, sin fondo)
        Item {
            id: notchRect
            // vtnc: top-anchored, body height and clipped: when the notch retracts the edge
            // swallows the content instead of moving it; while it morphs, content (and the
            // transition blur) never shows outside the animated body
            anchors.top: parent.top
            anchors.horizontalCenter: parent.horizontalCenter
            anchors.alignWhenCentered: false
            width: parent.width - notchContainer.totalCornerWidth
            height: notchContainer.bodyHeight
            clip: true

            property int defaultRadius: notchContainer.pill ? Math.round(notchContainer.defaultHeight / 2) : (notchContainer.roundness > 0 ? (notchContainer.roomy ? notchContainer.roundness + 20 : notchContainer.roundness + 4) : 0)
            property int islandRadius: notchContainer.pill ? Math.round(notchContainer.defaultHeight / 2) : (notchContainer.roundness > 0 ? (notchContainer.roomy ? notchContainer.roundness + 20 : notchContainer.roundness + 4) : 0)

            property int topLeftRadius: root.notchTheme === "default" ? (notchContainer.position === "bottom" ? defaultRadius : 0) : islandRadius
            property int topRightRadius: root.notchTheme === "default" ? (notchContainer.position === "bottom" ? defaultRadius : 0) : islandRadius
            property int bottomLeftRadius: root.notchTheme === "island" ? islandRadius : (notchContainer.position === "top" ? defaultRadius : 0)
            property int bottomRightRadius: root.notchTheme === "island" ? islandRadius : (notchContainer.position === "top" ? defaultRadius : 0)

            // size the island morphs to: the current page (+ padding while an app is open)
            Item {
                id: stackContainer
                visible: false
                width: stackViewInternal.currentItem ? stackViewInternal.currentItem.implicitWidth + (notchContainer.screenNotchOpen ? 32 : 0) : (notchContainer.screenNotchOpen ? 32 : 0)
                height: stackViewInternal.currentItem ? stackViewInternal.currentItem.implicitHeight + (notchContainer.screenNotchOpen ? 32 : 0) : (notchContainer.screenNotchOpen ? 32 : 0)
            }

            // vtnc: pages follow the animated body (container transform), see PageHost
            PageHost {
                id: stackViewInternal
                anchors.fill: parent
                initialItem: defaultView
                fullHeight: notchContainer.implicitHeight
                targetHeight: notchContainer.pageHeight
                restHeight: notchContainer.idleHeight
                appMargin: 16
                pageScale: Store.theme.anim.pageScale
                // whole pixels only at rest (K.Kit.snap): rounded while the body moved, the pages flipped a pixel
                // back and forth through its overshoot (2026-10-28)
                snap: !root.moving
                // the body's half pixel on screen (the island itself sits at the window's exact centre, the
                // body inside it), taken back so the pages land on whole pixels (2026-10-27); a page that keeps
                // its width keeps the same pixel while the body morphs (its centre doesn't move)
                snapX: Math.round(root.x + root.bodyLeft) - (root.x + root.bodyLeft)
                duration: K.Kit.anim.durations.expressiveDefaultSpatial

                onCurrentItemChanged: notchContainer.updateChildHover()
            }

            // the attached notification ("grow"): under the page (idle or an app), as wide as the island's final width (the
            // body grows around it and clips it while it morphs). Created on first use and kept
            Loader {
                id: attachmentLoader
                property bool used: false
                active: used || root.transientAttached
                onActiveChanged: if (active)
                    used = true
                x: Math.round((notchRect.width - width) / 2)
                y: notchContainer.pageHeight
                Behavior on y {
                    enabled: K.Kit.anim.enabled
                    K.Anim {
                        type: K.Anim.BodySpatial
                    }
                }
                width: notchContainer.bodyTargetWidth
                sourceComponent: Transient.NotificationView {
                    screen: root.screen
                    fixedWidth: notchContainer.bodyTargetWidth
                    topPadding: 2
                    visible: root.transientAttached
                }
            }
        }
    }

    // ---------------------------------------------------------------------------
    // Pages (vtnc apps system)

    DefaultView {
        id: defaultView
        snap: !root.moving
        screen: root.screen
        expanded: root.expanded
        flashedWidgets: root.shownFlashes
    }

    // One view per app and screen, created on first open. Apps with keepAlive keep
    // their view (and state) after closing; the others are destroyed once hidden.
    property var pages: ({})
    property var pendingDestroy: []
    readonly property QtObject currentApp: appOpen ? AppRegistry.get(Runtime.activeApp) : null

    function pageFor(app: QtObject): Item {
        let page = pages[app.appId];
        if (page)
            return page;
        page = app.view.createObject(root, {
            visible: false
        });
        if (page.hasOwnProperty("screen"))
            page.screen = root.screen;
        pages[app.appId] = page;
        return page;
    }

    function releasePage(appId: string) {
        const page = pages[appId];
        if (!page)
            return;
        page.closed?.();
        const app = AppRegistry.get(appId);
        if (app && !app.keepAlive) {
            delete pages[appId];
            pendingDestroy.push(page);
        }
    }

    // the app whose page is alive as the current app (also while a transient covers it)
    property string shownApp: ""
    // what PageHost shows: "" idle, "app:<id>" or "transient:<kind>"
    property string shownKey: ""

    // one page per transient kind, created on first use and kept
    readonly property var transientComponents: ({
            osd: osdTransient,
            notification: notificationTransient
        })
    property var transientPages: ({})
    function transientPageFor(kind: string): Item {
        let page = transientPages[kind];
        if (page)
            return page;
        const component = transientComponents[kind] ?? placeholderTransient;
        page = component.createObject(root, {
            visible: false
        });
        if (page.hasOwnProperty("screen"))
            page.screen = root.screen;
        if (page.hasOwnProperty("islandWidth"))
            page.islandWidth = Qt.binding(() => root.idleRefWidth);
        transientPages[kind] = page;
        return page;
    }
    Component {
        id: placeholderTransient
        Transient.PlaceholderView {}
    }
    Component {
        id: osdTransient
        Transient.OsdView {}
    }
    Component {
        id: notificationTransient
        Transient.NotificationView {}
    }

    // the idle island's width in the mode it's in (compact / expanded; compact under an app), kept
    // from before a transient: the OSD can size its bar to it (osd.fitIsland). Runtime is read
    // directly: when a transient starts, the idle view collapses before transientActive updates
    property real idleRefWidth: 0 // set in Component.onCompleted (top)
    Connections {
        target: defaultView
        function onImplicitWidthChanged() {
            if (Runtime.transientOn(root.screenName) === null)
                root.idleRefWidth = defaultView.implicitWidth;
        }
    }

    // volume / mic / brightness changes → the OSD transient on this screen
    Transient.OsdSource {
        screenName: root.screenName
    }

    // transient > app > idle. A transient over an app keeps the app's page alive (no
    // closed()/destroy), so ending it morphs back to the same page, state and focus included.
    // Coalesced: one change often comes as several (closeApp ends the transient, then clears
    // activeApp); only the final state is shown, never a page in between.
    function syncPage() {
        Qt.callLater(root.applyPage);
    }
    function applyPage() {
        const stack = notchContainer.stackView;
        // an attached notification leaves the page as it is (idle)
        const t = activeTransient?.kind === "notification" && notificationGrows ? null : activeTransient;
        hideHoldTimer.stop();
        if (t) {
            const kind = t.kind;
            const page = transientPageFor(kind);
            page.payload = t.payload;
            if (shownKey !== "transient:" + kind) {
                stack.show(page);
                shownKey = "transient:" + kind;
            }
            return;
        }
        if (appOpen) {
            const app = AppRegistry.get(Runtime.activeApp);
            if (!app) {
                console.warn(`[Island] unknown app "${Runtime.activeApp}"`);
                Runtime.closeApp();
                return;
            }
            if (shownKey === "app:" + app.appId)
                return;
            const fresh = shownApp !== app.appId;
            if (fresh && shownApp !== "")
                releasePage(shownApp);
            const page = pageFor(app);
            stack.show(page);
            shownApp = app.appId;
            shownKey = "app:" + app.appId;
            Qt.callLater(() => {
                page.forceActiveFocus();
                if (fresh)
                    page.opened?.(Runtime.activeAppArgs);
            });
            return;
        }
        if (shownApp !== "") {
            releasePage(shownApp);
            shownApp = "";
        }
        // a transient ending while auto-hide wants the island away: hide straight from the
        // transient's shape (no morph to the idle island first); go idle once it's hidden
        if (shownKey.startsWith("transient:") && concealWanted && K.Kit.anim.enabled) {
            concealTimer.stop();
            revealTimer.stop();
            concealed = true;
            hideHoldTimer.restart();
            return;
        }
        if (shownKey !== "") {
            stack.pop(null);
            shownKey = "";
        }
    }
    Timer {
        id: hideHoldTimer
        interval: K.Kit.anim.durations.expressiveDefaultSpatial
        // still idle (an app or a new transient would have called applyPage, which stops this)
        onTriggered: {
            if (root.activeTransient === null && !root.appOpen && root.shownKey !== "") {
                notchContainer.stackView.pop(null);
                root.shownKey = "";
            }
        }
    }

    // destroy non-keepAlive pages once the exit transition finished
    Connections {
        target: notchContainer.stackView
        function onBusyChanged() {
            const stack = notchContainer.stackView;
            if (stack.busy || root.pendingDestroy.length === 0)
                return;
            for (const p of root.pendingDestroy)
                if (p !== stack.currentItem)
                    p.destroy();
            root.pendingDestroy = [];
        }
    }

    Connections {
        target: Runtime
        function onReopened(appId, args) {
            if (root.showingApp && root.shownApp === appId)
                root.pages[appId]?.opened?.(args);
        }
        function onActiveAppChanged() {
            if (root.appOpen)
                root.syncPage();
        }
    }
}
