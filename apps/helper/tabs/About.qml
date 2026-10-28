import QtQuick
import Quickshell
import qs.core
import ".."
import "../info.js" as Info

// Helper → About (2026-10-17): what vtnc is (the hero), a tour of its parts as cards (a click opens
// one; user), where to start and where things are. A base: the docs and the repository join once they
// exist.
HelperList {
    searchable: false
    keyWidth: 250
    wrap: true
    note: "Enter or a click copies a path"
    heroIcon: "info"
    heroShape: "cookie9"
    heroTitle: Info.NAME + "  ·  " + Info.VERSION
    heroText: Info.TAGLINE + "<br>The island at the top grows into everything else: hover it for more, click its widgets, or use the shortcuts below."
    sections: [
        {
            title: "Start here",
            rows: [
                {
                    keys: ["Super"],
                    text: "Search and open apps"
                },
                {
                    keys: ["Super", "D"],
                    text: "The dashboard: quick settings, media, calendar…"
                },
                {
                    keys: ["Super", "I"],
                    text: "Settings: the look, the island, the dashboard"
                },
                {
                    keys: ["Super", "/"],
                    text: "This Helper"
                }
            ]
        },
        {
            title: "Where things are",
            rows: [
                {
                    key: "~/.config/vtnc/",
                    text: "Your settings and presets",
                    copy: Store.configDir
                },
                {
                    key: "~/.local/state/vtnc/",
                    text: "What the shell remembers",
                    copy: Store.stateDir
                },
                {
                    key: "~/.config/hypr/vtnc/",
                    text: "vtnc's Hyprland files (yours: custom/)",
                    copy: Quickshell.env("HOME") + "/.config/hypr/vtnc"
                },
                {
                    key: "~/.config/quickshell/vtnc/",
                    text: "The shell itself",
                    copy: Quickshell.shellDir
                }
            ]
        }
    ]

    function opened() {
        reset();
    }

    // the tour: three per row
    readonly property var tour: [
        {
            icon: "web_asset",
            shape: "cookie6",
            title: "Island",
            text: "The bar at the top: hover to expand it, click its widgets. Its layout is in Settings.",
            open: () => Runtime.openApp("settings", {
                    page: "island/general"
                })
        },
        {
            icon: "dashboard",
            shape: "cookie9",
            title: "Dashboard",
            text: "Super+D: quick settings, media, calendar and more, on a grid you arrange.",
            open: () => Runtime.openApp("dashboard", {})
        },
        {
            icon: "apps",
            shape: "sunny",
            title: "Apps",
            text: "Super opens the launcher: type to find an app, Enter to open it.",
            open: () => Runtime.openApp("launcher", {})
        },
        {
            icon: "settings",
            shape: "cookie12",
            title: "Settings",
            text: "Super+I: the look, the island, the dashboard and the apps.",
            open: () => Runtime.openApp("settings", {})
        },
        {
            icon: "style",
            shape: "softBurst",
            title: "Presets",
            text: "Save your whole style (island, dashboard, colors, wallpaper) and switch between them.",
            open: () => Runtime.openApp("settings", {
                    page: "presets"
                })
        },
        {
            icon: "wallpaper",
            shape: "cookie7",
            title: "Wallpaper",
            text: "Super+, picks a wallpaper; the colors follow it.",
            open: () => Runtime.openApp("wallpaper", {})
        }
    ]
    readonly property int tourHeight: 92
    extraHeight: 2 * tourHeight + 16

    Grid {
        width: parent.width
        columns: 3
        spacing: 16

        Repeater {
            model: tour

            TourCard {
                required property var modelData
                width: (parent.width - 32) / 3
                height: tourHeight
                icon: modelData.icon
                shape: modelData.shape
                title: modelData.title
                text: modelData.text
                open: modelData.open
            }
        }
    }
}
