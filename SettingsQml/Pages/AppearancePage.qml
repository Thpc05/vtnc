import QtQuick
import ".."
import "../../ConfigValues"

SettingsPage {
    title: "Appearance"
    icon: "󰏘"

    SettingGroup {
        title: "Colors"
        // No revert arrows here on purpose — see SettingColor

        SettingColor {
            label: "Accent"
            hint: "Focus, selection, and whatever is active"
            value: Theme.accent
            store: Theme.data; key: "accent"; defaults: Defaults.theme
        }
        SettingColor {
            label: "Card"
            hint: "The step above black. The main background is fixed at "
                + "#000000 and is not configurable — the island is black"
            value: Theme.card
            store: Theme.data; key: "card"; defaults: Defaults.theme
        }
        SettingColor {
            label: "Hairline border"
            hint: "1px around every card. Keep the alpha low — it is edge "
                + "light, not a line. Opaque turns it into a frame"
            value: Theme.border
            store: Theme.data; key: "border"; defaults: Defaults.theme
        }
        SettingColor {
            label: "Recessed surface"
            hint: "Slider tracks and artwork that failed to load"
            value: Theme.surface
            store: Theme.data; key: "surface"; defaults: Defaults.theme
        }
        SettingColor {
            label: "Hover layer"
            hint: "Behind every pointed target. Needs alpha (#2effffff) — "
                + "it stacks on top of whatever is underneath"
            value: Theme.hoverLayer
            store: Theme.data; key: "hoverLayer"; defaults: Defaults.theme
        }
        SettingColor {
            label: "Separator"
            value: Theme.separator
            store: Theme.data; key: "separator"; defaults: Defaults.theme
        }
        SettingColor {
            label: "Shadow"
            value: Theme.shadow
            store: Theme.data; key: "shadow"; defaults: Defaults.theme
        }
        SettingColor {
            label: "Danger"
            hint: "Delete, power off, critical battery"
            value: Theme.danger
            store: Theme.data; key: "danger"; defaults: Defaults.theme
        }
    }

    SettingGroup {
        title: "Text"

        SettingColor {
            label: "Primary"
            value: Theme.textPrimary
            store: Theme.data; key: "textPrimary"; defaults: Defaults.theme
        }
        SettingColor {
            label: "Secondary"
            value: Theme.textSecondary
            store: Theme.data; key: "textSecondary"; defaults: Defaults.theme
        }
        SettingColor {
            label: "Muted"
            value: Theme.textMuted
            store: Theme.data; key: "textMuted"; defaults: Defaults.theme
        }
        SettingText {
            label: "Display font"
            text: Theme.fontDisplay
            store: Theme.data; key: "fontDisplay"; defaults: Defaults.theme
        }
        SettingText {
            label: "Monospace font"
            hint: "Clock and numbers"
            text: Theme.fontMono
            store: Theme.data; key: "fontMono"; defaults: Defaults.theme
        }
        SettingText {
            label: "Icon font"
            text: Theme.fontIcon
            store: Theme.data; key: "fontIcon"; defaults: Defaults.theme
        }
    }

    SettingGroup {
        title: "Corner radius"

        SettingSlider {
            label: "Island"
            hint: "Practical ceiling is half the bar height. Above that "
                + "the corner starts varying with height again"
            value: Theme.radiusIsland
            from: 0; to: 40; suffix: "px"
            store: Theme.data; key: "radiusIsland"; defaults: Defaults.theme
        }
        SettingSlider {
            label: "Card"
            hint: "Root of the concentric chain — the chip derives from it"
            value: Theme.radiusCard
            from: 0; to: 40; suffix: "px"
            store: Theme.data; key: "radiusCard"; defaults: Defaults.theme
        }
        SettingSlider {
            label: "Screen corners"
            value: Theme.radiusScreen
            from: 0; to: 60; suffix: "px"
            store: Theme.data; key: "radiusScreen"; defaults: Defaults.theme
        }

        SettingRow {
            label: "List row"
            hint: "DERIVED: island − content padding. Not editable — it is "
                + "what keeps a row concentric with the island it sits in"
            controlWidth: 60

            Text {
                anchors.right: parent.right
                anchors.verticalCenter: parent.verticalCenter
                text: Math.round(Theme.radiusRow) + " px"
                color: Theme.textMuted
                font { family: Theme.fontMono; pixelSize: 12 }
            }
        }

        SettingRow {
            label: "Chip"
            hint: "DERIVED: card − card padding. Not editable — it is what "
                + "keeps the corners concentric"
            controlWidth: 60

            Text {
                anchors.right: parent.right
                anchors.verticalCenter: parent.verticalCenter
                text: Math.round(Theme.radiusChip) + " px"
                color: Theme.textMuted
                font { family: Theme.fontMono; pixelSize: 12 }
            }
        }
    }

    SettingGroup {
        title: "Spacing"

        SettingSlider {
            label: "Content padding"
            hint: "Also sets the list row radius"
            value: Theme.contentPadding
            from: 0; to: 30; suffix: "px"
            store: Theme.data; key: "contentPadding"; defaults: Defaults.theme
        }
        SettingSlider {
            label: "Card padding"
            hint: "Also sets the chip radius"
            value: Theme.cardPadding
            from: 0; to: 30; suffix: "px"
            store: Theme.data; key: "cardPadding"; defaults: Defaults.theme
        }
    }
}
