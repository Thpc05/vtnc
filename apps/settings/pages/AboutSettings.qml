import QtQuick
import Quickshell
import qs.core
import qs.components
import qs.theme
import "../controls"

Page {
    id: page

    Columns {
        Section {
            title: "vtnc"

            SettingRow {
                label: "Settings"
                description: Store.configDir
                IconButton {
                    icon: Icons.folder
                    onClicked: Quickshell.execDetached(["xdg-open", Store.configDir])
                }
            }
            SettingRow {
                label: "State"
                description: Store.stateDir
                IconButton {
                    icon: Icons.folder
                    onClicked: Quickshell.execDetached(["xdg-open", Store.stateDir])
                }
            }
            SettingRow {
                label: "Reload shell"
                IconButton {
                    icon: Icons.arrowCounterClockwise
                    onClicked: Quickshell.reload(false)
                }
            }
        }
    }
}
