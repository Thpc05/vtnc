import QtQuick
import Quickshell
import qs.theme
import qs.iwidgets

// Example gallery: the battery Iwidget in every style, bare and on the card.
// tools/probe/render.sh tools/probe/examples/battery.qml
// A gallery is a ShellRoot whose window saves itself to $OUT and quits.
ShellRoot {
    FloatingWindow {
        implicitWidth: 520
        implicitHeight: 220
        Rectangle {
            id: shot
            width: 520
            height: 220
            color: Colors.background
            Column {
                x: 12
                y: 10
                spacing: 6
                Repeater {
                    model: ["shapes", "tones", "tone", "ring", "arc"]
                    Row {
                        id: line
                        required property string modelData
                        spacing: 24
                        Text {
                            width: 60
                            text: line.modelData
                            color: Colors.outline
                            font.pixelSize: 11
                            anchors.verticalCenter: parent.verticalCenter
                        }
                        Repeater {
                            model: ["", "Card"]
                            Item {
                                required property string modelData
                                width: 90
                                height: 34
                                IwidgetFrame {
                                    anchors.verticalCenter: parent.verticalCenter
                                    widgetId: "battery"
                                    style: line.modelData + parent.modelData
                                    mode: "compact"
                                }
                            }
                        }
                    }
                }
            }
        }
    }
    Timer {
        interval: 1500
        running: true
        onTriggered: shot.grabToImage(r => {
            r.saveToFile(Quickshell.env("OUT"));
            Qt.quit();
        })
    }
}
