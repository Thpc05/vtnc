import QtQuick
import qs.core
import qs.components
import qs.theme
import qs.kit as K
import "../../controls"
import "../dashboard"
import "../../../../dwidgets/quick/qwidgets.js" as Qw

// Island widgets:
//  - layout editor: three anchor columns (left / center / right) and the widgets that are off;
//    drag a chip to move it between columns / off, or to reorder it inside a column
//  - click a chip to select it; the detail panel below picks its style (or Hidden) per mode,
//    with a live preview of each, plus the widget's own options (`options` below)
//  - an Iwidget may be on the island more than once (2026-10-11, as the Dwidgets): entries have a
//    `uid`; the original is uid = id, Duplicate makes copies (`<id>-2`…, marked "copy"). Only the
//    original goes to Off: a copy taken off (or dragged there) is deleted. The options are the
//    Iwidget's, shared by its copies
Page {
    id: page

    readonly property var widgets: (Store.island.widgets ?? []).filter(w => WidgetRegistry.has(w.id))
    readonly property var columns: [
        {
            section: "left",
            title: "Left"
        },
        {
            section: "center",
            title: "Center"
        },
        {
            section: "right",
            title: "Right"
        }
    ]

    readonly property int chipHeight: 32
    readonly property int chipSpacing: 4
    readonly property int rowStep: chipHeight + chipSpacing

    // chip being dragged (its entry), shared by the drop areas for the indicator
    property var dragEntry: null

    function inSection(section: string): var {
        return widgets.filter(w => w.section === section);
    }

    function isCopy(w: var): bool {
        return !!w && w.uid !== w.id;
    }

    // move entry `uid` to `section` at position `index` among that section's widgets; a copy sent to
    // Off is deleted (only the original may be off)
    function moveTo(uid: string, section: string, index: int) {
        const moved = widgets.find(w => w.uid === uid);
        if (!moved)
            return;
        const rest = widgets.filter(w => w.uid !== uid).map(w => Object.assign({}, w));
        if (section === "off" && isCopy(moved)) {
            Store.island.widgets = rest;
            return;
        }
        const target = rest.filter(w => w.section === section);
        const others = rest.filter(w => w.section !== section);
        // the styles per mode are kept, also while off (restored when it comes back)
        target.splice(Math.max(0, Math.min(index, target.length)), 0, Object.assign({}, moved, {
            section: section
        }));
        Store.island.widgets = others.concat(target);
    }

    // mode: "compact" | "expanded"; style: a style id or WidgetRegistry.hidden
    function setStyle(uid: string, mode: string, style: string) {
        Store.island.widgets = widgets.map(w => {
            const copy = Object.assign({}, w);
            if (w.uid === uid)
                copy[mode] = style;
            return copy;
        });
    }

    // a copy of entry `uid` right after it (uid `<id>-2`, `-3`…), selected; never in Off (it keeps one
    // of each), so a copy of an off one goes to the center
    function duplicate(uid: string) {
        const i = widgets.findIndex(w => w.uid === uid);
        if (i < 0)
            return;
        const w = widgets[i];
        let n = 2;
        while (widgets.some(x => x.uid === `${w.id}-${n}`))
            n++;
        const copy = Object.assign({}, w, {
            uid: `${w.id}-${n}`,
            section: w.section === "off" ? "center" : w.section
        });
        const list = widgets.map(x => Object.assign({}, x));
        list.splice(i + 1, 0, copy);
        Store.island.widgets = list;
        selectedUid = copy.uid;
    }

    // selected chip (entry uid); the detail panel edits it
    property string selectedUid: widgets.find(w => w.section !== "off")?.uid ?? widgets[0]?.uid ?? ""
    readonly property var selected: widgets.find(w => w.uid === selectedUid) ?? null
    readonly property string selectedId: selected?.id ?? ""

    // widget-specific options shown in the detail panel: id → Component
    readonly property var options: ({
            clock: clockOptions,
            date: dateOptions,
            notifications: notificationOptions,
            workspaces: workspacesOptions,
            tray: trayOptions,
            media: mediaOptions,
            visualizer: visualizerOptions,
            quick: quickOptions,
            window: windowOptions,
            battery: batteryOptions,
            volume: volumeOptions,
            dock: dockOptions
        })

    Component {
        id: workspacesOptions
        WorkspacesOptions {}
    }
    Component {
        id: trayOptions
        TrayOptions {}
    }
    Component {
        id: mediaOptions
        MediaOptions {}
    }
    Component {
        id: visualizerOptions
        VisualizerOptions {}
    }
    Component {
        id: windowOptions
        WindowOptions {}
    }
    Component {
        id: batteryOptions
        BatteryOptions {}
    }
    Component {
        id: volumeOptions
        VolumeOptions {}
    }
    Component {
        id: dockOptions
        DockOptions {}
    }
    Component {
        id: quickOptions
        QuickOptions {
            catalog: Qw
            entries: Qw.QWIDGETS
        }
    }

    Component {
        id: clockOptions
        ClockOptions {}
    }
    Component {
        id: dateOptions
        ClockOptions {
            which: "date"
        }
    }
    Component {
        id: notificationOptions
        NotificationOptions {}
    }

    readonly property var sectionTitles: ({
            left: "Left",
            center: "Center",
            right: "Right",
            off: "Off"
        })

    // short label of a style for the chip markers: "Two tones" → "TT", "Icon + slider" → "IS" (a card
    // variant has its parent's; the mark itself is drawn as a card, ModeMark)
    function abbrev(id: string, style: string): string {
        const base = WidgetRegistry.baseStyle(id, style);
        const s = WidgetRegistry.styles(id).find(x => x.id === base);
        return s ? s.title.split(/\s+/).filter(w => w !== "+").map(w => w[0].toUpperCase()).join("") : "";
    }

    StyledText {
        width: parent.width
        leftPadding: Tokens.spacing.s
        wrapMode: Text.Wrap
        text: "Compact is the island at rest; expanded is while it's hovered or expanded. Drag a widget to anchor it or to take it out of the island, and select it to choose its look in each mode. The two marks on a widget show its compact and expanded look (a pill: on the card)."
        font.pixelSize: Tokens.font.small
        color: Colors.overSurfaceVariant
    }

    // chip ---------------------------------------------------------------------
    // Dragging doesn't move the chip itself: a ghost copy follows the cursor in the page's
    // content layer (reparenting mid-drag breaks the drag coordinates) and carries the Drag.
    property bool dragActive: false

    component ChipFace: Rectangle {
        id: face

        property var entry: ({})
        property bool highlighted: false
        property bool hovered: false
        property bool selected: false
        readonly property var info: WidgetRegistry.widgets[entry.id] ?? {}
        // never visible in the island: off, or hidden in both modes
        readonly property bool dim: entry.section === "off" || (entry.compact === WidgetRegistry.hidden && entry.expanded === WidgetRegistry.hidden)

        implicitWidth: label.implicitWidth + 4 * Tokens.spacing.s + 16 + marks.implicitWidth
        implicitHeight: page.chipHeight
        radius: height / 2
        color: highlighted ? Colors.primary : (hovered ? K.Kit.expressive.high : K.Kit.expressive.off)
        border.width: selected && !highlighted ? 2 : 0
        border.color: Colors.primary
        Behavior on color {
            ColorAnimation {
                duration: Tokens.anim.faster
            }
        }

        Row {
            anchors.verticalCenter: parent.verticalCenter
            x: Tokens.spacing.s
            spacing: Tokens.spacing.s

            Icon {
                anchors.verticalCenter: parent.verticalCenter
                icon: Icons[face.info.icon] ?? Icons.puzzlePiece
                size: 16
                color: face.highlighted ? Colors.overPrimary : (face.dim ? Colors.outline : Colors.primary)
            }

            StyledText {
                id: label
                anchors.verticalCenter: parent.verticalCenter
                // a copy is tagged with its number ("clock-2" → "Clock · copy 2")
                readonly property string copy: (face.entry.uid ?? "") !== (face.entry.id ?? "") && (face.entry.uid ?? "").startsWith((face.entry.id ?? "") + "-") ? face.entry.uid.slice(face.entry.id.length + 1) : ""
                text: (face.info.title ?? face.entry.id ?? "") + (copy !== "" ? " · copy " + copy : "")
                font.pixelSize: Tokens.font.small
                font.weight: Font.DemiBold
                color: face.highlighted ? Colors.overPrimary : (face.dim ? Colors.overSurfaceVariant : Colors.overBackground)
            }
        }

        // compact / expanded marks
        Row {
            id: marks
            anchors.right: parent.right
            anchors.rightMargin: Tokens.spacing.s
            anchors.verticalCenter: parent.verticalCenter
            spacing: 3

            Repeater {
                model: ["compact", "expanded"]

                ModeMark {
                    required property string modelData
                    widgetId: face.entry.id ?? ""
                    value: face.entry[modelData] ?? ""
                    onPrimary: face.highlighted
                }
            }
        }
    }

    // a style's short label (an eye for single-style widgets, an eye-slash when hidden); bare like the
    // style itself, or a little pill in the cards' colour (Appearance → Colors → Cards) for a Card variant
    component ModeMark: Rectangle {
        id: mark

        property string widgetId
        property string value
        property bool onPrimary: false
        readonly property bool isHidden: value === WidgetRegistry.hidden
        readonly property bool card: !isHidden && WidgetRegistry.isCard(widgetId, value)
        readonly property bool single: WidgetRegistry.parents(widgetId).length <= 1
        readonly property color ink: onPrimary ? Colors.overPrimary : card ? K.Kit.card.over : isHidden ? Colors.outline : Colors.overBackground

        implicitWidth: Math.max(20, markText.implicitWidth + 10)
        implicitHeight: 18
        radius: height / 2
        color: !card ? "transparent" : onPrimary ? Qt.alpha(Colors.overPrimary, 0.22) : K.Kit.card.fill
        border.width: card && !onPrimary ? 1 : 0
        border.color: Colors.outlineVariant

        StyledText {
            id: markText
            anchors.centerIn: parent
            visible: !mark.isHidden && !mark.single
            text: page.abbrev(mark.widgetId, mark.value)
            font.pixelSize: Tokens.font.small - 2
            font.weight: Font.Bold
            color: mark.ink
        }
        Icon {
            anchors.centerIn: parent
            visible: mark.isHidden || mark.single
            icon: mark.isHidden ? Icons.eyeSlash : Icons.eye
            size: 12
            color: mark.ink
        }
    }

    component Chip: Item {
        id: chip

        required property var entry
        readonly property bool isDragged: page.dragActive && page.dragEntry?.uid === entry.uid

        implicitWidth: face.implicitWidth
        height: page.chipHeight

        ChipFace {
            id: face
            width: chip.width
            height: chip.height
            entry: chip.entry
            hovered: mouse.containsMouse
            selected: page.selectedUid === chip.entry.uid
            // placeholder look while its ghost is being dragged
            opacity: chip.isDragged ? 0.3 : 1
        }

        MouseArea {
            id: mouse

            property point pressPos

            anchors.fill: parent
            hoverEnabled: true
            preventStealing: true
            cursorShape: chip.isDragged ? Qt.ClosedHandCursor : Qt.PointingHandCursor

            onPressed: m => {
                pressPos = Qt.point(m.x, m.y);
                page.dragEntry = chip.entry;
                ghost.width = chip.width;
                ghost.grab = Qt.point(m.x, m.y);
            }
            onPositionChanged: m => {
                if (!pressed)
                    return;
                if (!page.dragActive && Math.hypot(m.x - pressPos.x, m.y - pressPos.y) > 6)
                    page.dragActive = true;
                if (page.dragActive) {
                    const p = mapToItem(ghost.parent, m.x, m.y);
                    ghost.x = p.x - ghost.grab.x;
                    ghost.y = p.y - ghost.grab.y;
                }
            }
            onReleased: {
                const wasDrag = page.dragActive;
                if (wasDrag)
                    ghost.Drag.drop();
                page.dragActive = false;
                page.dragEntry = null;
                // a plain click selects it for the detail panel
                if (!wasDrag)
                    page.selectedUid = chip.entry.uid;
            }
            onCanceled: {
                page.dragActive = false;
                page.dragEntry = null;
            }
        }
    }

    // anchor columns -----------------------------------------------------------
    Row {
        id: columnsRow

        readonly property int columnWidth: (width - 2 * spacing) / 3
        readonly property int maxRows: Math.max(3, ...page.columns.map(c => page.inSection(c.section).length + 1))

        width: parent.width
        spacing: Tokens.spacing.s

        Repeater {
            model: page.columns

            Card {
                id: column

                required property var modelData
                readonly property var entries: page.inSection(modelData.section)

                width: columnsRow.columnWidth
                height: header.height + columnsRow.maxRows * page.rowStep + Tokens.spacing.s
                color: drop.containsDrag ? K.Kit.expressive.high : K.Kit.expressive.container
                Behavior on color {
                    ColorAnimation {
                        duration: Tokens.anim.faster
                    }
                }

                StyledText {
                    id: header
                    height: 30
                    leftPadding: Tokens.spacing.m
                    verticalAlignment: Text.AlignVCenter
                    text: column.modelData.title
                    font.pixelSize: Tokens.font.small
                    font.weight: Font.Bold
                    color: Colors.primary
                }

                Column {
                    id: list
                    x: Tokens.spacing.s
                    y: header.height
                    width: parent.width - 2 * Tokens.spacing.s
                    spacing: page.chipSpacing

                    Repeater {
                        model: column.entries

                        Chip {
                            required property var modelData
                            entry: modelData
                            width: list.width
                        }
                    }
                }

                // insertion line while dragging over the column
                Rectangle {
                    visible: drop.containsDrag
                    x: list.x
                    width: list.width
                    height: 2
                    radius: 1
                    color: Colors.primary
                    y: list.y + drop.insertIndex * page.rowStep - page.chipSpacing / 2 - 1
                }

                DropArea {
                    id: drop

                    property int insertIndex: 0

                    anchors.fill: parent
                    keys: ["vtnc-widget"]

                    function indexAt(y: real): int {
                        const i = Math.round((y - list.y) / page.rowStep);
                        // don't count the dragged chip itself when it's in this column
                        const n = column.entries.filter(w => w.uid !== page.dragEntry?.uid).length;
                        return Math.max(0, Math.min(i, n));
                    }

                    onEntered: drag => insertIndex = indexAt(drag.y)
                    onPositionChanged: drag => insertIndex = indexAt(drag.y)
                    onDropped: drag => {
                        const entry = page.dragEntry;
                        const section = column.modelData.section;
                        const index = insertIndex;
                        // after the release handler finished: moving rebuilds the chips,
                        // destroying the one whose handler is still running
                        if (entry)
                            Qt.callLater(() => page.moveTo(entry.uid, section, index));
                    }
                }
            }
        }
    }

    // off row ------------------------------------------------------------------
    Card {
        id: offCard

        readonly property var entries: page.inSection("off")

        width: parent.width
        height: offHeader.height + Math.max(page.chipHeight, offFlow.implicitHeight) + Tokens.spacing.m
        color: offDrop.containsDrag ? K.Kit.expressive.high : K.Kit.expressive.container
        Behavior on color {
            ColorAnimation {
                duration: Tokens.anim.faster
            }
        }

        StyledText {
            id: offHeader
            height: 30
            leftPadding: Tokens.spacing.m
            verticalAlignment: Text.AlignVCenter
            text: "Off"
            font.pixelSize: Tokens.font.small
            font.weight: Font.Bold
            color: Colors.outline
        }

        StyledText {
            visible: offCard.entries.length === 0
            x: Tokens.spacing.m
            y: offHeader.height + (page.chipHeight - height) / 2
            text: "Drop a widget here to remove it from the island"
            font.pixelSize: Tokens.font.small
            color: Colors.outline
        }

        Flow {
            id: offFlow
            x: Tokens.spacing.s
            y: offHeader.height
            width: parent.width - 2 * Tokens.spacing.s
            spacing: page.chipSpacing

            Repeater {
                model: offCard.entries

                Chip {
                    required property var modelData
                    entry: modelData
                    width: implicitWidth
                }
            }
        }

        DropArea {
            id: offDrop
            anchors.fill: parent
            keys: ["vtnc-widget"]
            onDropped: drag => {
                const entry = page.dragEntry;
                const index = offCard.entries.length;
                if (entry)
                    Qt.callLater(() => page.moveTo(entry.uid, "off", index));
            }
        }
    }

    // detail panel -------------------------------------------------------------
    // the selected widget: its look per mode (with a live preview) and its own options
    component ModeEditor: Column {
        id: editor

        required property string mode
        required property string title
        required property string description
        required property string widgetId
        required property string uid
        required property string value

        spacing: Tokens.spacing.s

        Column {
            spacing: 1
            StyledText {
                text: editor.title
                font.weight: Font.DemiBold
            }
            StyledText {
                text: editor.description
                font.pixelSize: Tokens.font.small
                color: Colors.overSurfaceVariant
            }
        }

        // stage: the whole card is the island body (its colour and transparency, as the island's
        // surface draws it), the widget as it looks in this mode
        Rectangle {
            width: editor.width
            height: 64
            radius: K.Kit.rounding.large
            color: K.Kit.expressive.page
            clip: true

            WidgetPreview {
                anchors.centerIn: parent
                widgetId: editor.widgetId
                style: editor.value
                mode: editor.mode
            }
        }

        // the parent styles (card variants are the Card switch beside them)
        readonly property bool hidden: editor.value === WidgetRegistry.hidden
        readonly property string base: hidden ? editor.value : WidgetRegistry.baseStyle(editor.widgetId, editor.value)
        readonly property bool card: !hidden && WidgetRegistry.isCard(editor.widgetId, editor.value)
        readonly property string cardId: hidden ? "" : WidgetRegistry.cardVariant(editor.widgetId, base)

        Row {
            spacing: Tokens.spacing.m

            Segmented {
                anchors.verticalCenter: parent.verticalCenter
                readonly property var styles: WidgetRegistry.parents(editor.widgetId)
                options: styles.map(s => ({
                            value: s.id,
                            label: styles.length > 1 ? s.title : "Shown"
                        })).concat([
                        {
                            value: WidgetRegistry.hidden,
                            icon: Icons.eyeSlash,
                            label: "Hidden"
                        }
                    ])
                value: editor.base
                // keeps the card when the new style has one
                onSelected: v => {
                    const variant = v !== WidgetRegistry.hidden && editor.card ? WidgetRegistry.cardVariant(editor.widgetId, v) : "";
                    page.setStyle(editor.uid, editor.mode, variant || v);
                }
            }
            Row {
                anchors.verticalCenter: parent.verticalCenter
                visible: editor.cardId !== ""
                spacing: Tokens.spacing.s
                StyledText {
                    anchors.verticalCenter: parent.verticalCenter
                    text: "Card"
                    font.pixelSize: Tokens.font.small
                    color: Colors.overSurfaceVariant
                }
                Switch {
                    anchors.verticalCenter: parent.verticalCenter
                    checked: editor.card
                    onToggled: c => page.setStyle(editor.uid, editor.mode, c ? editor.cardId : editor.base)
                }
            }
        }
    }

    Card {
        id: detail

        visible: page.selected !== null
        width: parent.width
        height: detailColumn.implicitHeight + 2 * Tokens.spacing.m

        Column {
            id: detailColumn
            x: Tokens.spacing.l
            y: Tokens.spacing.m
            width: parent.width - 2 * Tokens.spacing.l
            spacing: Tokens.spacing.m

            // header: icon, title and where it sits
            Row {
                spacing: Tokens.spacing.s

                Icon {
                    anchors.verticalCenter: parent.verticalCenter
                    icon: Icons[WidgetRegistry.widgets[page.selectedId]?.icon] ?? Icons.puzzlePiece
                    size: 18
                    color: Colors.primary
                }
                StyledText {
                    anchors.verticalCenter: parent.verticalCenter
                    text: WidgetRegistry.widgets[page.selectedId]?.title ?? ""
                    font.pixelSize: Tokens.font.large
                    font.weight: Font.Bold
                }
                StyledText {
                    anchors.verticalCenter: parent.verticalCenter
                    readonly property string section: page.selected?.section ?? "off"
                    text: (section === "off" ? "Off · drag it to a column to use it" : page.sectionTitles[section]) + (page.isCopy(page.selected) ? " · copy (taking it off deletes it)" : "")
                    font.pixelSize: Tokens.font.small
                    color: Colors.outline
                }
            }

            // copies: duplicate it, or take it off the island (the options are shared by the copies)
            Row {
                spacing: Tokens.spacing.s

                SmallButton {
                    text: "Duplicate"
                    onClicked: page.duplicate(page.selectedUid)
                }
                SmallButton {
                    visible: (page.selected?.section ?? "off") !== "off"
                    // a copy can't be off: taking it off deletes it
                    text: page.isCopy(page.selected) ? "Delete copy" : "Take off"
                    danger: page.isCopy(page.selected)
                    onClicked: {
                        const uid = page.selectedUid;
                        page.moveTo(uid, "off", page.inSection("off").length);
                        if (!page.selected)
                            page.selectedUid = page.widgets.find(w => w.section !== "off")?.uid ?? "";
                    }
                }
                StyledText {
                    anchors.verticalCenter: parent.verticalCenter
                    readonly property int copies: page.widgets.filter(w => w.id === page.selectedId && w.section !== "off").length
                    visible: copies > 1
                    text: `${copies} on the island · their options are shared`
                    font.pixelSize: Tokens.font.small
                    color: Colors.outline
                }
            }

            Row {
                id: modes
                width: parent.width
                spacing: Tokens.spacing.l

                ModeEditor {
                    width: (modes.width - modes.spacing) / 2
                    mode: "compact"
                    title: "Compact"
                    description: "The island at rest"
                    widgetId: page.selectedId
                    uid: page.selectedUid
                    value: page.selected?.compact ?? WidgetRegistry.hidden
                }
                ModeEditor {
                    width: (modes.width - modes.spacing) / 2
                    mode: "expanded"
                    title: "Expanded"
                    description: "While hovered or expanded"
                    widgetId: page.selectedId
                    uid: page.selectedUid
                    value: page.selected?.expanded ?? WidgetRegistry.hidden
                }
            }

            // widget-specific options (a null component loads nothing)
            Loader {
                width: parent.width
                sourceComponent: page.options[page.selectedId] ?? null
            }
        }
    }

    ChipFace {
        id: ghost

        property point grab

        parent: page.contentItem
        z: 100
        visible: page.dragActive
        entry: page.dragEntry ?? ({})
        highlighted: true
        height: page.chipHeight

        Drag.active: page.dragActive
        Drag.keys: ["vtnc-widget"]
        Drag.source: ghost
        Drag.hotSpot.x: grab.x
        Drag.hotSpot.y: grab.y
    }
}
