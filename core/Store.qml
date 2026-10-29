pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Io
import "Migrate.js" as Migrate

// Persistent settings and state (core/STATE.md):
//  - ~/.config/vtnc/{island,dashboard,appearance,system}.json: what the user configures
//    (island / dashboard / appearance are what a preset saves, services/Presets.qml)
//  - ~/.local/state/vtnc/state.json: what the shell remembers (toggles, pinned player, apps' UI)
// Factory defaults live in defaults/config/*.json and defaults/state.json. The old one-file state
// (~/.local/state/vtnc/vtnc-state.json) is split into these on the first start (core/Migrate.js).
Singleton {
    id: root

    readonly property string configDir: (Quickshell.env("XDG_CONFIG_HOME") || Quickshell.env("HOME") + "/.config") + "/vtnc"
    readonly property string stateDir: (Quickshell.env("XDG_STATE_HOME") || Quickshell.env("HOME") + "/.local/state") + "/vtnc"
    readonly property string presetsDir: configDir + "/presets"
    readonly property string factoryDir: Quickshell.shellDir + "/defaults"
    // the preset made from a migrated state
    readonly property string migratedPreset: "My setup"

    readonly property var files: ({
            island: islandFile,
            dashboard: dashboardFile,
            appearance: appearanceFile,
            system: systemFile,
            state: stateFile
        })

    // true once every file was loaded and validated at least once
    readonly property bool ready: islandFile.ready && dashboardFile.ready && appearanceFile.ready && systemFile.ready && stateFile.ready

    // island.json
    property alias island: islandAdapter.island
    property alias osd: islandAdapter.osd
    // dashboard.json
    property alias dashboard: dashboardAdapter.dashboard
    // appearance.json
    property alias theme: appearanceAdapter.theme
    property alias frame: appearanceAdapter.frame
    property alias wallpaper: appearanceAdapter.wallpaper
    // system.json
    property alias wallpapers: systemAdapter.wallpapers
    property alias tools: systemAdapter.tools
    property alias audio: systemAdapter.audio
    property alias media: systemAdapter.media
    property alias nightLight: systemAdapter.nightLight
    property alias hints: systemAdapter.hints
    property alias alerts: systemAdapter.alerts
    // the island apps' options (Settings → Apps; `Store.apps` is their remembered state, state.json)
    property alias appOptions: systemAdapter.apps
    // state.json
    property alias controls: stateAdapter.controls
    property alias player: stateAdapter.player
    property alias presets: stateAdapter.presets
    property alias apps: stateAdapter.apps

    function resetToDefaults() {
        console.info("[Store] restoring factory defaults");
        for (const k in files)
            files[k].resetToFactory();
    }

    // "~/x" → "/home/user/x"
    function expandPath(path: string): string {
        return path.startsWith("~/") ? Quickshell.env("HOME") + path.slice(1) : path;
    }

    // Per-app persistent storage (apps.<id>.<key>)
    function appGet(appId, key, fallback) {
        const a = stateAdapter.apps?.[appId];
        return a && a[key] !== undefined ? a[key] : fallback;
    }

    function appSet(appId, key, value) {
        const apps = Object.assign({}, stateAdapter.apps);
        apps[appId] = Object.assign({}, apps[appId]);
        apps[appId][key] = value;
        stateAdapter.apps = apps;
    }

    // bootstrap: directories, the migration (once), missing files from the factory, then load
    function open() {
        islandFile.path = configDir + "/island.json";
        dashboardFile.path = configDir + "/dashboard.json";
        appearanceFile.path = configDir + "/appearance.json";
        systemFile.path = configDir + "/system.json";
        stateFile.path = stateDir + "/state.json";
    }

    function migrate(text: string) {
        let old;
        try {
            old = JSON.parse(text);
        } catch (e) {
            console.warn("[Store] the old vtnc-state.json is not valid JSON, not migrating:", e);
            install.running = true;
            return;
        }
        console.info("[Store] migrating vtnc-state.json to", configDir);
        const parts = Migrate.split(old);
        const out = {};
        for (const k in files)
            out[k] = files[k].merged(parts[k]);
        out.state.presets = {
            active: migratedPreset
        };
        const now = new Date().toISOString();
        const preset = {
            name: migratedPreset,
            created: now,
            updated: now,
            config: {
                island: out.island,
                dashboard: out.dashboard,
                appearance: out.appearance
            }
        };
        const json = v => JSON.stringify(v, null, 2) + "\n";
        writeMigration.command = ["sh", "-c", 'set -e; cfg=$1; st=$2; w() { printf "%s" "$2" > "$1.tmp" && mv "$1.tmp" "$1"; }; w "$cfg/island.json" "$3"; w "$cfg/dashboard.json" "$4"; w "$cfg/appearance.json" "$5"; w "$cfg/system.json" "$6"; w "$st/state.json" "$7"; w "$cfg/presets/$9.json" "$8"; mv -f "$st/vtnc-state.json" "$st/vtnc-state.json.migrated"; rm -f "$st/vtnc-state-default.json"', "sh", configDir, stateDir, json(out.island), json(out.dashboard), json(out.appearance), json(out.system), json(out.state), json(preset), migratedPreset];
        writeMigration.running = true;
    }

    Process {
        id: probe
        running: true
        command: ["sh", "-c", 'mkdir -p "$1/presets" "$2" && { [ -e "$1/island.json" ] || [ ! -f "$2/vtnc-state.json" ] || cat "$2/vtnc-state.json"; }', "sh", root.configDir, root.stateDir]
        stdout: StdioCollector {
            id: probeOut
        }
        stderr: StdioCollector {
            onStreamFinished: if (text.trim() !== "")
                console.error("[Store] bootstrap:", text.trim())
        }
        onExited: code => {
            if (code === 0 && probeOut.text.trim() !== "")
                root.migrate(probeOut.text);
            else
                install.running = true;
        }
    }

    Process {
        id: writeMigration
        stderr: StdioCollector {
            onStreamFinished: if (text.trim() !== "")
                console.error("[Store] migration:", text.trim())
        }
        onExited: code => {
            if (code !== 0)
                console.error("[Store] migration failed with code", code);
            install.running = true;
        }
    }

    // any missing file comes from the factory
    Process {
        id: install
        command: ["sh", "-c", 'cfg=$1; st=$2; fac=$3; for f in island dashboard appearance system; do [ -f "$cfg/$f.json" ] || install -m 644 "$fac/config/$f.json" "$cfg/$f.json"; done; [ -f "$st/state.json" ] || install -m 644 "$fac/state.json" "$st/state.json"', "sh", root.configDir, root.stateDir, root.factoryDir]
        stderr: StdioCollector {
            onStreamFinished: if (text.trim() !== "")
                console.error("[Store] bootstrap:", text.trim())
        }
        onExited: code => {
            if (code !== 0)
                console.error("[Store] bootstrap failed with code", code);
            root.open();
        }
    }

    ConfigFile {
        id: islandFile
        factoryPath: root.factoryDir + "/config/island.json"
        adapter: JsonAdapter {
            id: islandAdapter

            property int version

            property JsonObject island: JsonObject {
                property string style
                property int minWidth
                property int minWidthExpanded
                property int height
                property int heightExpanded
                property int margin
                property int padding
                // the body's corner rounding, its own multiplier over the 16 px base (Island → General → Shape,
                // 2026-10-28); below 0 = the theme's (Appearance → General → Scale → Rounding)
                property real rounding
                // the sections (Island → Anchors), per island mode (2026-10-15): the centre kept in the
                // middle, the gap between a section's widgets and between the sections, a card behind each
                property JsonObject anchors: JsonObject {
                    property JsonObject compact: JsonObject {
                        property bool anchorCenter
                        property int gap
                        property int between
                        property JsonObject left: JsonObject {
                            property bool card
                        }
                        property JsonObject center: JsonObject {
                            property bool card
                        }
                        property JsonObject right: JsonObject {
                            property bool card
                        }
                    }
                    property JsonObject expanded: JsonObject {
                        property bool anchorCenter
                        property int gap
                        property int between
                        property JsonObject left: JsonObject {
                            property bool card
                        }
                        property JsonObject center: JsonObject {
                            property bool card
                        }
                        property JsonObject right: JsonObject {
                            property bool card
                        }
                    }
                }
                property bool expandOnHover
                property int hoverDelay
                property int collapseDelay
                property bool autohide
                property int autohide_nv
                property int autohide_px
                property int autohide_delay
                property int autohide_show_delay
                property int autohide_width
                property bool reserveSpace
                property var widgets: []
                property JsonObject flash: JsonObject {
                    property bool media
                    property int duration
                }
                // how a new notification shows, per island mode: "transient" (the island becomes the
                // card) or "widget" (only the bell iwidget reacts)
                property JsonObject notifications: JsonObject {
                    property string compact
                    property string expanded
                    // the notification card's width range (px); the max never goes past 90 % of the screen
                    property int minWidth
                    property int maxWidth
                    // the card's look (shapes / tones / tone, island/transient/NotificationCard.qml) and its
                    // tone's role
                    property string style
                    property string color
                    // "replace" (the island becomes the card) or "grow" (the island grows down and shows it
                    // under its content, as wide as the island); "hover" or "always" (the expanded card)
                    property string presentation
                    property string expand
                    // how the card expands: "slide" (the text moves) or "fade" (it fades through)
                    property string animation
                    // how long a popup stays (s), and whether an app's own timeout wins (2026-10-27, user)
                    property int duration
                    property bool useAppTimeout
                }
                // clock / date iwidgets, each styled on its own (iwidgets/clock/TextPill.qml): "" font /
                // 0 size = the widget's default; color a role (default / primary / secondary / tertiary /
                // variant); roundness the font's ROND axis; background none / container / tonal / primary
                // with its rounding (-1 = a pill)
                property JsonObject clock: JsonObject {
                    property string font
                    property int weight
                    property int size
                    property real letterSpacing
                    property int roundness
                    property string color
                    property string background
                    property int rounding
                    property string timeFormat
                }
                // the workspaces Iwidget: how many it shows per island mode (0 = dynamic: at least 5, up
                // to the highest used one)
                property JsonObject workspaces: JsonObject {
                    property int compactCount
                    property int expandedCount
                    // Two tones / Tone: the label (dot / number / roman / japanese), how the focused one is
                    // marked (pill / shape) and, per island mode, the windows after it (icons / apps / off), at
                    // most `max` (0 = all)
                    property string label
                    property string focus
                    property JsonObject windows: JsonObject {
                        property string compact
                        property string expanded
                        property int max
                    }
                }
                // the tray Iwidget: the tint style's colour role (primary / surface / variant /
                // secondary / tertiary)
                property JsonObject tray: JsonObject {
                    property string tintColor
                    // per island mode: the icons folded behind a chevron (the old "compact" style), off /
                    // left (<) / right (>): where they open
                    property JsonObject compact: JsonObject {
                        property string fold
                    }
                    property JsonObject expanded: JsonObject {
                        property string fold
                    }
                }
                // the volume Iwidget: the slider waves while music plays; per island mode the icon and
                // the percent around it
                property JsonObject volume: JsonObject {
                    property bool wavy
                    property JsonObject compact: JsonObject {
                        property bool icon
                        property bool percent
                    }
                    property JsonObject expanded: JsonObject {
                        property bool icon
                        property bool percent
                    }
                }
                // the media Iwidget, per island mode: what it shows (iwidgets/media/InfoRow.qml), the
                // controls after it, and its width (0 = auto); when it goes away: "never" (an icon without
                // a player), "noMedia" (without a player) or "paused" (also while paused)
                property JsonObject media: JsonObject {
                    property string visibility
                    property JsonObject compact: JsonObject {
                        property bool showArt
                        property bool showTitle
                        property bool showArtist
                        property bool showWave
                        property bool controls
                        property int width
                        property int titleWeight
                        property int artistWeight
                    }
                    property JsonObject expanded: JsonObject {
                        property bool showArt
                        property bool showTitle
                        property bool showArtist
                        property bool showWave
                        property bool controls
                        property int width
                        property int titleWeight
                        property int artistWeight
                    }
                }
                // the visualizer Iwidget: its colour role, and per island mode the bars and the width
                // (0 = auto)
                property JsonObject visualizer: JsonObject {
                    property string color
                    // "music" (cava) or "random" (a made-up rhythm while something plays)
                    property string source
                    // seconds without music before it collapses
                    property int hideDelay
                    // never collapses: flat (its min height) while nothing plays
                    property bool alwaysShow
                    // Dots: the level (%) a dot turns on at
                    property int dotThreshold
                    // Shapes: the level (%) it starts moving at (2026-10-27, user)
                    property int shapeThreshold
                    property JsonObject compact: JsonObject {
                        property int bars
                        property int width
                        property int maxHeight
                        property int minHeight
                    }
                    property JsonObject expanded: JsonObject {
                        property int bars
                        property int width
                        property int maxHeight
                        property int minHeight
                    }
                }
                // the active window Iwidget, per island mode: the icon shown or not, the text (first / second
                // / both / none: the title's parts around its dash), its max width (px) and weight (0 = 600)
                property JsonObject window: JsonObject {
                    // with no window focused: "text" (`text` and the `image` as its mark, ~/.face by default;
                    // "" or a missing file = the desktop symbol) or "media" (the current track with the note, the text without a player)
                    property JsonObject idle: JsonObject {
                        property string show
                        property string text
                        property string image
                    }
                    property JsonObject compact: JsonObject {
                        property bool showIcon
                        property string text
                        property int maxWidth
                        property int weight
                    }
                    property JsonObject expanded: JsonObject {
                        property bool showIcon
                        property string text
                        property int maxWidth
                        property int weight
                    }
                }
                // the dock Iwidget: the pinned apps (desktop entry ids, in order) and per island mode what it
                // shows ("dock": pinned + open / "open") and whose windows ("workspace": this monitor's / "all")
                property JsonObject dock: JsonObject {
                    property var pinned: []
                    property JsonObject compact: JsonObject {
                        property string content
                        property string scope
                    }
                    property JsonObject expanded: JsonObject {
                        property string content
                        property string scope
                    }
                }
                // the battery Iwidget: the tone's role and what each island mode shows (both / icon / text)
                property JsonObject battery: JsonObject {
                    property string color
                    // hidden above this level (%), 0 = never
                    property int hideAbove
                    property JsonObject compact: JsonObject {
                        property string show
                    }
                    property JsonObject expanded: JsonObject {
                        property string show
                    }
                }
                // the Quick configs Iwidget: the Qwidgets shown, in order (dwidgets/quick/qwidgets.js),
                // the gap between them (px) and the icons' weight (0 = the style's)
                property JsonObject quick: JsonObject {
                    property var items: []
                    property int gap
                    property int weight
                    // Two tones' colour role (primary / surface / variant / secondary / tertiary)
                    property string color
                }
                property JsonObject date: JsonObject {
                    property string font
                    property int weight
                    property int size
                    property real letterSpacing
                    property int roundness
                    property string color
                    property string background
                    property int rounding
                    property string format
                }
            }

            // volume / mic / brightness OSD, shown by the island (island/transient/OsdView.qml)
            property JsonObject osd: JsonObject {
                property bool enabled
                property int duration
                property real pxPerPercent
                // 100 % = the island's own width (compact or expanded, as it was) instead of pxPerPercent
                property bool fitIsland
                // no volume OSD while the volume Iwidget is in the island (it shows the level)
                property bool skipWithVolumeWidget
                // the volume OSD is the volume Iwidget shown for a moment (it must be in the layout,
                // hidden or not) instead of the slider
                property bool volumeWidget
            }
        }
    }

    ConfigFile {
        id: dashboardFile
        factoryPath: root.factoryDir + "/config/dashboard.json"
        adapter: JsonAdapter {
            id: dashboardAdapter

            property int version

            // dashboard grid (see dwidgets/README.md): cell size and gap in px, how an expanding
            // Dwidget makes room, the cards' colour (Kit.card), and the entries [{ uid, id, style, size, x, y, expandOn, options }]
            property JsonObject dashboard: JsonObject {
                property int cell
                property int gap
                property string expandMode
                property var widgets: []
            }
        }
    }

    ConfigFile {
        id: appearanceFile
        factoryPath: root.factoryDir + "/config/appearance.json"
        adapter: JsonAdapter {
            id: appearanceAdapter

            property int version

            property JsonObject theme: JsonObject {
                property string font
                property string monoFont
                // multipliers of the kit's sizes (caelestia's appearance.*.scale); 1 = factory,
                // anim 0 = no animations
                property JsonObject scale: JsonObject {
                    property real rounding
                    property real spacing
                    property real padding
                    property real font
                    property real anim
                }
                // translucent surfaces with blur behind (Colors.layer): `base` is the page's alpha,
                // `layers` the containers'
                property JsonObject transparency: JsonObject {
                    property bool enabled
                    property real base
                    property real layers
                }
                property JsonObject anim: JsonObject {
                    property bool pageScale
                    // the island body overshoots its size and hops (2026-10-28)
                    property bool bounce
                }
                property string scheme
                // the cards' colour, island and dashboard (Kit.card): neutral / container / tinted / primary
                property string card
                // the apps' look (launcher, session, tools, wallpaper): shapes / tones / tone, the
                // Iwidgets' families (K.Kit.appStyle)
                property string appStyle
                property bool light
                // the color mappings per mode, { token: spec } (theme/colorRoles.js); {} = pure M3.
                // Reassign the object to save it
                property var colors
            }

            // caelestia's screen frame: a border of `thickness` px around the screen with the island
            // attached to it (`enabled`), and the screen's rounded corners, `rounding` px
            // (`roundCorners`: the frame's inner corners, or the bare screen's) — independent
            property JsonObject frame: JsonObject {
                property bool enabled
                property int thickness
                property bool roundCorners
                property int rounding
            }

            // the wallpaper shown (the folder and transition are in system.json)
            property JsonObject wallpaper: JsonObject {
                property string current
            }
        }
    }

    ConfigFile {
        id: systemFile
        factoryPath: root.factoryDir + "/config/system.json"
        adapter: JsonAdapter {
            id: systemAdapter

            property int version

            property JsonObject wallpapers: JsonObject {
                property string dir
                property string transition
            }

            property JsonObject tools: JsonObject {
                property string screenshotsDir
                property string recordingsDir
                property string ocrLang
                property int recordFps
            }

            // maxVolume: output volume limit in % (100–200), enforced by services/Audio.qml
            property JsonObject audio: JsonObject {
                property int maxVolume
            }

            property JsonObject media: JsonObject {
                property bool enableFirefoxPlayer
            }

            property JsonObject nightLight: JsonObject {
                property int temp
            }

            // the key hints under the tools / session apps
            property JsonObject hints: JsonObject {
                property bool tools
                property bool session
            }

            // notifications the shell sends itself: battery warnings (services/BatteryWarnings.qml)
            property JsonObject alerts: JsonObject {
                property bool battery
            }

            // the island apps' options (Settings → Apps, 2026-10-17)
            property JsonObject apps: JsonObject {
                // the history (services/Notifications.qml): how many it keeps, saved across restarts,
                // dropped after N days (0 = never), grouped by app in the app
                property JsonObject notifications: JsonObject {
                    property int historySize
                    property bool persist
                    property int maxAgeDays
                    property bool groupByApp
                }
                // cliphist (services/Clipboard.qml): its max entries, images stored, preview lines per row
                property JsonObject clipboard: JsonObject {
                    property int maxItems
                    property bool images
                    property int previewLines
                }
                // the notes' format (markdown: a Preview toggle; plain: never rendered), editor font
                // (ui / mono) and size, their folder, opening on the preview
                property JsonObject notes: JsonObject {
                    property string format
                    property string font
                    property int fontSize
                    property string dir
                    property bool openPreview
                }
                // the game's start speed
                property JsonObject dino: JsonObject {
                    property string speed
                }
            }
        }
    }

    ConfigFile {
        id: stateFile
        factoryPath: root.factoryDir + "/state.json"
        adapter: JsonAdapter {
            id: stateAdapter

            property int version

            property JsonObject controls: JsonObject {
                property bool nightLight
                property bool caffeine
                property bool gameMode
                property bool dnd
            }

            // the pinned player's identity ("Spotify"…); "" = follow the last one that played
            property JsonObject player: JsonObject {
                property string pinned
            }

            // the preset applied last (services/Presets.qml; "" = none)
            property JsonObject presets: JsonObject {
                property string active
            }

            property var apps: ({})
        }
    }
}
