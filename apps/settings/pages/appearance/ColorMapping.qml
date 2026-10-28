import QtQuick
import qs.core
import qs.components
import qs.theme
import qs.services
import "../../controls"
import "../../../../theme/colorRoles.js" as Roles

// Appearance → Colors: where each shell color comes from, per mode. By default a token is its
// Material 3 role from matugen in the current mode (background: pure black / white); here it can
// be any role of the dark or the light scheme, a palette tone, or a fixed hex
// (Store.theme.colors[mode][token], resolved by theme/colorRoles.js in Colors).
Page {
    id: page

    // the mapping being edited: the shell's own mode (picking one here switches the shell)
    readonly property string editMode: Store.theme.light ? "light" : "dark"
    // the token whose picker is open
    property string openToken: ""

    // two columns: the scheme, mode and accents at the left; the other groups at the right
    Columns {
    Column {
        spacing: Tokens.spacing.l

        Section {
            title: "Colors"

            SettingRow {
                label: "Scheme"
                description: "How matugen builds the palette from the wallpaper"
                Segmented {
                    options: Wallpapers.schemes.map(s => ({
                                value: s,
                                label: s.replace("scheme-", "").split("-").map(w => w[0].toUpperCase() + w.slice(1)).join(" ")
                            }))
                    value: Store.theme.scheme
                    onSelected: v => Store.theme.scheme = v
                }
            }
            SettingRow {
                label: "Mode"
                description: "The shell's mode, and the mapping edited: each mode has its own. Roles and tones follow the wallpaper; a hex doesn't"
                Segmented {
                    options: [
                        {
                            value: "dark",
                            label: "Dark"
                        },
                        {
                            value: "light",
                            label: "Light"
                        }
                    ]
                    value: page.editMode
                    onSelected: v => Store.theme.light = v === "light"
                }
            }
        }

        // the tokens, by group: the accents here, the rest in the right column
        TokenGroup {
            group: "Accent"
        }
    }
    Column {
        spacing: Tokens.spacing.l

        Repeater {
            model: Roles.GROUPS.filter(g => g !== "Accent")

            TokenGroup {
                required property string modelData
                group: modelData
            }
        }
    }
    }

    // a group's tokens in a Section
    component TokenGroup: Section {
        id: tokenGroup
        property string group
        title: group

        Repeater {
            model: Roles.TOKENS.filter(t => t.group === tokenGroup.group)

            ColorTokenRow {
                required property var modelData
                token: modelData.token
                title: modelData.title
                open: page.openToken === token
                onToggled: page.openToken = open ? "" : token
            }
        }
    }
}
