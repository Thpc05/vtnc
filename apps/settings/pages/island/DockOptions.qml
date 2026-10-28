import QtQuick
import Quickshell
import qs.core
import qs.components
import qs.theme
import "../../controls"

// The dock Iwidget's options (island.dock), shown in the Layout detail panel: the pinned apps (pinned and
// unpinned with a right click on the dock) and, in a card per island mode, what it shows and whose windows.
Column {
    id: root

    readonly property var options: Store.island.dock

    spacing: Tokens.spacing.s

    StyledText {
        text: "Dock"
        font.pixelSize: Tokens.font.small
        font.weight: Font.Bold
        color: Colors.primary
    }

    SettingRow {
        label: "Pinned"
        description: {
            const names = root.options.pinned.map(id => DesktopEntries.byId(id)?.name ?? id);
            return (names.length > 0 ? names.join(" · ") : "None yet") + " (right click an app on the dock to pin or unpin it)";
        }
        SmallButton {
            text: "Clear"
            danger: true
            enabled: root.options.pinned.length > 0
            onClicked: root.options.pinned = []
        }
    }

    Row {
        id: columns
        width: root.width
        spacing: Tokens.spacing.s

        Repeater {
            model: [
                {
                    mode: "compact",
                    title: "Compact"
                },
                {
                    mode: "expanded",
                    title: "Expanded"
                }
            ]

            OptionsCard {
                id: card
                required property var modelData
                readonly property var options: root.options[modelData.mode]
                width: (columns.width - columns.spacing) / 2
                title: modelData.title

                SettingRow {
                    label: "Shows"
                    description: "Dock: the pinned apps, then the other open ones · Open: only the open apps (nothing with none)"
                    Segmented {
                        options: [
                            {
                                value: "dock",
                                label: "Dock"
                            },
                            {
                                value: "open",
                                label: "Open"
                            }
                        ]
                        value: card.options.content
                        onSelected: v => card.options.content = v
                    }
                }
                SettingRow {
                    label: "Windows"
                    description: "Whose windows count: this monitor's workspace, or every workspace"
                    Segmented {
                        options: [
                            {
                                value: "workspace",
                                label: "Workspace"
                            },
                            {
                                value: "all",
                                label: "All"
                            }
                        ]
                        value: card.options.scope
                        onSelected: v => card.options.scope = v
                    }
                }
            }
        }
    }
}
