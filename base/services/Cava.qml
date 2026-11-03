pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Io

// Audio bars from cava (raw ascii output, values in 0..1), for visualizers, one cava per bar count in
// use (2026-10-09): each bar is then a real frequency band with its own sensitivity (averaging 48 bars
// down to a few cancelled the peaks: few bars moved as in slow motion, user). acquire(n) when a
// visualizer of n bars shows, release(n) when it hides; valuesFor(n) reads them (zeros until it runs).
// The processes are made and destroyed one by one (not a model: a changed list would restart the ones
// already running). Without the cava binary the values stay flat.
Singleton {
    id: root

    // n → holders, n → its process, n → its latest values
    property var users: ({})
    property var procs: ({})
    property var values: ({})

    function clampBars(n: int): int {
        return Math.max(2, Math.min(64, n || 48));
    }

    function acquire(n: int) {
        n = clampBars(n);
        const u = Object.assign({}, users);
        u[n] = (u[n] ?? 0) + 1;
        users = u;
        if (!procs[n]) {
            const p = Object.assign({}, procs);
            p[n] = cavaComponent.createObject(root, {
                bars: n
            });
            procs = p;
        }
    }

    function release(n: int) {
        n = clampBars(n);
        const u = Object.assign({}, users);
        u[n] = Math.max(0, (u[n] ?? 0) - 1);
        if (u[n] === 0) {
            delete u[n];
            procs[n]?.destroy();
            const p = Object.assign({}, procs);
            delete p[n];
            procs = p;
            const v = Object.assign({}, values);
            delete v[n];
            values = v;
        }
        users = u;
    }

    function valuesFor(n: int): var {
        n = clampBars(n);
        return values[n] ?? Array(n).fill(0);
    }

    function setValues(n: int, list: var) {
        const v = Object.assign({}, values);
        v[n] = list;
        values = v;
    }

    // cava's config for `bars`, handed over through a process substitution (no file on disk)
    function config(bars: int): string {
        return ["[general]", "bars = " + bars, "framerate = 60", "autosens = 1", "[input]", "method = pipewire", "source = auto", "[output]", "method = raw", "raw_target = /dev/stdout", "data_format = ascii", "ascii_max_range = 1000", "bar_delimiter = 59", "frame_delimiter = 10", "[smoothing]", "noise_reduction = 60"].join("\n");
    }

    Component {
        id: cavaComponent

        Process {
            id: proc
            property int bars: 48

            running: true
            command: ["bash", "-c", "exec cava -p <(printf '%s\\n' \"$1\")", "cava", root.config(bars)]

            stdout: SplitParser {
                onRead: line => {
                    const parts = line.split(";");
                    const out = [];
                    for (let i = 0; i < proc.bars; i++)
                        out.push(Math.min(1, (parseInt(parts[i]) || 0) / 1000));
                    root.setValues(proc.bars, out);
                }
            }
        }
    }
}
