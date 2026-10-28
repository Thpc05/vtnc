import QtQuick
import qs.core
import "../../controls"

// Apps → Wallpaper (2026-10-27, from System): the folder the wallpaper app lists and awww's transition.
Page {
    Section {
        title: "Wallpaper"

        SettingRow {
            label: "Wallpapers folder"
            TextField {
                value: Store.wallpapers.dir
                mono: true
                onEdited: v => Store.wallpapers.dir = v
            }
        }
        SettingRow {
            label: "Transition"
            description: "awww transition when applying a wallpaper"
            Cycler {
                options: ["grow", "center", "outer", "wipe", "wave", "fade", "simple", "left", "right", "top", "bottom", "any", "random", "none"].map(t => ({
                            value: t,
                            label: t[0].toUpperCase() + t.slice(1)
                        }))
                value: Store.wallpapers.transition
                onSelected: v => Store.wallpapers.transition = v
            }
        }
    }
}
