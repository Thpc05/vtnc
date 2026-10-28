import QtQuick
import qs.core
import qs.theme
import "../../controls"

// Island → Auto hide: when the island slides away and how.
Page {
    Columns {
        Section {
            title: "Behavior"

            SettingRow {
                label: "Auto-hide"
                description: "Slide the island away; hover the top edge to bring it back"
                Switch {
                    checked: Store.island.autohide
                    onToggled: c => Store.island.autohide = c
                }
            }
            SettingRow {
                label: "When"
                description: "Fullscreen: only over fullscreen windows · Windows: also when the workspace has windows · Always"
                opacity: Store.island.autohide ? 1 : 0.5
                Segmented {
                    options: [
                        {
                            value: 1,
                            label: "Fullscreen"
                        },
                        {
                            value: 2,
                            label: "Windows"
                        },
                        {
                            value: 3,
                            label: "Always"
                        }
                    ]
                    value: Store.island.autohide_nv
                    onSelected: v => Store.island.autohide_nv = v
                }
            }
            SettingRow {
                label: "Activation area"
                description: "Height of the strip at the top edge that reveals the island"
                opacity: Store.island.autohide ? 1 : 0.5
                Stepper {
                    value: Store.island.autohide_px
                    from: 1
                    to: 40
                    step: 1
                    suffix: " px"
                    onEdited: v => Store.island.autohide_px = v
                }
            }
            SettingRow {
                label: "Show delay"
                description: "Wait before sliding in when the pointer reaches the top edge"
                opacity: Store.island.autohide ? 1 : 0.5
                Stepper {
                    value: Store.island.autohide_show_delay
                    from: 0
                    to: 5000
                    step: 50
                    suffix: " ms"
                    onEdited: v => Store.island.autohide_show_delay = v
                }
            }
            SettingRow {
                label: "Hide delay"
                description: "Wait before sliding away (after the pointer leaves, a window opens…)"
                opacity: Store.island.autohide ? 1 : 0.5
                Stepper {
                    value: Store.island.autohide_delay
                    from: 0
                    to: 5000
                    step: 100
                    suffix: " ms"
                    onEdited: v => Store.island.autohide_delay = v
                }
            }
        }

        Section {
            title: "Animation"

            SettingRow {
                label: "Width while hiding"
                description: "Width change as the island hides: negative narrows, positive widens (0 = off)"
                opacity: Store.island.autohide ? 1 : 0.5
                Stepper {
                    value: Store.island.autohide_width
                    from: -100
                    to: 100
                    step: 5
                    suffix: " %"
                    onEdited: v => Store.island.autohide_width = v
                }
            }
        }
    }
}
