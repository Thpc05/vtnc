import QtQuick
import QtQuick.Effects
import Quickshell.Widgets
import qs.kit as K

// A tray icon tinted to one colour while keeping its own shading (caelestia's ColouredIcon /
// Colouriser, rewritten: vtnc has no C++ ImageAnalyser). MultiEffect colourises it fully (each
// pixel = `colour` × its grey level), and the brightness lifts the icon so its dominant tone lands on
// `level` of the colour: caelestia lifts it to 1, which clipped everything lighter and flattened the
// icon into a heavy, saturated blob (user); 0.7 keeps its lights and darks. The lightness is measured
// here: a tiny hidden Canvas draws the icon and averages the HSL lightness of its opaque pixels.
IconImage {
    id: root

    property color colour
    property bool tint: true
    // the icon's dominant lightness (0…1), measured once per source
    property real lightness: 0.5
    // where the dominant tone lands (1 = the full colour, flat)
    property real level: 0.7

    asynchronous: true
    layer.enabled: tint
    layer.effect: MultiEffect {
        colorization: 1
        colorizationColor: root.colour
        brightness: Math.max(0, root.level - root.lightness)
        Behavior on colorizationColor {
            K.CAnim {}
        }
    }

    onSourceChanged: probe.load()
    Component.onCompleted: probe.load()

    Canvas {
        id: probe
        width: 16
        height: 16
        visible: false
        renderTarget: Canvas.Image

        function load() {
            if (root.source === "")
                return;
            if (isImageLoaded(root.source))
                requestPaint();
            else
                loadImage(root.source);
        }
        onImageLoaded: requestPaint()

        onPaint: {
            const ctx = getContext("2d");
            ctx.clearRect(0, 0, width, height);
            if (!isImageLoaded(root.source))
                return;
            ctx.drawImage(root.source, 0, 0, width, height);
            const d = ctx.getImageData(0, 0, width, height).data;
            let sum = 0;
            let n = 0;
            for (let i = 0; i < d.length; i += 4) {
                if (d[i + 3] < 128)
                    continue;
                const r = d[i] / 255, g = d[i + 1] / 255, b = d[i + 2] / 255;
                sum += (Math.max(r, g, b) + Math.min(r, g, b)) / 2;
                n++;
            }
            if (n > 0)
                root.lightness = sum / n;
        }
    }
}
