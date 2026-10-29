import QtQuick
import Quickshell
import Quickshell.Io
import qs.core
import qs.services

// IPC: one target per component.  qs -c vtnc ipc call <target> <function> [args]
// `qs -c vtnc ipc show` lists everything.
//
//  island         expand · collapse · toggle · autohide <bool> · toggleAutohide
//  <app>          open · close · toggle        (launcher, dashboard, session, tools, wallpaper, settings)
//  launcher       + search <text>
//  settings       + page <name>
//  wallpaper      + set <path> · random
//  tools          + screenshot <region|screen> · record <region|screen|audio> · stop · pickColor · ocr
//  session        + lock · suspend · hibernate · logout · reboot · poweroff
//  lightmode      light · dark · toggle
//  transparency   on · off · toggle
//  scheme         next · previous · set <scheme-…>
//  launch         run <target>   (core/launch.js: vtnc:<app> · vtnc:settings/<page> · desktop:<entry id>)
//  notifications  clear · toggleDnd · dnd <true|false> · test <case>   (a sample notification; `test list`
//                 names the cases)
//  media          playPause · next · previous
//  preset         list · active · apply <name> · save · revert
//  shell          reload · resetState · status · perf <on|off|toggle>   (each island window's frame rate
//                 in `qs log -c vtnc`, island/PerfMeter.qml)
//  battery        warn <level>   (a battery warning's notification, to preview it: services/BatteryWarnings.qml)
Scope {
    id: root

    // open/close/toggle for an app of the apps system (apps/AppRegistry)
    // (the target name is the app id)
    component AppTarget: IpcHandler {
        function open(): void {
            Runtime.openApp(target, {});
        }
        function close(): void {
            if (Runtime.activeApp === target)
                Runtime.closeApp();
        }
        function toggle(): void {
            Runtime.toggleApp(target);
        }
    }

    // island ------------------------------------------------------------------
    IpcHandler {
        target: "island"

        // expanded state, pinned on the focused monitor (the hover still expands it too);
        // like the apps, these cancel a transient (OSD / notification) right away
        function expand(): void {
            Runtime.interruptTransients();
            Runtime.setPinned(Hypr.focusedScreen, true);
        }
        function collapse(): void {
            Runtime.interruptTransients();
            Runtime.setPinned(Hypr.focusedScreen, false);
        }
        function toggle(): void {
            Runtime.interruptTransients();
            Runtime.setPinned(Hypr.focusedScreen, !Runtime.isPinned(Hypr.focusedScreen));
        }

        // auto-hide on/off (the level and activation px are set in the settings app)
        function autohide(enabled: bool): void {
            Store.island.autohide = enabled;
        }
        function toggleAutohide(): void {
            Store.island.autohide = !Store.island.autohide;
        }
    }

    // apps --------------------------------------------------------------------
    AppTarget {
        target: "launcher"

        // open the launcher with the search field filled
        function search(text: string): void {
            Runtime.openApp("launcher", {
                query: text
            });
        }
    }

    AppTarget {
        target: "dashboard"
    }

    AppTarget {
        target: "clipboard"
    }

    AppTarget {
        target: "notes"
    }

    AppTarget {
        target: "dino"
    }

    AppTarget {
        target: "helper"

        // open on a tab: about, keys, mouse, cli, ipc, glossary
        function tab(name: string): void {
            Runtime.openApp("helper", {
                tab: name
            });
        }
    }

    AppTarget {
        target: "settings"

        // open the settings on a page: island, layout, appearance, system, about
        function page(name: string): void {
            Runtime.openApp("settings", {
                page: name
            });
        }
    }

    AppTarget {
        target: "wallpaper"

        // apply a wallpaper (awww) and regenerate the colors (matugen)
        function set(path: string): void {
            Wallpapers.apply(path);
        }
        // random wallpaper from the wallpapers folder, never the current one
        function random(): void {
            Wallpapers.applyRandom();
        }
    }

    AppTarget {
        target: "tools"

        // through Actions, like the Tools app: each runs once the island closed, so it isn't in the capture
        // (mode: region / screen; record also audio; anything else is the screen, as before)
        function screenshot(mode: string): void {
            Actions.runTool(mode === "region" ? "shot-region" : "shot-screen");
        }
        // starts a recording, or stops the current one
        function record(mode: string): void {
            if (ScreenTools.recording)
                Actions.runTool("stop");
            else
                Actions.runTool(mode === "region" || mode === "audio" ? "rec-" + mode : "rec-screen");
        }
        function stop(): void {
            Actions.runTool("stop");
        }
        function pickColor(): void {
            Actions.runTool("picker");
        }
        function ocr(): void {
            Actions.runTool("ocr");
        }
    }

    AppTarget {
        target: "session"

        function lock(): void {
            Actions.runSession("lock");
        }
        function suspend(): void {
            Actions.runSession("suspend");
        }
        function hibernate(): void {
            Actions.runSession("hibernate");
        }
        function logout(): void {
            Actions.runSession("logout");
        }
        function reboot(): void {
            Actions.runSession("reboot");
        }
        function poweroff(): void {
            Actions.runSession("poweroff");
        }
    }

    // transparent surfaces (Appearance → Transparency) ----------------------------------
    IpcHandler {
        target: "transparency"

        function on(): void {
            Store.theme.transparency.enabled = true;
        }
        function off(): void {
            Store.theme.transparency.enabled = false;
        }
        function toggle(): void {
            Store.theme.transparency.enabled = !Store.theme.transparency.enabled;
        }
    }

    // matugen's scheme (the colours regenerate) ------------------------------------------
    IpcHandler {
        target: "scheme"

        function next(): void {
            Wallpapers.cycleScheme(1);
        }
        function previous(): void {
            Wallpapers.cycleScheme(-1);
        }
        function set(name: string): void {
            if (Wallpapers.schemes.includes(name))
                Store.theme.scheme = name;
        }
    }

    // open a launch target (core/Launch.qml); the future CLI's `vtnc open <target>` ------
    IpcHandler {
        target: "launch"

        function run(target: string): void {
            Launch.run(target);
        }
    }

    // light / dark mode (main background white/black, matugen colors regenerated) -----
    IpcHandler {
        target: "lightmode"

        function light(): void {
            Store.theme.light = true;
        }
        function dark(): void {
            Store.theme.light = false;
        }
        function toggle(): void {
            Store.theme.light = !Store.theme.light;
        }
    }

    // notifications -----------------------------------------------------------
    IpcHandler {
        target: "notifications"

        // the Notifications app (apps/notifications), as an AppTarget
        function open(): void {
            Runtime.openApp("notifications", {});
        }
        function close(): void {
            if (Runtime.activeApp === "notifications")
                Runtime.closeApp();
        }
        function toggle(): void {
            Runtime.toggleApp("notifications");
        }
        function clear(): void {
            Notifications.discardAllNotifications();
        }
        function toggleDnd(): void {
            Notifications.silent = !Notifications.silent;
        }
        function dnd(enabled: bool): void {
            Notifications.silent = enabled;
        }
        // Sample notifications to try the popup by hand (notify-send, as an app would).
        function test(name: string): string {
            const cases = root.notificationTests;
            if (name === "several") {
                for (const n of ["simple", "actions", "long"])
                    root.sendTest(cases[n]);
                return "sent: simple, actions, long";
            }
            if (!cases[name])
                return "cases: " + Object.keys(cases).concat(["several"]).join(", ");
            root.sendTest(cases[name]);
            return "sent: " + name;
        }
    }
    // notifications.test's cases: notify-send's arguments (no "-a": the app name is `app`)
    readonly property var notificationTests: ({
            simple: {
                app: "Test",
                args: ["Simple", "Just a summary and a short body"]
            },
            actions: {
                app: "Mail",
                args: ["-A", "default=Open", "-A", "reply=Reply", "-A", "read=Mark as read", "-A", "delete=Delete", "New mail from Alex", "Three buttons (a fourth is left out) and a click on the card opens it"]
            },
            one: {
                app: "Discord",
                args: ["-A", "default=", "-A", "settings=Settings", "Discord", "One button; the unlabelled default action is the card's click"]
            },
            long: {
                app: "Test",
                args: ["A rather long summary that won't fit on one line", "A long body that wraps onto several lines when the card expands. It keeps going so the third line ends in an ellipsis instead of growing the card any further than that."]
            },
            critical: {
                app: "Test",
                args: ["-u", "critical", "Critical", "In the error color; it stays until you dismiss it"]
            },
            timeout: {
                app: "Test",
                args: ["-t", "2000", "Two seconds", "The app asked for a 2 s timeout"]
            },
            never: {
                app: "Test",
                args: ["-t", "0", "No timeout", "The app asked for it never to expire"]
            },
            picture: {
                app: "Music",
                args: ["-i", "/usr/share/pixmaps/archlinux-logo.png", "With a picture", "An image hint replaces the lead"]
            },
            symbol: {
                app: "Battery",
                args: ["-n", "material:battery_alert", "Material symbol", "The shell's own icons: material:<name>"]
            }
        })
    function sendTest(c) {
        // (with actions notify-send waits for one, as the app that gets it)
        Quickshell.execDetached(["notify-send", "-a", c.app].concat(c.args));
    }

    // media -------------------------------------------------------------------
    IpcHandler {
        target: "media"

        function playPause(): void {
            MprisController.togglePlaying();
        }
        function next(): void {
            MprisController.next();
        }
        function previous(): void {
            MprisController.previous();
        }
    }

    // presets -----------------------------------------------------------------
    IpcHandler {
        target: "preset"

        function list(): string {
            return Presets.list.map(p => p.name).join("\n");
        }
        function active(): string {
            return (Presets.active || "(none)") + (Presets.modified ? " (modified: " + Presets.modifiedParts.join(", ") + ")" : "");
        }
        function apply(name: string): string {
            return Presets.apply(name) ? "applied " + name : "no preset " + name;
        }
        function save(): string {
            return Presets.save() ? "saved " + Presets.active : "nothing to save (no active preset, or Default)";
        }
        function revert(): void {
            Presets.revert("");
        }
    }

    // shell -------------------------------------------------------------------
    IpcHandler {
        target: "shell"

        function reload(): void {
            Quickshell.reload(false);
        }
        function resetState(): void {
            Store.resetToDefaults();
        }
        // debug: a placeholder transient on the focused monitor for `ms` (0 = 2000)
        function testTransient(kind: string, ms: int): void {
            Runtime.showTransient(Hypr.focusedScreen, kind || "debug", {
                text: kind || "debug"
            }, ms > 0 ? ms : 2000);
        }
        function perf(state: string): string {
            Runtime.perf = state === "toggle" ? !Runtime.perf : state === "on";
            return "perf " + (Runtime.perf ? "on" : "off");
        }
        function status(): string {
            return JSON.stringify({
                ready: Store.ready,
                activeApp: Runtime.activeApp,
                activeScreen: Runtime.activeScreen,
                transients: Runtime.transients,
                pinnedExpanded: Runtime.pinnedExpanded,
                focusedScreen: Hypr.focusedScreen,
                notifications: Notifications.list.length,
                silent: Notifications.silent,
                media: MprisController.activePlayer?.trackTitle ?? null,
                recording: ScreenTools.recording
            });
        }
    }
}
