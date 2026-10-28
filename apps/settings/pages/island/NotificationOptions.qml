import QtQuick
import qs.core
import qs.services
import qs.components
import qs.theme
import "../../controls"

// Notifications iwidget options, shown in the Widgets detail panel when the bell is selected:
// how a new notification shows per island mode (island.notifications) and do not disturb. The popup's
// look (presentation, expand, card, width) is in Appearance → Popups.
Column {
    id: root

    readonly property var modes: Store.island.notifications
    readonly property var options: [
        {
            value: "transient",
            label: "Island"
        },
        {
            value: "widget",
            label: "Widget only"
        }
    ]

    spacing: 0

    StyledText {
        bottomPadding: Tokens.spacing.xs
        text: "Notifications"
        font.pixelSize: Tokens.font.small
        font.weight: Font.Bold
        color: Colors.primary
    }

    SettingRow {
        label: "While compact"
        description: "Island: it becomes the notification for a moment · Widget only: just the bell shakes"
        Segmented {
            options: root.options
            value: root.modes.compact
            onSelected: v => root.modes.compact = v
        }
    }
    SettingRow {
        label: "While expanded"
        description: "The same choice while the island is hovered, pinned or expanded"
        Segmented {
            options: root.options
            value: root.modes.expanded
            onSelected: v => root.modes.expanded = v
        }
    }
    SettingRow {
        label: "Do not disturb"
        description: "No popups at all; notifications still arrive (click the bell to toggle)"
        Switch {
            checked: Notifications.silent
            onToggled: c => Notifications.silent = c
        }
    }
    StyledText {
        width: parent.width
        topPadding: Tokens.spacing.xs
        text: "The popup's look and size: Appearance → Popups"
        font.pixelSize: Tokens.font.small
        color: Colors.overSurfaceVariant
        wrapMode: Text.Wrap
    }
}
