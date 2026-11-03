//@ pragma UseQApplication
//@ pragma ShellId vtnc

import QtQuick
import Quickshell
import qs.base.core
import qs.apps
import qs.island
import qs.shell
import "settings/tree.js" as SettingsTree

ShellRoot {
    id: root

    Ipc {
        // every Settings page's path (IPC `settings pages`)
        settingsPages: SettingsTree.leaves().map(l => l.path)
    }

    Daemons {}

    // Everything visual waits for the state file to be loaded and validated
    Variants {
        model: Store.ready ? Quickshell.screens : []

        Scope {
            id: screenScope
            required property ShellScreen modelData

            FrameExclusions {
                screen: screenScope.modelData
            }

            IslandWindow {
                apps: AppRegistry
                screen: screenScope.modelData
            }

            LazyLoader {
                active: Store.island.reserveSpace

                ReserveWindow {
                    screen: screenScope.modelData
                }
            }
        }
    }
}
