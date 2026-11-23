pragma Singleton

import QtQml
import "./config-shape.mjs" as ConfigShape

// Live, in-memory only: which pages are stacked on top of each island's
// idle page (decision 1e.2), and which page each mirror is actually
// drawing (0.506, for criterion 3 — observable from outside without
// looking at a pixel). Never written to disk — that's what makes a call
// momentary and `set` (straight to config.json) permanent (decision 4b.1).
//
// Supersedes the 0.505 slang of "call the idle page back to end a call":
// `end` is the real verb now, popping the stack instead of pretending a
// call to idle is the same thing.
QtObject {
    id: root

    property var stacks: ({}) // islandName -> [pageName, ...], top = last, max 5 (ConfigShape.CALL_STACK_LIMIT)

    // "o gatilho mora na page" (decision 1b.5): this is reached from the
    // `page` IpcHandler (vtnc page <name> call <island>), never from
    // `island` — the island itself declares no trigger.
    function call(islandName, pageName) {
        const next = Object.assign({}, stacks);
        next[islandName] = ConfigShape.pushCall(stacks[islandName], pageName);
        stacks = next;
    }

    // Unstacks one level (decision 1e.2): Esc, click-outside, a popup's own
    // timeout/close button, or `vtnc island <name> end` all land here.
    // Lands on idle by itself once the stack is empty — island/Island.qml's
    // currentPageName already falls back there, nothing special-cased.
    function end(islandName) {
        if (!(islandName in stacks)) return;
        const popped = ConfigShape.popCall(stacks[islandName]);
        const next = Object.assign({}, stacks);
        if (popped.length > 0) next[islandName] = popped;
        else delete next[islandName];
        stacks = next;
    }

    function calledPage(islandName) {
        return ConfigShape.topOfCall(stacks[islandName]);
    }

    // Per-mirror observability (0.506 criterion 3): each Island.qml
    // instance reports what it's actually drawing, keyed by its own
    // Hyprland monitor name — a called page only reaches one mirror (the
    // focused one), the others keep wearing what they had. Read back
    // through `vtnc island <name> get`'s `mirrors` field, so criterion 3
    // can be confirmed without comparing pixels.
    property var mirrorPages: ({}) // "islandName@monitorName" -> pageName

    function setMirrorPage(islandName, monitorName, pageName) {
        const key = islandName + "@" + monitorName;
        if (mirrorPages[key] === pageName) return;
        const next = Object.assign({}, mirrorPages);
        next[key] = pageName;
        mirrorPages = next;
    }

    function mirrorPagesFor(islandName) {
        const prefix = islandName + "@";
        const result = {};
        for (const key of Object.keys(mirrorPages)) {
            if (key.startsWith(prefix)) result[key.slice(prefix.length)] = mirrorPages[key];
        }
        return result;
    }
}
