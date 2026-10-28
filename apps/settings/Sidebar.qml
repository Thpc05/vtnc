import QtQuick
import QtQuick.Shapes
import qs.core
import qs.components
import qs.theme
import qs.dwidgets.quick.panels
import qs.kit as K
import "../common"

// Settings sidebar: icon + label rows; the selected page with sub-pages opens its branches
// right below it, joined by tree lines. In the apps' look (R1.5, 2026-10-17; was caelestia's nav on a
// card): bare on the page, one width (the page doesn't move), the selected row in the lists' highlight
// (apps/common/RowHighlight: Shapes the container, Two tones a tint, Tone a bar) and the current
// page's icon on its mark (Shapes the random M3 shape, Two tones a tone square, Tone the bare icon).
Item {
    id: root

    // [{ id, title, icon, children?: [{ id, title }] }]
    required property var tree
    // "parent/child" or "leaf"
    required property string path
    signal picked(string path)

    readonly property string topId: path.split("/")[0]
    readonly property string childId: path.split("/")[1] ?? ""
    readonly property int topIndex: tree.findIndex(n => n.id === topId)
    readonly property var topNode: tree[topIndex] ?? null
    readonly property int childIndex: topNode?.children ? topNode.children.findIndex(c => c.id === childId) : -1
    readonly property bool treeOpen: (topNode?.children?.length ?? 0) > 0

    readonly property int rowHeight: 38
    readonly property int childHeight: 32
    // x of the tree trunk: under the centre of the parent's icon
    readonly property int trunkX: Tokens.spacing.m + 8

    readonly property PanelColors c: PanelColors {
        look: K.Kit.appLook
    }
    // the current page's mark: a new shape on every move, none morphing when the app opens
    readonly property FocusShape focusShape: FocusShape {}
    onTopIndexChanged: focusShape.next()
    function reshuffle() {
        focusShape.reshuffle();
    }

    width: 176

    Column {
        id: nav
        width: parent.width
        spacing: 2

        Row {
            height: 44
            leftPadding: Tokens.spacing.m
            spacing: Tokens.spacing.s

            Icon {
                anchors.verticalCenter: parent.verticalCenter
                icon: Icons.gear
                size: 16
                color: root.c.accent
            }
            StyledText {
                anchors.verticalCenter: parent.verticalCenter
                text: "Settings"
                font.pixelSize: Tokens.font.large
                font.weight: Font.Bold
                color: root.c.strong
            }
        }

        Item {
            width: parent.width
            height: tops.height

            // selection highlight: follows the selected row (a sub-page when there is one),
            // also while the branches above it open or close
            readonly property Item selTop: {
                topRepeater.count; // itemAt() isn't reactive
                return topRepeater.itemAt(root.topIndex);
            }
            RowHighlight {
                id: highlight
                readonly property bool onChild: root.childIndex >= 0
                c: root.c
                rowHeight: height
                // on a sub-page it starts after the tree lines
                x: onChild ? root.trunkX + 16 : 0
                width: parent.width - x
                Behavior on x {
                    K.Anim {
                        type: K.Anim.FastSpatial
                    }
                }
                y: parent.selTop ? parent.selTop.y + (onChild ? root.rowHeight + root.childIndex * root.childHeight : 0) : 0
                height: onChild ? root.childHeight : root.rowHeight
                Behavior on y {
                    K.Anim {
                        type: K.Anim.DefaultSpatial
                    }
                }
                Behavior on height {
                    K.Anim {
                        type: K.Anim.FastSpatial
                    }
                }
            }

            Column {
                id: tops
                width: parent.width

                Repeater {
                    id: topRepeater
                    model: root.tree

                    Item {
                        id: top
                        required property var modelData
                        required property int index
                        readonly property bool isCurrent: index === root.topIndex
                        readonly property var children_: modelData.children ?? []
                        readonly property bool open: isCurrent && children_.length > 0

                        width: tops.width
                        height: root.rowHeight + branch.height + 2
                        clip: true

                        // parent row
                        Item {
                            id: row
                            width: parent.width
                            height: root.rowHeight

                            readonly property color fg: root.c.strong

                            Row {
                                anchors.verticalCenter: parent.verticalCenter
                                leftPadding: Tokens.spacing.m
                                spacing: Tokens.spacing.m

                                // the current page's mark: Shapes the random M3 shape, Two tones a tone square, Tone
                                // the bare icon in the tone
                                Item {
                                    anchors.verticalCenter: parent.verticalCenter
                                    width: 28
                                    height: 28

                                    K.M3Shape {
                                        anchors.fill: parent
                                        visible: top.isCurrent && root.c.shapes
                                        shape: root.focusShape.shape || "cookie7"
                                        animate: !root.focusShape.instant
                                        samples: 60
                                        color: root.c.accent
                                    }
                                    Rectangle {
                                        anchors.fill: parent
                                        visible: top.isCurrent && root.c.kind === "tones"
                                        radius: 9
                                        color: root.c.accent
                                    }
                                    Icon {
                                        anchors.centerIn: parent
                                        icon: top.modelData.icon
                                        size: 16
                                        // filled on the current page (M3's selected icon)
                                        fill: top.isCurrent ? 1 : 0
                                        color: top.isCurrent ? (root.c.kind === "tone" ? root.c.accent : root.c.overAccent) : row.fg
                                        Behavior on color {
                                            K.CAnim {}
                                        }
                                    }
                                }
                                StyledText {
                                    anchors.verticalCenter: parent.verticalCenter
                                    text: top.modelData.title
                                    font.weight: top.isCurrent ? Font.Bold : Font.DemiBold
                                    color: top.isCurrent && root.c.kind === "tone" ? root.c.accent : row.fg
                                }
                            }

                            K.StateLayer {
                                id: rowMouse
                                radius: height / 2
                                color: row.fg
                                onClicked: root.picked(top.children_.length > 0 ? top.modelData.id + "/" + top.children_[0].id : top.modelData.id)
                            }
                        }

                        // branches
                        Item {
                            id: branch
                            y: root.rowHeight
                            width: parent.width
                            height: top.open ? top.children_.length * root.childHeight : 0
                            opacity: top.open ? 1 : 0
                            Behavior on height {
                                K.Anim {}
                            }
                            Behavior on opacity {
                                K.Anim {
                                    type: K.Anim.FastEffects
                                }
                            }

                            // the model carries everything a branch row needs (it can't reach `top`)
                            Repeater {
                                model: top.children_.map((c, i) => ({
                                            id: c.id,
                                            title: c.title,
                                            parentId: top.modelData.id,
                                            last: i === top.children_.length - 1
                                        }))

                                Item {
                                    id: child
                                    required property var modelData
                                    required property int index
                                    readonly property bool isCurrent: root.topId === modelData.parentId && root.childId === modelData.id
                                    readonly property bool last: modelData.last

                                    y: index * root.childHeight
                                    width: branch.width
                                    height: root.childHeight

                                    // tree line: trunk down from the parent, rounded elbow into the row;
                                    // the trunk continues to the next sibling unless this is the last one
                                    Shape {
                                        anchors.fill: parent
                                        preferredRendererType: Shape.CurveRenderer
                                        ShapePath {
                                            strokeColor: Qt.alpha(root.c.strong, 0.3)
                                            strokeWidth: 1.5
                                            fillColor: "transparent"
                                            capStyle: ShapePath.RoundCap
                                            PathSvg {
                                                readonly property real x0: root.trunkX
                                                readonly property real mid: child.height / 2
                                                readonly property real r: 6
                                                path: `M ${x0} 0 L ${x0} ${mid - r} Q ${x0} ${mid} ${x0 + r} ${mid} L ${x0 + 12} ${mid}` + (child.last ? "" : ` M ${x0} ${mid - r} L ${x0} ${child.height}`)
                                            }
                                        }
                                    }

                                    StyledText {
                                        x: root.trunkX + 16 + Tokens.spacing.s
                                        anchors.verticalCenter: parent.verticalCenter
                                        text: child.modelData.title
                                        font.weight: child.isCurrent ? Font.Bold : Font.Medium
                                        color: child.isCurrent ? (root.c.kind === "tone" ? root.c.accent : root.c.strong) : root.c.weak
                                        Behavior on color {
                                            K.CAnim {}
                                        }
                                    }

                                    K.StateLayer {
                                        id: childMouse
                                        anchors.fill: undefined
                                        x: root.trunkX + 16
                                        width: parent.width - x
                                        height: parent.height
                                        radius: height / 2
                                        color: root.c.strong
                                        onClicked: root.picked(child.modelData.parentId + "/" + child.modelData.id)
                                    }
                                }
                            }
                        }
                    }
                }
            }
        }
    }

    StyledText {
        anchors.bottom: parent.bottom
        anchors.bottomMargin: Tokens.spacing.m
        anchors.horizontalCenter: parent.horizontalCenter
        text: "Changes apply instantly"
        font.pixelSize: Tokens.font.small
        color: root.c.weak
    }
}
