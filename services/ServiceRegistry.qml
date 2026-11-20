pragma Singleton

import QtQml
import "./clock"

// Services are unique and shared, switched on only while some visible
// widget needs them (decision 5.2). The shell — this registry, not the
// widget — keeps the count (decision 5.2b): a widget just acquires/releases
// by name, and never knows whether it was the first or the fifth.
QtObject {
    id: root

    property var instances: ({}) // name -> service instance
    property var refCounts: ({}) // name -> int

    readonly property var knownServices: ["clock"]

    function _componentFor(name) {
        switch (name) {
        case "clock": return clockComponent;
        default: return null;
        }
    }

    function acquire(name) {
        const count = (refCounts[name] ?? 0) + 1;
        refCounts = Object.assign({}, refCounts, { [name]: count });

        if (count === 1) {
            const component = _componentFor(name);
            if (!component) {
                console.warn("vtnc: unknown service:", name);
                return;
            }
            instances = Object.assign({}, instances, { [name]: component.createObject(root) });
        }
    }

    function release(name) {
        const count = (refCounts[name] ?? 0) - 1;

        if (count <= 0) {
            const nextCounts = Object.assign({}, refCounts);
            delete nextCounts[name];
            refCounts = nextCounts;

            const instance = instances[name];
            const nextInstances = Object.assign({}, instances);
            delete nextInstances[name];
            instances = nextInstances;
            if (instance) instance.destroy();
        } else {
            refCounts = Object.assign({}, refCounts, { [name]: count });
        }
    }

    function get(name) {
        return instances[name] ?? null;
    }

    function isRunning(name) {
        return name in instances;
    }

    function holders(name) {
        return refCounts[name] ?? 0;
    }

    function list() {
        return knownServices.map((name) => ({
            name: name,
            running: isRunning(name),
            holders: holders(name),
        }));
    }

    property Component clockComponent: Component {
        Clock {}
    }
}
