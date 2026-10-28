//@ pragma UseQApplication
//@ pragma ShellId vtnc

import QtQuick
import Quickshell
import qs.core
import qs.frame
import qs.island
import qs.services
import qs.dwidgets.visualizer as DashVisualizer
import "island/transient" as Transient

ShellRoot {
    id: root

    Ipc {}

    // when notification popups take over the island (the notification transient)
    Transient.NotificationPresenter {}
    BatteryWarnings {}

    // Start services that must run even when no widget uses them
    Component.onCompleted: {
        Notifications.list;
        NetworkService.wifiEnabled;
        Wallpapers.current;
        Controls.gameMode;
        // its watchers store every copy in cliphist
        Clipboard.entries;
        // cava for the dashboard's visualizers while music plays, so an open doesn't wait for it
        DashVisualizer.VisualizerKeeper.held;
    }

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
