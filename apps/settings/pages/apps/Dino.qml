import QtQuick
import qs.core
import "../../controls"

// Apps → Dino run: the game's speed and its high score (state.json, apps.dino.highscore).
Page {
    id: root

    readonly property var cfg: Store.appOptions.dino
    readonly property int highscore: Store.appGet("dino", "highscore", 0)
    property bool confirming: false

    Section {
        title: "Game"

        SettingRow {
            label: "Start speed"
            Segmented {
                options: [
                    {
                        value: "normal",
                        label: "Normal"
                    },
                    {
                        value: "fast",
                        label: "Fast"
                    }
                ]
                value: root.cfg.speed
                onSelected: v => root.cfg.speed = v
            }
        }
        SettingRow {
            label: "High score"
            description: root.highscore > 0 ? String(root.highscore).padStart(5, "0") : "None yet"
            Row {
                spacing: 6
                SmallButton {
                    visible: !root.confirming
                    enabled: root.highscore > 0
                    text: "Reset"
                    onClicked: root.confirming = true
                }
                SmallButton {
                    visible: root.confirming
                    text: "Cancel"
                    onClicked: root.confirming = false
                }
                SmallButton {
                    visible: root.confirming
                    danger: true
                    text: "Reset high score"
                    onClicked: {
                        Store.appSet("dino", "highscore", 0);
                        root.confirming = false;
                    }
                }
            }
        }
    }
}
