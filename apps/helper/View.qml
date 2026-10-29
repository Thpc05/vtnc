import QtQuick
import qs.core
import qs.theme
import qs.kit as K
import qs.dwidgets.quick.panels
import "tabs" as Tabs

// Helper (2026-10-17, a base: the content grows towards 1.0): help for the shell, in tabs shown as one
// connected group in the header (About · Keys · Mouse · CLI · IPC · Glossary), the current one filled in
// the apps' look. A tab change fades through (out fast, in). The last tab is remembered (state.json).
// Keys: Ctrl+Tab / Ctrl+Shift+Tab, Ctrl+1…6. Open on a tab: `qs -c vtnc ipc call helper tab keys`.
FocusScope {
    id: root

    readonly property var tabs: [
        {
            id: "about",
            text: "About",
            icon: "info"
        },
        {
            id: "keys",
            text: "Keys",
            icon: "keyboard"
        },
        {
            id: "mouse",
            text: "Mouse",
            icon: "mouse"
        },
        {
            id: "cli",
            text: "CLI",
            icon: "terminal"
        },
        {
            id: "ipc",
            text: "IPC",
            icon: "settings_ethernet"
        },
        {
            id: "glossary",
            text: "Glossary",
            icon: "menu_book"
        }
    ]
    readonly property var components: ({
            about: aboutTab,
            keys: keysTab,
            mouse: mouseTab,
            cli: cliTab,
            ipc: ipcTab,
            glossary: glossaryTab
        })

    readonly property PanelColors c: PanelColors {
        look: K.Kit.appLook
    }

    // the tab picked (the group shows it at once) and the one shown (swapped at the fade's dip)
    property string tab: Store.appGet("helper", "tab", "about")
    property string shown: tab

    // big: the tabs show two columns at once (user)
    implicitWidth: 1080
    implicitHeight: 660

    // a tab's own opened() runs when it loads (the body's onLoaded: on creation and on a tab change);
    // here only for the tab already shown when the open Helper is opened again
    property bool created: false

    function opened(args) {
        const t = args?.tab ?? "";
        const before = tab;
        if (tabs.some(x => x.id === t))
            select(t);
        if (created && tab === before)
            Qt.callLater(() => body.item?.opened?.());
        created = true;
    }

    function select(id: string) {
        if (!tabs.some(x => x.id === id) || id === tab)
            return;
        tab = id;
        Store.appSet("helper", "tab", id);
        swap.restart();
    }

    function step(dir: int) {
        const i = tabs.findIndex(x => x.id === tab);
        select(tabs[(i + dir + tabs.length) % tabs.length].id);
    }

    Keys.onPressed: e => {
        if (!(e.modifiers & Qt.ControlModifier))
            return;
        if (e.key === Qt.Key_Tab)
            step(1);
        else if (e.key === Qt.Key_Backtab)
            step(-1);
        else if (e.key >= Qt.Key_1 && e.key <= Qt.Key_6)
            select(tabs[e.key - Qt.Key_1].id);
        else
            return;
        e.accepted = true;
    }

    // header ------------------------------------------------------------------
    Item {
        id: header
        width: parent.width
        height: 40

        K.StyledText {
            anchors.left: parent.left
            anchors.leftMargin: Tokens.spacing.s
            anchors.verticalCenter: parent.verticalCenter
            text: "Helper"
            font.family: K.Kit.family
            font.variableAxes: K.Kit.axes
            font.pixelSize: 17
            font.weight: Font.Bold
            color: root.c.strong
        }

        ActionGroup {
            anchors.right: parent.right
            anchors.verticalCenter: parent.verticalCenter
            width: 640
            look: K.Kit.appLook
            actions: root.tabs.map(t => ({
                        text: t.text,
                        icon: t.icon,
                        primary: t.id === root.tab,
                        run: () => root.select(t.id)
                    }))
        }
    }

    // body: the tab, fading through on a change -----------------------------
    Loader {
        id: body
        anchors.top: header.bottom
        anchors.topMargin: Tokens.spacing.m
        anchors.bottom: parent.bottom
        width: parent.width
        focus: true
        sourceComponent: root.components[root.shown] ?? aboutTab
        onLoaded: item.opened?.()
    }

    SequentialAnimation {
        id: swap
        K.Anim {
            target: body
            property: "opacity"
            to: 0
            type: K.Anim.FastEffects
        }
        ScriptAction {
            script: root.shown = root.tab
        }
        K.Anim {
            target: body
            property: "opacity"
            to: 1
            type: K.Anim.DefaultEffects
        }
    }

    Component {
        id: aboutTab
        Tabs.About {}
    }
    Component {
        id: keysTab
        Tabs.Keybinds {}
    }
    Component {
        id: mouseTab
        Tabs.Mouse {}
    }
    Component {
        id: cliTab
        Tabs.Cli {}
    }
    Component {
        id: ipcTab
        Tabs.Ipc {}
    }
    Component {
        id: glossaryTab
        Tabs.Glossary {}
    }
}
