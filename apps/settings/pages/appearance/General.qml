import QtQuick
import qs.core
import qs.services
import qs.theme
import "../../controls"

// Appearance → General: light mode, scheme, shape, text and motion (the colors: Colors.qml).
Page {
    // the kit's sizes × the user's multiplier (caelestia's appearance.*.scale); 100 % = factory
    component ScaleRow: SettingRow {
        id: row
        property string key
        property real from: 50
        property real to: 200
        property string offText: ""
        Stepper {
            value: Math.round((Store.theme.scale?.[row.key] ?? 1) * 100)
            from: row.from
            to: row.to
            step: 5
            suffix: " %"
            specialValueText: row.offText
            firstValue: 25
            onEdited: v => Store.theme.scale[row.key] = v / 100
        }
    }

    Columns {
        Column {
            spacing: Tokens.spacing.l

            // the light mode and the scheme are in Appearance → Colors (2026-10-27: they were here too)
            Section {
                title: "Look"

                SettingRow {
                    label: "Cards"
                    description: "The fill of every card style, on the island and the dashboard: neutral (surface), container (primary container), tinted (surface with a primary tint) or primary"
                    Segmented {
                        options: [
                            {
                                value: "neutral",
                                label: "Neutral"
                            },
                            {
                                value: "container",
                                label: "Container"
                            },
                            {
                                value: "tinted",
                                label: "Tinted"
                            },
                            {
                                value: "primary",
                                label: "Primary"
                            }
                        ]
                        value: Store.theme.card
                        onSelected: v => Store.theme.card = v
                    }
                }
                SettingRow {
                    label: "Apps"
                    description: "The look of every app (launcher, settings, notifications, clipboard, notes…), as the Iwidgets: shapes (filled marks), two tones (tints of the primary) or tone (the primary alone, no fills)"
                    Segmented {
                        options: [
                            {
                                value: "shapes",
                                label: "Shapes"
                            },
                            {
                                value: "tones",
                                label: "Two tones"
                            },
                            {
                                value: "tone",
                                label: "Tone"
                            }
                        ]
                        value: Store.theme.appStyle
                        onSelected: v => Store.theme.appStyle = v
                    }
                }
            }

            Section {
                title: "Fonts"

                SettingRow {
                    label: "Font"
                    FontPicker {
                        emptyLabel: "Default (" + Tokens.defaultFamily + ")"
                        value: Store.theme.font
                        onEdited: v => Store.theme.font = v
                    }
                }
                SettingRow {
                    label: "Monospace font"
                    FontPicker {
                        value: Store.theme.monoFont
                        onEdited: v => Store.theme.monoFont = v
                    }
                }
            }

            Section {
                title: "Scale"

                ScaleRow {
                    label: "Rounding"
                    description: "Corner radii everywhere"
                    key: "rounding"
                    from: 0
                }
                ScaleRow {
                    label: "Spacing"
                    description: "Gaps between items"
                    key: "spacing"
                }
                ScaleRow {
                    label: "Padding"
                    description: "Space inside cards and controls"
                    key: "padding"
                }
                ScaleRow {
                    label: "Text"
                    description: "Text and icon size"
                    key: "font"
                }
            }

            Section {
                title: "Transparency"

                SettingRow {
                    label: "Transparent surfaces"
                    description: "Blur the desktop behind the frame, the island and its apps"
                    Switch {
                        checked: Store.theme.transparency.enabled
                        onToggled: c => Store.theme.transparency.enabled = c
                    }
                }
                SettingRow {
                    label: "Background opacity"
                    opacity: Store.theme.transparency.enabled ? 1 : 0.5
                    Stepper {
                        value: Math.round(Store.theme.transparency.base * 100)
                        from: 0
                        to: 100
                        step: 5
                        suffix: " %"
                        onEdited: v => Store.theme.transparency.base = v / 100
                    }
                }
                SettingRow {
                    label: "Card opacity"
                    description: "Cards are also lifted to stand out from the background"
                    opacity: Store.theme.transparency.enabled ? 1 : 0.5
                    Stepper {
                        value: Math.round(Store.theme.transparency.layers * 100)
                        from: 0
                        to: 100
                        step: 5
                        suffix: " %"
                        onEdited: v => Store.theme.transparency.layers = v / 100
                    }
                }
            }
        }

        Column {
            spacing: Tokens.spacing.l

            // the motion (2026-10-27: Animations and the Scale's animation length together; the jelly went)
            Section {
                title: "Motion"

                ScaleRow {
                    label: "Animation length"
                    description: "Longer is slower"
                    key: "anim"
                    from: 0
                    to: 300
                    offText: "Off"
                }
                SettingRow {
                    label: "Bounce"
                    description: "The island overshoots its size a little and settles back as it morphs (off: it eases straight into place)"
                    Switch {
                        checked: Store.theme.anim.bounce
                        onToggled: c => Store.theme.anim.bounce = c
                    }
                }
                SettingRow {
                    label: "Page scale"
                    description: "Apps scale with the island while it morphs (off: they keep their size and the island crops them)"
                    Switch {
                        checked: Store.theme.anim.pageScale
                        onToggled: c => Store.theme.anim.pageScale = c
                    }
                }
            }

            Section {
                title: "Frame"

                SettingRow {
                    label: "Screen frame"
                    description: "A border around the screen that the island hangs from; windows keep clear of it"
                    Switch {
                        checked: Store.frame.enabled
                        onToggled: c => Store.frame.enabled = c
                    }
                }
                SettingRow {
                    label: "Thickness"
                    opacity: Store.frame.enabled ? 1 : 0.5
                    Stepper {
                        value: Store.frame.thickness
                        from: 1
                        to: 40
                        step: 1
                        suffix: " px"
                        onEdited: v => Store.frame.thickness = v
                    }
                }
                SettingRow {
                    label: "Rounded corners"
                    description: "Round the screen's corners (the frame's inner corners while it's on)"
                    Switch {
                        checked: Store.frame.roundCorners
                        onToggled: c => Store.frame.roundCorners = c
                    }
                }
                SettingRow {
                    label: "Radius"
                    opacity: Store.frame.roundCorners ? 1 : 0.5
                    Stepper {
                        value: Store.frame.rounding
                        from: 1
                        to: 60
                        step: 1
                        suffix: " px"
                        onEdited: v => Store.frame.rounding = v
                    }
                }
                // the frame and the corners' colour (the `frame` token, also in Appearance → Colors;
                // Auto: the island's background)
                ColorTokenRow {
                    id: frameColor
                    token: "frame"
                    title: "Color"
                    onToggled: open = !open
                }
            }
        }
    }
}
