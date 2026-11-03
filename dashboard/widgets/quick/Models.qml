import QtQuick
import "qwidgets" as Q
import "qwidgets.js" as Catalog

// The Qwidget models of a list of instances (qwidgets.js items(): { key, id, config }), one model per
// instance, for the Quick configs Dwidget and Iwidget. A model lives while its key stays in the list (a
// change elsewhere doesn't recreate it: a JS-array model would), and gets its instance's config in
// place. `models` maps key → model.
Item {
    id: root

    visible: false

    property var instances: []
    property var models: ({})

    onInstancesChanged: sync()
    Component.onCompleted: sync()
    Component.onDestruction: {
        for (const k in models)
            models[k].destroy();
    }

    function sync() {
        const next = {};
        for (const inst of instances) {
            let m = models[inst.key] ?? null;
            if (m && JSON.stringify(m.config) !== JSON.stringify(inst.config))
                m.config = inst.config;
            if (!m)
                m = create(inst);
            if (m)
                next[inst.key] = m;
        }
        for (const k in models)
            if (!next[k])
                models[k].destroy();
        models = next;
    }

    function create(inst: var): QtObject {
        const q = Catalog.QWIDGETS[inst.id];
        if (!q)
            return null;
        const props = {
            qid: inst.id,
            config: inst.config
        };
        let c = components[inst.id] ?? null;
        if (q.tool) {
            c = tool;
            props.tool = q.tool;
        } else if (q.action) {
            c = session;
            props.sessionAction = q.action;
        } else if (inst.id === "settings") {
            props.target = "vtnc:settings";
        }
        return c ? c.createObject(root, props) : null;
    }

    readonly property var components: ({
            wifi: wifi,
            bluetooth: bluetooth,
            nightLight: nightLight,
            caffeine: caffeine,
            gameMode: gameMode,
            dnd: dnd,
            powerProfile: powerProfile,
            microphone: microphone,
            lightMode: lightMode,
            mixer: mixer,
            transparency: transparency,
            scheme: scheme,
            wallpaper: wallpaper,
            app: app,
            settings: app
        })

    Component {
        id: wifi
        Q.Wifi {}
    }
    Component {
        id: bluetooth
        Q.Bluetooth {}
    }
    Component {
        id: nightLight
        Q.NightLight {}
    }
    Component {
        id: caffeine
        Q.Caffeine {}
    }
    Component {
        id: gameMode
        Q.GameMode {}
    }
    Component {
        id: dnd
        Q.Dnd {}
    }
    Component {
        id: powerProfile
        Q.PowerProfile {}
    }
    Component {
        id: microphone
        Q.Microphone {}
    }
    Component {
        id: lightMode
        Q.LightMode {}
    }
    Component {
        id: mixer
        Q.Mixer {}
    }
    Component {
        id: transparency
        Q.Transparency {}
    }
    Component {
        id: scheme
        Q.ColorScheme {}
    }
    Component {
        id: wallpaper
        Q.Wallpaper {}
    }
    Component {
        id: app
        Q.App {}
    }
    Component {
        id: tool
        Q.Tool {}
    }
    Component {
        id: session
        Q.SessionAction {}
    }
}
