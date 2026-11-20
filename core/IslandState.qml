pragma Singleton

import QtQml

// Live, in-memory only: which page a `call` put on top of each island's
// idle page. Never written to disk — that's exactly what makes `call`
// momentary and `set` (which goes straight to config.json) permanent
// (decision 4b.1). An island can be mirrored on several screens; they all
// share one entry here, keyed by island name, since a call isn't tied to
// a monitor.
QtObject {
    id: root

    property var calledPages: ({}) // islandName -> pageName

    function call(islandName, pageName) {
        const next = Object.assign({}, calledPages);
        next[islandName] = pageName;
        calledPages = next;
    }

    function clearCall(islandName) {
        if (!(islandName in calledPages)) return;
        const next = Object.assign({}, calledPages);
        delete next[islandName];
        calledPages = next;
    }

    function calledPage(islandName) {
        return calledPages[islandName] ?? "";
    }
}
