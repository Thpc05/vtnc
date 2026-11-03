//@ pragma UseQApplication
//@ pragma ShellId vtnc

import QtQuick
import Quickshell
import qs.base.core
import qs.apps
import qs.island
import qs.shell

ShellRoot {
    id: root

    Ipc {
        settingsPages: AppRegistry.get("settings")?.pages ?? []
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
