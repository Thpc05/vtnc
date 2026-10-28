import QtQuick
import qs.core
import qs.services
import qs.theme
import "../controls"

// The system: audio, brightness, media and night light (2026-10-27: the wallpaper, the screen tools and
// the hints moved to Apps → Wallpaper, Tools and Session).
Page {
    Columns {
        Column {
            spacing: Tokens.spacing.l

            Section {
                title: "Audio"

                SettingRow {
                    label: "Volume limit"
                    description: "Maximum output volume; changes past it (e.g. from keys) are pulled back. Past 100% the OSD slider grows with it"
                    Stepper {
                        value: Store.audio.maxVolume
                        from: 100
                        to: 200
                        step: 5
                        suffix: "%"
                        onEdited: v => Store.audio.maxVolume = v
                    }
                }
            }
        }

        Column {
            spacing: Tokens.spacing.l

            Section {
                title: "Brightness"

                SettingRow {
                    label: "Sync brightness"
                    description: "Change the brightness of every monitor together"
                    Switch {
                        checked: Brightness.syncBrightness
                        onToggled: c => Brightness.syncBrightness = c
                    }
                }
            }

            Section {
                title: "Media"

                SettingRow {
                    label: "Firefox as a player"
                    description: "Track media playing in Firefox"
                    Switch {
                        checked: Store.media.enableFirefoxPlayer
                        onToggled: c => Store.media.enableFirefoxPlayer = c
                    }
                }
            }

            Section {
                title: "Night light"

                SettingRow {
                    label: "Temperature"
                    Stepper {
                        value: Store.nightLight.temp
                        from: 2500
                        to: 6000
                        step: 100
                        suffix: " K"
                        onEdited: v => Store.nightLight.temp = v
                    }
                }
            }

        }
    }
}
