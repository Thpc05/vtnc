import QtQuick

// The frame-rate meter (`qs -c vtnc ipc call shell perf on`, off by default): once a second while its
// window draws, one log line "[perf] <screen> fps N worst X ms slow K" (worst = the longest gap between
// two frames of that second, slow = gaps over 25 ms); after the drawing stops, one "[perf] <screen> idle".
// An idle shell draws nothing, so it logs nothing more. The times are taken when the GUI thread gets
// the render thread's frameSwapped, so they are close, not exact.
Item {
    id: meter

    required property string name

    property int frames: 0
    property real last: 0
    property real worst: 0
    property int slow: 0
    property bool drawing: false

    Connections {
        target: meter.Window.window
        function onFrameSwapped() {
            const now = Date.now();
            const gap = now - meter.last;
            // a gap over 250 ms is a pause between two drawings, not a slow frame
            if (meter.last > 0 && gap < 250) {
                meter.worst = Math.max(meter.worst, gap);
                if (gap > 25)
                    meter.slow++;
            }
            meter.last = now;
            meter.frames++;
        }
    }

    Timer {
        interval: 1000
        running: true
        repeat: true
        onTriggered: {
            if (meter.frames > 0)
                console.info(`[perf] ${meter.name} fps ${meter.frames} worst ${meter.worst} ms slow ${meter.slow}`);
            else if (meter.drawing)
                console.info(`[perf] ${meter.name} idle`);
            meter.drawing = meter.frames > 0;
            meter.frames = 0;
            meter.worst = 0;
            meter.slow = 0;
        }
    }
}
