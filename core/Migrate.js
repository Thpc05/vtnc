.pragma library

// The one-file state (~/.local/state/vtnc/vtnc-state.json, schema ≤ 4) split into the files of
// core/STATE.md: island / dashboard / appearance / system in ~/.config/vtnc, state in
// ~/.local/state/vtnc. Keys that moved:
//   controls.nightLightTemp → system nightLight.temp
//   media.player → state player.pinned
//   apps.{tools,session}.showHints → system hints.{tools,session}
//   wallpaper.dir / transition → system wallpapers.*
// Only what the old file had is copied; each file's merge fills the rest.

var FILES = ["island", "dashboard", "appearance", "system", "state"];

function isObject(v) {
    return v !== null && typeof v === "object" && !Array.isArray(v);
}

function copy(v) {
    return v === undefined ? undefined : JSON.parse(JSON.stringify(v));
}

// { key: value } without the undefined values
function pick(o) {
    var out = {};
    for (var k in o)
        if (o[k] !== undefined)
            out[k] = o[k];
    return out;
}

function split(old) {
    var s = isObject(old) ? old : {};
    var wallpaper = isObject(s.wallpaper) ? s.wallpaper : {};
    var controls = isObject(s.controls) ? copy(s.controls) : undefined;
    var media = isObject(s.media) ? s.media : {};
    var apps = isObject(s.apps) ? copy(s.apps) : undefined;

    var nightTemp = controls ? controls.nightLightTemp : undefined;
    if (controls)
        delete controls.nightLightTemp;

    var hints = {};
    if (apps) {
        ["tools", "session"].forEach(function (id) {
            if (isObject(apps[id]) && "showHints" in apps[id]) {
                hints[id] = apps[id].showHints;
                delete apps[id].showHints;
                if (Object.keys(apps[id]).length === 0)
                    delete apps[id];
            }
        });
    }

    return {
        island: pick({
            island: copy(s.island),
            osd: copy(s.osd)
        }),
        dashboard: pick({
            dashboard: copy(s.dashboard)
        }),
        appearance: pick({
            theme: copy(s.theme),
            corners: copy(s.corners),
            wallpaper: "current" in wallpaper ? { current: wallpaper.current } : undefined
        }),
        system: pick({
            wallpapers: pick({
                dir: wallpaper.dir,
                transition: wallpaper.transition
            }),
            tools: copy(s.tools),
            audio: copy(s.audio),
            media: "enableFirefoxPlayer" in media ? { enableFirefoxPlayer: media.enableFirefoxPlayer } : undefined,
            nightLight: nightTemp !== undefined ? { temp: nightTemp } : undefined,
            hints: hints
        }),
        state: pick({
            controls: controls,
            player: "player" in media ? { pinned: media.player } : undefined,
            apps: apps
        })
    };
}
