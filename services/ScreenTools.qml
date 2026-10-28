pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Io
import qs.core

// Screenshot / screen recording / color picker / OCR.
// Tools: grim + slurp, gpu-screen-recorder, hyprpicker, tesseract, wl-copy, notify-send.
// Actions are usually started through Runtime.closeThen() so the island is closed first.
Singleton {
    id: root

    readonly property string screenshotsDir: Store.expandPath(Store.tools.screenshotsDir)
    readonly property string recordingsDir: Store.expandPath(Store.tools.recordingsDir)

    // Region selection = plain slurp. It always reads stdin (predefined boxes) when stdin isn't a
    // terminal, so every call gets </dev/null — a Process keeps an open pipe and slurp would
    // wait on it forever without ever showing up.

    // Recording state
    readonly property bool recording: recorder.started
    property string recordingFile: ""
    property real recordingStart: 0
    property int elapsed: 0          // seconds, updated while recording
    readonly property string elapsedText: {
        const m = Math.floor(elapsed / 60), s = elapsed % 60;
        return `${m}:${s < 10 ? "0" : ""}${s}`;
    }

    function run(script: string, args: var) {
        Quickshell.execDetached(["sh", "-c", script, "sh", ...args]);
    }

    // Screenshots -------------------------------------------------------------
    // mode: "region" | "screen" (focused monitor)
    function screenshot(mode: string, monitor: string) {
        run(`
            dir="$1"; mode="$2"; mon="$3"; shift 3
            mkdir -p "$dir"
            f="$dir/$(date +%Y-%m-%d_%H-%M-%S).png"
            if [ "$mode" = region ]; then
                g=$(slurp </dev/null) || exit 0
                grim -g "$g" "$f" || exit 1
            else
                grim -o "$mon" "$f" || exit 1
            fi
            wl-copy --type image/png < "$f"
            notify-send -a vtnc -i "$f" "Screenshot saved" "Copied to clipboard"
        `, [screenshotsDir, mode, monitor]);
    }

    // Color picker / OCR ------------------------------------------------------
    function pickColor() {
        run(`
            c=$(hyprpicker -a -f hex) || exit 0
            [ -n "$c" ] && notify-send -a vtnc "Color copied" "$c"
        `, []);
    }

    function ocr() {
        run(`
            lang="$1"; shift
            g=$(slurp </dev/null) || exit 0
            t=$(grim -g "$g" - | tesseract - - -l "$lang" 2>/dev/null)
            if [ -n "$(printf %s "$t" | tr -d '[:space:]')" ]; then
                printf %s "$t" | wl-copy
                notify-send -a vtnc "Text copied" "$t"
            else
                notify-send -a vtnc "No text found"
            fi
        `, [Store.tools.ocrLang]);
    }

    // Recording ---------------------------------------------------------------
    // mode: "region" | "screen" | "audio" (drag = region, click = whole monitor; records
    // system audio + microphone mixed in one track)
    function startRecording(mode: string, monitor: string) {
        if (recorder.running)
            return;
        recorder.started = false;
        recorder.command = ["sh", "-c", `
            dir="$1"; mode="$2"; mon="$3"; fps="$4"; shift 4
            mkdir -p "$dir"
            f="$dir/$(date +%Y-%m-%d_%H-%M-%S).mp4"
            case "$mode" in
                region) g=$(slurp -f "%wx%h+%x+%y" </dev/null) || exit 0; set -- -w region -region "$g" ;;
                audio)  g=$(slurp -o -f "%wx%h+%x+%y" </dev/null) || exit 0; set -- -w region -region "$g" -a "default_output|default_input" ;;
                *)      set -- -w "$mon" ;;
            esac
            echo "FILE:$f"
            exec gpu-screen-recorder "$@" -f "$fps" -o "$f"
        `, "sh", recordingsDir, mode, monitor, String(Store.tools.recordFps)];
        recorder.running = true;
    }

    function stopRecording() {
        if (!recorder.running)
            return;
        // gpu-screen-recorder crashes (corrupt file) if interrupted right after starting
        const age = Date.now() - recordingStart;
        if (age < 2500) {
            stopDelay.interval = 2500 - age;
            stopDelay.restart();
        }
        else
            recorder.signal(2); // SIGINT → finalize file
    }

    Timer {
        id: stopDelay
        onTriggered: recorder.signal(2)
    }

    Timer {
        running: root.recording
        interval: 1000
        repeat: true
        triggeredOnStart: true
        onTriggered: root.elapsed = Math.floor((Date.now() - root.recordingStart) / 1000)
    }

    Process {
        id: recorder
        property bool started: false

        stdout: SplitParser {
            onRead: line => {
                if (line.startsWith("FILE:")) {
                    root.recordingFile = line.slice(5);
                    root.recordingStart = Date.now();
                    root.elapsed = 0;
                    recorder.started = true;
                }
            }
        }

        onExited: code => {
            const file = root.recordingFile;
            if (started && file !== "")
                Quickshell.execDetached(["sh", "-c", 'if [ -s "$1" ]; then notify-send -a vtnc "Recording saved" "$1"; else notify-send -a vtnc -u critical "Recording failed" "$1"; fi', "sh", file]);
            started = false;
            root.recordingFile = "";
            root.elapsed = 0;
        }
    }
}
