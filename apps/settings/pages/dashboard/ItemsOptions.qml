import QtQuick
import qs.core
import qs.components
import qs.theme
import qs.kit as K
import "../../controls"

// The chosen-items options of a Dwidget / Iwidget (Dashboard → Layout and Island → Layout side panels):
// which of its mini widgets it shows in what order (options.items): Quick configs' Qwidgets, Sliders'
// Swidgets. Shown: drag to reorder, click to select (then remove it, or pick an App's target).
// Add: click to add, one group at a time (tabs) when the catalog has GROUPS. `catalog` is the items' JS catalog
// (entries `{ title, icon }`, items(options), available(shown); optionally raw(options) — the stored
// list, where an entry may be an instance object { id, target } and ids may repeat — GROUPS and
// MAX_ITEMS). The list is edited by position, so repeats are fine.
Item {
    id: root

    required property var entry
    required property var catalog
    required property var entries
    property string heading
    property string hint
    // the island's list (catalog filters: no panel-only Qwidgets)
    property bool island: false
    signal edited(var options)

    // the stored list (ids or instance objects) and what can be added
    readonly property var stored: catalog.raw ? catalog.raw(entry?.options, island) : catalog.items(entry?.options)
    readonly property var rest: catalog.available(stored, island)
    readonly property int maxItems: catalog.MAX_ITEMS ?? 0
    readonly property var groups: catalog.GROUPS ?? []
    // the group shown under "Add"
    property string group: groups[0]?.id ?? ""

    function idOf(e: var): string {
        return typeof e === "string" ? e : (e?.id ?? "");
    }
    // a stored entry's label: an App shows its target's name
    function titleOf(e: var): string {
        const info = entries[idOf(e)] ?? {};
        if (info.config === "target")
            return typeof e === "object" && e.target ? Launch.describe(e.target).title : `${info.title} (pick one)`;
        return info.title ?? idOf(e);
    }

    // the selected position (-1: none)
    property int selected: -1
    readonly property var selectedEntry: selected >= 0 && selected < stored.length ? stored[selected] : null
    onStoredChanged: if (selected >= stored.length)
        selected = -1

    // the position being dragged
    property int dragIndex: -1
    property bool dragActive: false

    function write(list: var) {
        root.edited(Object.assign({}, root.entry?.options ?? {}, {
            items: list
        }));
    }

    // move position `from` to just before position `before` (-1 = the end)
    function move(from: int, before: int) {
        const list = root.stored.slice();
        const item = list.splice(from, 1)[0];
        let at = before < 0 ? list.length : (before > from ? before - 1 : before);
        list.splice(at, 0, item);
        selected = -1;
        root.write(list);
    }
    function remove(i: int) {
        const list = root.stored.slice();
        list.splice(i, 1);
        selected = -1;
        root.write(list);
    }
    function add(id: string) {
        const at = root.stored.length;
        root.write(root.stored.concat([id]));
        // one that needs a target: select it and open the picker
        if ((root.entries[id] ?? {}).config === "target") {
            selected = at;
            Qt.callLater(() => detailPicker.open = true);
        }
    }
    function setTarget(i: int, target: string) {
        const list = root.stored.slice();
        list[i] = {
            id: root.idOf(list[i]),
            target: target
        };
        root.write(list);
    }

    width: parent?.width ?? 0
    implicitHeight: column.implicitHeight

    component Chip: Rectangle {
        id: chip

        property var item: ""
        property bool dim: false
        property bool current: false
        readonly property string qid: root.idOf(item)
        readonly property var info: root.entries[qid] ?? ({})

        implicitWidth: chipRow.implicitWidth + 2 * Tokens.spacing.s
        implicitHeight: 28
        radius: height / 2
        color: current ? Colors.primary : dim ? "transparent" : (chipMouse.containsMouse ? K.Kit.expressive.high : K.Kit.expressive.off)
        border.width: dim ? 1 : 0
        border.color: Colors.outlineVariant

        Row {
            id: chipRow
            anchors.centerIn: parent
            spacing: Tokens.spacing.xs

            Icon {
                anchors.verticalCenter: parent.verticalCenter
                icon: Icons[chip.info.icon] ?? ""
                size: 14
                color: chip.current ? Colors.overPrimary : chip.dim ? Colors.outline : Colors.primary
            }
            StyledText {
                anchors.verticalCenter: parent.verticalCenter
                text: chip.dim ? (chip.info.title ?? chip.qid) : root.titleOf(chip.item)
                font.pixelSize: Tokens.font.small
                color: chip.current ? Colors.overPrimary : chip.dim ? Colors.overSurfaceVariant : Colors.overBackground
            }
        }

        MouseArea {
            id: chipMouse
            anchors.fill: parent
            hoverEnabled: true
            cursorShape: Qt.PointingHandCursor
        }
    }

    Column {
        id: column
        width: parent.width
        spacing: Tokens.spacing.xs

        StyledText {
            topPadding: Tokens.spacing.m
            text: root.heading
            font.pixelSize: Tokens.font.small
            font.weight: Font.Bold
            color: Colors.primary
        }
        StyledText {
            width: parent.width
            wrapMode: Text.Wrap
            text: root.hint
            font.pixelSize: Tokens.font.small
            color: Colors.overSurfaceVariant
        }

        Flow {
            id: shownFlow
            width: parent.width
            spacing: 4

            Repeater {
                model: root.stored

                Chip {
                    id: shownChip

                    required property var modelData
                    required property int index
                    item: modelData
                    current: root.selected === index
                    opacity: root.dragActive && root.dragIndex === index ? 0.3 : 1

                    // drop another chip here: it goes before this one
                    DropArea {
                        anchors.fill: parent
                        keys: ["vtnc-item"]
                        onDropped: {
                            const from = root.dragIndex;
                            const before = shownChip.index;
                            if (from >= 0 && from !== before)
                                Qt.callLater(() => root.move(from, before));
                        }
                    }

                    MouseArea {
                        property point pressPos

                        anchors.fill: parent
                        preventStealing: true
                        cursorShape: root.dragActive ? Qt.ClosedHandCursor : Qt.PointingHandCursor
                        onPressed: m => {
                            pressPos = Qt.point(m.x, m.y);
                            root.dragIndex = shownChip.index;
                            ghost.grab = Qt.point(m.x, m.y);
                        }
                        onPositionChanged: m => {
                            if (!pressed)
                                return;
                            if (!root.dragActive && Math.hypot(m.x - pressPos.x, m.y - pressPos.y) > 6)
                                root.dragActive = true;
                            if (root.dragActive) {
                                const p = mapToItem(root, m.x, m.y);
                                ghost.x = p.x - ghost.grab.x;
                                ghost.y = p.y - ghost.grab.y;
                            }
                        }
                        onReleased: {
                            const wasDrag = root.dragActive;
                            if (wasDrag)
                                ghost.Drag.drop();
                            root.dragActive = false;
                            if (!wasDrag)
                                root.selected = root.selected === shownChip.index ? -1 : shownChip.index;
                            root.dragIndex = -1;
                        }
                        onCanceled: {
                            root.dragActive = false;
                            root.dragIndex = -1;
                        }
                    }
                }
            }

            // the end of the list (drop here = last)
            Rectangle {
                width: 28
                height: 28
                radius: height / 2
                color: "transparent"
                border.width: endDrop.containsDrag ? 1 : 0
                border.color: Colors.primary
                visible: root.dragActive

                DropArea {
                    id: endDrop
                    anchors.fill: parent
                    keys: ["vtnc-item"]
                    onDropped: {
                        const from = root.dragIndex;
                        if (from >= 0)
                            Qt.callLater(() => root.move(from, -1));
                    }
                }
            }
        }

        // the selected one: remove it, or pick what an App opens
        Rectangle {
            width: parent.width
            visible: root.selectedEntry !== null
            implicitHeight: detail.implicitHeight + 2 * Tokens.spacing.s
            radius: K.Kit.rounding.large
            color: K.Kit.expressive.off

            Column {
                id: detail
                x: Tokens.spacing.s
                y: Tokens.spacing.s
                width: parent.width - 2 * Tokens.spacing.s
                spacing: Tokens.spacing.s

                Row {
                    spacing: Tokens.spacing.s

                    StyledText {
                        anchors.verticalCenter: parent.verticalCenter
                        text: root.selectedEntry !== null ? root.titleOf(root.selectedEntry) : ""
                        font.pixelSize: Tokens.font.small
                        font.weight: Font.Bold
                        color: Colors.overBackground
                    }
                    SmallButton {
                        anchors.verticalCenter: parent.verticalCenter
                        text: "Remove"
                        danger: true
                        onClicked: root.remove(root.selected)
                    }
                }
                TargetPicker {
                    id: detailPicker
                    width: parent.width
                    visible: (root.entries[root.idOf(root.selectedEntry)] ?? {}).config === "target"
                    value: typeof root.selectedEntry === "object" && root.selectedEntry !== null ? (root.selectedEntry.target ?? "") : ""
                    onEdited: v => root.setTarget(root.selected, v)
                }
            }
        }

        StyledText {
            visible: root.maxItems > 0 && root.stored.length >= root.maxItems
            width: parent.width
            wrapMode: Text.Wrap
            text: `At most ${root.maxItems}: remove one to add another`
            font.pixelSize: Tokens.font.small
            color: Colors.outline
        }

        // what can be added: one group at a time (tabs), its chips below
        StyledText {
            visible: root.rest.length > 0
            topPadding: Tokens.spacing.xs
            text: "Add"
            font.pixelSize: Tokens.font.small
            color: Colors.outline
        }
        Segmented {
            visible: root.rest.length > 0 && root.groups.length > 1
            maxWidth: column.width
            options: root.groups.map(g => ({
                        value: g.id,
                        label: g.title
                    }))
            value: root.group
            onSelected: v => root.group = v
        }
        Flow {
            width: parent.width
            spacing: 4

            Repeater {
                model: root.rest.filter(id => root.groups.length <= 1 || (root.entries[id]?.group ?? "") === root.group)

                Chip {
                    id: restChip

                    required property string modelData
                    item: modelData
                    dim: true

                    MouseArea {
                        anchors.fill: parent
                        cursorShape: Qt.PointingHandCursor
                        onClicked: {
                            const id = restChip.qid;
                            Qt.callLater(() => root.add(id));
                        }
                    }
                }
            }
        }
    }

    // follows the pointer while reordering (outside the Flows, so they don't lay it out)
    Chip {
        id: ghost

        property point grab

        item: root.dragIndex >= 0 ? root.stored[root.dragIndex] ?? "" : ""
        visible: root.dragActive
        z: 10
        border.width: 2
        border.color: Colors.primary

        Drag.active: root.dragActive
        Drag.keys: ["vtnc-item"]
        Drag.hotSpot.x: grab.x
        Drag.hotSpot.y: grab.y
    }
}
