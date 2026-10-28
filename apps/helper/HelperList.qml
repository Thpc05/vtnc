import QtQuick
import Quickshell
import qs.theme
import qs.kit as K
import qs.dwidgets.quick.panels

// A Helper tab's body (2026-10-17): the hero card (what the tab is, how it works), a search, then the
// sections as cards (user) in two columns, each card going to the shorter one (a section longer than
// half of it all splits into two cards), so most of it shows at once; the area scrolls when it's
// longer. `extra` content (the About's tour) sits above the cards, in the scrolled area. Rows
// (HelperRow) with `copy` copy it on Enter / a click (a "Copied" hint at the bottom). ↑/↓ go through
// the rows in reading order (the first column's cards, then the second's); ←/→ jump between the
// columns (empty search). In the apps' look.
// sections: [{ title, rows: [{ keys?: [..], button?, place?, key?, text, copy? }] }]
FocusScope {
    id: root

    property var sections: []
    property string note: ""
    property string placeholder: "Search…"
    property int keyWidth: 220
    // descriptions wrap (up to 2 lines) instead of eliding; every row is then 52 tall
    property bool wrap: false
    property bool searchable: true
    // the hero
    property string heroIcon
    property string heroTitle
    property string heroText
    property string heroShape: "cookie7"
    // content above the cards (inside the scrolled area)
    default property alias extra: extraBox.data
    property real extraHeight: 0

    readonly property PanelColors c: PanelColors {
        look: K.Kit.appLook
    }
    readonly property int gap: 16
    readonly property int rowHeight: wrap ? 52 : 36
    readonly property int cardTitle: 34
    readonly property int cardPad: 6

    // the cards (a long section split in two) placed in two columns; their rows numbered in reading order
    readonly property var layout: {
        const q = input.text.trim().toLowerCase();
        const cards = [];
        let total = 0;
        for (const s of sections) {
            const rs = s.rows.filter(r => q === "" || [r.text, r.key, r.place, r.button, (r.keys ?? []).join(" ")].join(" ").toLowerCase().includes(q));
            if (rs.length > 0) {
                cards.push({
                    title: s.title ?? "",
                    rows: rs
                });
                total += rs.length;
            }
        }
        // two columns in reading order (the first, then the second), cut where their heights are closest;
        // a cut inside a section splits it into two cards, the second without the title
        const h = cd => (cd.title ? cardTitle : cardPad) + cd.rows.length * rowHeight + cardPad + gap;
        const colHeight = list => list.reduce((a, cd) => a + h(cd), 0);
        let best = null;
        for (let ci = 0; ci < cards.length; ci++) {
            const cd = cards[ci];
            for (let k = 0; k <= cd.rows.length; k++) {
                if (k === 0 && ci === 0)
                    continue;
                const leftCards = cards.slice(0, ci).concat(k > 0 ? [{
                            title: cd.title,
                            rows: cd.rows.slice(0, k)
                        }] : []);
                const rightCards = (k < cd.rows.length ? [{
                            title: k > 0 ? "" : cd.title,
                            rows: cd.rows.slice(k)
                        }] : []).concat(cards.slice(ci + 1));
                const diff = Math.abs(colHeight(leftCards) - colHeight(rightCards));
                // a cut inside a section costs a little: whole cards win a tie
                const score = diff + (k > 0 && k < cd.rows.length ? rowHeight / 2 : 0);
                if (!best || score < best.score)
                    best = {
                        score: score,
                        cols: [leftCards, rightCards]
                    };
            }
        }
        const cols = best ? best.cols : [cards, []];
        const heights = [colHeight(cols[0]), colHeight(cols[1])];
        // number the rows: the first column, then the second
        const flat = [];
        for (let ci = 0; ci < 2; ci++)
            for (const cd of cols[ci]) {
                cd.first = flat.length;
                for (const r of cd.rows)
                    flat.push(Object.assign({
                        column: ci
                    }, r));
            }
        return {
            columns: cols,
            heights: heights,
            rows: flat
        };
    }
    readonly property var rows: layout.rows

    // the current row: an index into `rows`
    property int current: -1
    readonly property var currentRow: rows[current] ?? null

    function reset() {
        input.text = "";
        current = rows.length > 0 ? 0 : -1;
        flick.contentY = 0;
        input.forceActiveFocus();
    }

    function step(dir: int) {
        const i = current + dir;
        if (i >= 0 && i < rows.length)
            current = i;
    }

    // the other column, at about the same place
    function across() {
        if (current < 0)
            return;
        const col = rows[current].column;
        const mine = rows.map((r, i) => i).filter(i => rows[i].column === col);
        const other = rows.map((r, i) => i).filter(i => rows[i].column !== col);
        if (other.length > 0)
            current = other[Math.min(mine.indexOf(current), other.length - 1)];
    }

    property string copied: ""
    Timer {
        id: copiedTimer
        interval: 1500
        onTriggered: root.copied = ""
    }
    function copy(r: var) {
        if (!r?.copy)
            return;
        Quickshell.execDetached(["wl-copy", "--", r.copy]);
        copied = r.copy;
        copiedTimer.restart();
    }

    onRowsChanged: Qt.callLater(() => root.current = root.rows.length > 0 ? 0 : -1)

    // keep the current row in view (its y in the scrolled area, set by the row)
    function reveal(y: real) {
        const top = flick.contentY;
        if (y < top + 8)
            flick.contentY = Math.max(0, y - 8);
        else if (y + rowHeight > top + flick.height - 8)
            flick.contentY = Math.max(0, Math.min(flick.contentHeight - flick.height, y + rowHeight - flick.height + 8));
    }

    // hero --------------------------------------------------------------------
    HelperHero {
        id: hero
        width: parent.width
        icon: root.heroIcon
        title: root.heroTitle
        text: root.heroText
        shape: root.heroShape
    }

    // search --------------------------------------------------------------------
    K.SearchBar {
        id: input
        anchors.top: hero.bottom
        anchors.topMargin: root.searchable ? Tokens.spacing.m : 0
        width: parent.width
        height: root.searchable ? 40 : 0
        visible: root.searchable
        topPadding: 0
        bottomPadding: 0
        focus: true
        placeholderText: root.placeholder
        font: Qt.font({
            family: K.Kit.family,
            pixelSize: Tokens.font.normal,
            variableAxes: K.Kit.axes
        })
        Keys.onPressed: e => {
            if (e.key === Qt.Key_Down)
                root.step(1);
            else if (e.key === Qt.Key_Up)
                root.step(-1);
            else if ((e.key === Qt.Key_Left || e.key === Qt.Key_Right) && input.text === "")
                root.across();
            else if (e.key === Qt.Key_Return || e.key === Qt.Key_Enter)
                root.copy(root.currentRow);
            else
                return;
            e.accepted = true;
        }
    }

    // the cards ------------------------------------------------------------------
    Flickable {
        id: flick
        anchors.top: input.bottom
        anchors.topMargin: Tokens.spacing.m
        anchors.bottom: footer.top
        anchors.bottomMargin: footer.height > 0 ? 6 : 0
        width: parent.width
        clip: true
        contentWidth: width
        readonly property real cardsTop: root.extraHeight > 0 ? root.extraHeight + root.gap : 0
        contentHeight: cardsTop + Math.max(0, Math.max(root.layout.heights[0], root.layout.heights[1]) - root.gap)
        boundsBehavior: Flickable.StopAtBounds
        Behavior on contentY {
            K.Anim {
                type: K.Anim.FastSpatial
            }
        }

        Item {
            id: extraBox
            width: flick.width
            height: root.extraHeight
        }

        Repeater {
            model: 2

            Column {
                id: col
                required property int index
                y: flick.cardsTop
                x: index * (width + root.gap)
                width: (flick.width - root.gap) / 2
                spacing: root.gap

                Repeater {
                    model: root.layout.columns[col.index]

                    // a section's card
                    Rectangle {
                        id: card
                        required property var modelData
                        width: col.width
                        height: (modelData.title ? root.cardTitle : root.cardPad) + modelData.rows.length * root.rowHeight + root.cardPad
                        radius: K.Kit.rounding.large
                        color: root.c.shapes ? K.Kit.expressive.container : root.c.kind === "tones" ? Qt.tint(K.Kit.expressive.container, Qt.alpha(root.c.accent, K.Kit.expressive.light ? 0.08 : 0.06)) : "transparent"
                        border.width: root.c.kind === "tone" ? 1 : 0
                        border.color: Qt.alpha(root.c.accent, 0.22)

                        K.StyledText {
                            visible: card.modelData.title !== ""
                            x: 14
                            y: 12
                            text: card.modelData.title
                            font.family: K.Kit.family
                            font.variableAxes: K.Kit.axes
                            font.pixelSize: 12
                            font.weight: 600
                            color: root.c.accent
                        }

                        Column {
                            x: root.cardPad
                            y: card.modelData.title ? root.cardTitle : root.cardPad
                            width: card.width - 2 * root.cardPad

                            Repeater {
                                model: card.modelData.rows

                                HelperRow {
                                    id: hr
                                    required property var modelData
                                    required property int index
                                    readonly property int at: card.modelData.first + index
                                    width: parent.width
                                    item: modelData
                                    c: root.c
                                    inCard: true
                                    keyWidth: root.keyWidth - root.cardPad
                                    wrap: root.wrap
                                    current: at === root.current
                                    copiedThis: root.copied !== "" && root.copied === modelData.copy
                                    onHovered: root.current = at
                                    onClicked: root.copy(modelData)
                                    onCurrentChanged: if (current)
                                        Qt.callLater(() => root.reveal(hr.mapToItem(flick.contentItem, 0, 0).y))
                                }
                            }
                        }
                    }
                }
            }
        }
    }

    K.StyledText {
        anchors.centerIn: flick
        visible: root.rows.length === 0 && root.searchable
        text: input.text !== "" ? "No matches" : "Nothing here yet"
        font.family: K.Kit.family
        font.variableAxes: K.Kit.axes
        font.pixelSize: 13
        color: root.c.weak
    }

    // a note about the list, or "Copied"
    K.StyledText {
        id: footer
        anchors.bottom: parent.bottom
        x: Tokens.spacing.s
        width: parent.width - 2 * x
        height: text !== "" ? 18 : 0
        verticalAlignment: Text.AlignBottom
        text: root.copied !== "" ? "Copied: " + root.copied : root.note
        elide: Text.ElideMiddle
        font.family: K.Kit.family
        font.variableAxes: K.Kit.axes
        font.pixelSize: 11
        color: root.copied !== "" ? root.c.accent : root.c.weak
    }
}
