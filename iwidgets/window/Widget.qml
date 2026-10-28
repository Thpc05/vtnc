import QtQuick
import Quickshell
import Quickshell.Widgets
import Quickshell.Io
import qs.core
import qs.services
import qs.kit as K

// The focused window's title (2026-10-11, user). With none focused (island.window.idle, 2026-10-15): a text
// ("Desktop" by default) with an image as its mark (the desktop symbol without one), or the current track
// ("Title — Artist", split like a title; the note as its mark), the text when nothing plays. Display only:
// no click or hover (user). Styles, each a lead mark and the title, which cross-fades when it changes:
//  - icon: the app's own icon and the title
//  - tones: the app's icon, the title in the accent bold and its "— App" part weak (media's Two tones)
//  - shapes: the app's kind as a Material symbol on an accent M3 shape (a new random shape per app,
//    morphing; the workspaces' Shapes) and the title
//  - tone (was "category"): the app's kind as a symbol and the title, both in the accent (after
//    caelestia's bar; next to Two tones, user)
// Each also comes on the island card (Card variants: `pal`). Options per island mode (Island → Layout →
// Active window, island.window.compact / expanded): showIcon (the lead mark), text (first / second / both
// / none: the title's parts around its dash, "Page — App"), maxWidth, weight. Nothing to show (no icon,
// no text) → width 0, the slot collapses.
Item {
    id: root

    property string style: "icon"
    // from the frame: the island mode and the palette (the island card's, or the bare island's)
    property string mode: "compact"
    property var pal: K.Kit.bare

    readonly property var options: Store.island.window?.[mode] ?? ({})
    readonly property real maxWidth: Math.max(60, options.maxWidth || 200)
    readonly property int weight: (options.weight ?? 0) > 0 ? options.weight : 600
    readonly property bool showIcon: options.showIcon ?? true
    // first / second / both / none
    readonly property string textMode: options.text || "both"

    // the focused window, while it's on the focused workspace: Hyprland keeps the last one active when
    // focus moves to an empty workspace (the title stayed; only closing it showed Desktop — user).
    // A special workspace (negative id) over it still counts.
    readonly property var toplevel: {
        const t = Hypr.activeToplevel;
        const ws = t?.workspace ?? null;
        const focused = Hypr.focusedWorkspace;
        if (!t || (ws && focused && ws.id > 0 && ws.id !== focused.id))
            return null;
        return t;
    }
    readonly property bool desktop: !toplevel
    // with no window: the text or the current track
    readonly property var idle: Store.island.window?.idle ?? ({})
    readonly property var player: MprisController.activePlayer
    readonly property bool idleMedia: desktop && idle.show === "media" && (player?.trackTitle ?? "") !== ""
    // the configured image, used only once it's known to exist (a missing one, ~/.face by default, falls
    // back to the desktop symbol without a warning; one that shows up later is picked up)
    readonly property string idlePath: {
        const i = idle.image ?? "";
        return i === "" ? "" : Store.expandPath(i.replace(/^file:\/\//, ""));
    }
    property bool idleImageFound: false
    FileView {
        path: root.idlePath
        printErrors: false
        watchChanges: true
        onLoaded: root.idleImageFound = true
        onLoadFailed: root.idleImageFound = false
        onFileChanged: reload()
        onPathChanged: root.idleImageFound = false
    }
    readonly property string idleImage: desktop && !idleMedia && idleImageFound ? "file://" + idlePath : ""
    readonly property string idleText: idleMedia ? [player.trackTitle, player.trackArtist ?? ""].filter(s => s !== "").join(" — ") : (idle.text ?? "Desktop")
    readonly property string appId: toplevel?.wayland?.appId || toplevel?.lastIpcObject?.class || ""
    readonly property var entry: appId !== "" ? DesktopEntries.heuristicLookup(appId) : null
    readonly property string appIcon: appId !== "" ? Quickshell.iconPath(entry?.icon || appId.toLowerCase(), true) : ""
    readonly property string appName: desktop ? "" : entry?.name || appId
    readonly property string symbol: idleMedia ? "music_note" : desktop ? "desktop_windows" : Apps.categorySymbol(entry?.categories ?? [])
    // the text right now: [main, secondary]. "Page — App" (" - ", " – ", " — "; the last one splits):
    // first = "Page", second = "App" (a title without a dash is both), both = all of it. Two tones splits
    // "both" into its two tones: "Page" strong, "App" weak (without a dash: the title and the app's name);
    // first / second are one part in one tone there too (user: Two tones showed both parts in "first")
    readonly property var live: {
        if (textMode === "none")
            return ["", ""];
        const t = desktop ? idleText : toplevel?.title ?? "";
        if (t === "")
            return [desktop ? "" : appName, ""];
        // the last separator (no matchAll in QML's JS)
        const re = /\s+[\-–—]\s+/g;
        let last = null;
        for (let m = re.exec(t); m; m = re.exec(t))
            last = m;
        const head = last ? t.slice(0, last.index).trim() : t;
        const tail = last ? t.slice(last.index + last[0].length).trim() : "";
        if (textMode === "first")
            return [head, ""];
        if (textMode === "second")
            return [last ? tail : t, ""];
        if (style !== "tones")
            return [t, ""];
        if (last)
            return [head, tail];
        return [t, appName.toLowerCase() !== t.toLowerCase() ? appName : ""];
    }

    // what's shown: `live`, settled. Some apps retitle a few times as they open (kitty: "kitty" →
    // "fish" → "~ - fish" in ~0.35 s, the title flickered — user). A change after a quiet spell shows at
    // once (switching windows stays instant); changes coming close behind it wait until the title has
    // been still for `settleMs`, or `maxWaitMs` at most (a title that never stops, a progress counter,
    // still updates). caelestia only cross-fades every change; ambxst has no window title.
    property string title: ""
    property string sub: ""
    readonly property int settleMs: 300
    readonly property int maxWaitMs: 1200
    property double lastCommit: 0
    function commit() {
        settle.stop();
        maxWait.stop();
        title = live[0];
        sub = live[1];
        lastCommit = Date.now();
    }
    onLiveChanged: {
        if (live[0] === title && live[1] === sub)
            return;
        if (!settle.running && Date.now() - lastCommit > settleMs) {
            commit();
        } else {
            settle.restart();
            if (!maxWait.running)
                maxWait.start();
        }
    }
    Component.onCompleted: commit()
    Timer {
        id: settle
        interval: root.settleMs
        onTriggered: root.commit()
    }
    Timer {
        id: maxWait
        interval: root.maxWaitMs
        onTriggered: root.commit()
    }

    readonly property real leadSize: showIcon ? (style === "shapes" ? 22 : 16) : 0
    readonly property int gap: 6
    // Two tones' weak part
    readonly property bool showApp: sub !== ""
    readonly property real textX: showIcon && title !== "" ? leadSize + gap : 0
    readonly property real textRoom: maxWidth - textX
    readonly property color titleColor: style === "tones" || style === "tone" ? pal.accent : pal.over

    // the final width; the slot animates to it (with the island's curve) and hands the animated width
    // back (`fillsSlot`): the content is laid out from the left and revealed / covered as it moves.
    // Centred at its final width, a new title showed whole at once while the island and its
    // neighbours took their time to make room (user)
    readonly property bool fillsSlot: true
    readonly property real targetWidth: Math.ceil(textX + (title !== "" ? titleText.textWidth : showIcon ? leadSize : 0) + (showApp && appText.textWidth > 0 ? gap + appText.textWidth : 0))
    implicitWidth: targetWidth
    implicitHeight: 24
    clip: true

    // the lead: the app's icon (its symbol without one), or the symbol (bare or on a shape)
    Item {
        id: lead
        anchors.verticalCenter: parent.verticalCenter
        visible: root.showIcon
        width: root.leadSize
        height: root.leadSize

        IconImage {
            anchors.fill: parent
            visible: (root.style === "icon" || root.style === "tones") && root.appIcon !== ""
            source: root.appIcon
            asynchronous: true
        }
        // no window: the idle image, in every style
        Image {
            id: idleImage
            anchors.fill: parent
            visible: root.idleImage !== "" && status === Image.Ready
            source: root.idleImage
            sourceSize: Qt.size(64, 64)
            fillMode: Image.PreserveAspectFit
            asynchronous: true
            mipmap: true
        }
        K.M3Shape {
            id: shape
            anchors.fill: parent
            visible: root.style === "shapes" && !idleImage.visible
            color: root.pal.accent

            readonly property var shapes: ["cookie4", "cookie6", "cookie7", "cookie9", "cookie12", "sunny", "softBurst", "clover4", "clover8"]
            function pick() {
                shape.shape = shapes[Math.floor(Math.random() * shapes.length)];
            }
            Component.onCompleted: pick()
            Connections {
                target: root
                function onAppIdChanged() {
                    shape.pick();
                }
            }
        }
        K.MaterialIcon {
            x: Math.round((parent.width - width) / 2)
            y: Math.round((parent.height - height) / 2)
            visible: !idleImage.visible && (root.style === "shapes" || root.style === "tone" || root.appIcon === "")
            text: root.symbol
            size: root.style === "shapes" ? 14 : 16
            fill: root.style === "shapes" ? 1 : 0
            color: root.style === "shapes" ? root.pal.overAccent : root.style === "tone" ? root.pal.accent : root.pal.overVariant
        }
    }

    TitleText {
        id: titleText
        anchors.verticalCenter: parent.verticalCenter
        x: root.textX
        text: root.title
        maxWidth: root.showApp ? root.textRoom * 0.65 : root.textRoom
        color: root.titleColor
        weight: root.style === "tones" ? Math.max(700, root.weight) : root.weight
    }
    TitleText {
        id: appText
        anchors.verticalCenter: parent.verticalCenter
        x: titleText.x + titleText.textWidth + root.gap
        visible: root.showApp
        text: root.sub
        maxWidth: Math.max(0, root.textRoom - titleText.textWidth - root.gap)
        color: root.pal.weak
        weight: 500
        pixelSize: 11
    }
}
