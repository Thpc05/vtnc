import QtQuick
import QtQuick.Effects
import Quickshell.Io
import qs.core
import qs.dwidgets
import qs.kit as K
import "../catalog.js" as DCatalog

// An image or a GIF from the system (2026-10-27, user; a "single" Dwidget, kept minimal: square sizes). It
// fills its rect (cropped) with the dashboard's rounding, rounded by a mask as the media art
// (media/Art.qml); the Card variant frames it on the card. A GIF plays while the dashboard shows.
// Options: path (Settings → Dashboard → Layout: typed or Browse…), speed (a GIF's, 0.25× … 2×), fit
// (crop · fit · stretch) and focus (what a crop keeps: center · top · bottom · left · right), and
// (2026-10-27, user) source "file" | "folder": a folder's random image (never the same twice in a row),
// changing on `change`: "open" (each dashboard open), "start" (each shell start) or "timer" (every
// `minutes`). The pick outlives the Dwidget (ImagePicks, by the entry's uid).
Dwidget {
    id: root

    // the entry's uid (Cell.qml), the folder pick's key
    property string uid
    readonly property bool card: DCatalog.isCard("image", root.style)
    // how it fills the rect (2026-10-27, user): crop (fills it, cut to the focus), fit (whole, with room
    // around it) or stretch; the focus is the part a crop keeps
    readonly property int fillMode: root.options?.fit === "fit" ? Image.PreserveAspectFit : root.options?.fit === "stretch" ? Image.Stretch : Image.PreserveAspectCrop
    readonly property string cropFocus: root.options?.focus || "center"
    readonly property int hAlign: cropFocus === "left" ? Image.AlignLeft : cropFocus === "right" ? Image.AlignRight : Image.AlignHCenter
    readonly property int vAlign: cropFocus === "top" ? Image.AlignTop : cropFocus === "bottom" ? Image.AlignBottom : Image.AlignVCenter
    readonly property bool fromFolder: root.options?.source === "folder"
    readonly property string folder: Store.expandPath(root.options?.folder ?? "")
    readonly property string change: root.options?.change || "open"
    readonly property int minutes: Math.max(1, root.options?.minutes ?? 30)
    // the folder's pick (from ImagePicks, so it survives the dashboard making the Dwidget again)
    readonly property var pick: root.uid !== "" ? ImagePicks.picks[root.uid] ?? null : null
    readonly property string path: fromFolder ? (pick && pick.folder === folder ? pick.path : "") : Store.expandPath(root.options?.path ?? "")
    // animated: a .gif, or a file without a still image's extension (the reader goes by the content then,
    // so "gif" or "jpg(1)" work; a still one is a single frame)
    readonly property bool gif: path !== "" && !/\.(png|jpe?g|webp|svg|bmp)$/i.test(path)
    readonly property string url: path === "" ? "" : "file://" + path
    readonly property Item shown: gif ? animated : still
    readonly property bool ready: url !== "" && shown.status === Image.Ready

    // the folder ---------------------------------------------------------------------------------
    // its files (not hidden ones; any kind: a file without an extension may be an image), listed again
    // before each new pick so new ones count
    property var files: []
    Process {
        id: lister
        command: ["find", "-L", root.folder, "-maxdepth", "1", "-type", "f", "!", "-name", ".*"]
        stdout: StdioCollector {
            onStreamFinished: {
                root.files = text.split("\n").filter(l => l !== "").sort();
                root.decide(lister.forced);
            }
        }
        property bool forced: false
    }
    function list(force: bool) {
        if (!fromFolder || folder === "" || uid === "" || lister.running)
            return;
        lister.forced = force;
        lister.running = true;
    }
    // keep the pick, or take a new one: always when `force`; else when there's none for this folder (or
    // its file is gone), when the dashboard opened since ("open"), or when it's older than the timer
    function decide(force: bool) {
        if (files.length === 0)
            return;
        const p = ImagePicks.get(uid);
        const valid = p !== null && p.folder === folder && files.includes(p.path);
        const stale = change === "open" ? p?.opens !== DashboardShape.opens : change === "timer" ? Date.now() - (p?.time ?? 0) >= minutes * 60000 : false;
        if (!force && valid && !stale)
            return;
        const pool = files.length > 1 && valid ? files.filter(f => f !== p.path) : files;
        ImagePicks.set(uid, folder, pool[Math.floor(Math.random() * pool.length)], DashboardShape.opens);
    }
    Component.onCompleted: list(false)
    onFolderChanged: list(false)
    onFromFolderChanged: list(false)
    onUidChanged: list(false)
    onChangeChanged: list(false)
    readonly property int opens: DashboardShape.opens
    onOpensChanged: if (change === "open")
        list(false)
    // the timer: checks every 30 s whether the pick is due (it runs only while the Dwidget exists)
    Timer {
        interval: 30000
        repeat: true
        running: root.fromFolder && root.change === "timer"
        onTriggered: {
            const p = ImagePicks.get(root.uid);
            if (!p || Date.now() - p.time >= root.minutes * 60000)
                root.list(true);
        }
    }

    DwidgetCard {
        id: cardHost
        anchors.fill: parent
        card: root.card
    }

    Item {
        id: frame
        anchors.fill: parent
        anchors.margins: cardHost.pad
        // the card's rounding, inset with the padding
        readonly property real radius: Math.max(4, cardHost.radius - cardHost.pad)

        Rectangle {
            anchors.fill: parent
            visible: !root.ready
            radius: frame.radius
            color: cardHost.pal.off
        }
        Rectangle {
            id: mask
            anchors.fill: parent
            radius: frame.radius
            visible: false
            layer.enabled: true
        }

        Image {
            id: still
            anchors.fill: parent
            visible: !root.gif && root.ready
            source: root.gif ? "" : root.url
            fillMode: root.fillMode
            horizontalAlignment: root.hAlign
            verticalAlignment: root.vAlign
            asynchronous: true
            sourceSize: Qt.size(Math.round(root.targetWidth * 2), Math.round(root.targetHeight * 2))
            layer.enabled: true
            layer.effect: MultiEffect {
                maskEnabled: true
                maskSource: mask
                maskThresholdMin: 0.5
                maskSpreadAtMin: 1
                autoPaddingEnabled: false
            }
        }
        AnimatedImage {
            id: animated
            anchors.fill: parent
            visible: root.gif && root.ready
            source: root.gif ? root.url : ""
            fillMode: root.fillMode
            horizontalAlignment: root.hAlign
            verticalAlignment: root.vAlign
            // local and small: loaded at once (asynchronous loading raced the source changes below)
            asynchronous: false
            playing: root.gif
            // options.speed (2026-10-27, user): 0.25× … 2×
            speed: Math.max(0.1, Math.min(4, root.options?.speed ?? 1))
            // a folder's new pick lands as the dashboard opens, while the page is still hidden, and Qt
            // pauses a hidden GIF (it stayed still, user): start it again once it's loaded and once it shows
            function restart() {
                if (!root.gif || status !== AnimatedImage.Ready || !visible)
                    return;
                playing = false;
                Qt.callLater(() => {
                    animated.currentFrame = 0;
                    animated.playing = root.gif;
                });
            }
            onStatusChanged: restart()
            onVisibleChanged: restart()
            layer.enabled: true
            layer.effect: MultiEffect {
                maskEnabled: true
                maskSource: mask
                maskThresholdMin: 0.5
                maskSpreadAtMin: 1
                autoPaddingEnabled: false
            }
        }

        // nothing picked, or it didn't load
        Column {
            anchors.centerIn: parent
            visible: !root.ready
            spacing: 4

            K.MaterialIcon {
                anchors.horizontalCenter: parent.horizontalCenter
                text: root.url === "" ? "image" : root.shown.status === Image.Error ? "broken_image" : "hourglass_empty"
                size: 2 * Math.round(Math.min(root.targetWidth, root.targetHeight) / 8)
                color: cardHost.pal.overVariant
            }
            K.StyledText {
                anchors.horizontalCenter: parent.horizontalCenter
                visible: root.targetWidth >= 140 && (root.url === "" || root.shown.status === Image.Error)
                text: root.url !== "" ? "Can't open it" : root.fromFolder && root.folder !== "" ? "No images" : root.fromFolder ? "Pick a folder" : "Pick an image"
                font.family: K.Kit.family
                font.variableAxes: K.Kit.axes
                font.pixelSize: 12
                color: cardHost.pal.overVariant
            }
        }
    }
}
