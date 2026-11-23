import Quickshell
import Quickshell.Io
import Quickshell.Hyprland
import "./core/config-shape.mjs" as ConfigShape
import "./core"
import "./island"
import "./services"
import "./settings"

// Entry point. The CLI's `set` writes config.json directly (decision 4b.4),
// picked up live by Config's FileView; `call`, `get` and `list` talk to this
// running process over Quickshell's own IPC (decision 1b.1 — the
// infrastructure exists for the CLI to reach into it).
ShellRoot {
    IslandManager {
        configRef: Config
    }

    // A plain window, not a layer-shell surface (decision 1d.6) — opens
    // with the shell for now; a toggle/keybind to show it on demand is a
    // later step's job, out of 0.503's scope.
    Settings {}

    // The island declares no trigger (decision 1b.5) — `call` lives on
    // `page` below. `end` is the one lifecycle verb that does belong here:
    // unstacking doesn't need to name a page, just which island to pop
    // (decision 1e.2).
    IpcHandler {
        target: "island"

        function end(name: string) {
            IslandState.end(name);
        }

        function get(name: string): string {
            const island = Config.island(name);
            if (!island) return JSON.stringify({ error: "no such island: " + name });
            const calledPage = IslandState.calledPage(name);
            return JSON.stringify({
                name: island.name,
                anchor: island.anchor ?? {},
                offset: island.offset ?? { x: 0, y: 0 },
                size: island.size ?? { w: 1, h: 1 },
                gap: island.gap ?? 0,
                layer: island.layer ?? "top",
                idlePage: island.page ?? "",
                calledPage: calledPage,
                page: calledPage !== "" ? calledPage : (island.page ?? ""),
                autohide: ConfigShape.resolveAutohide(Config.data, island),
                // Which page each mirror actually draws (0.506 criterion
                // 3) — a called page reaches only the focused monitor's
                // mirror; the rest report their own idle page, read back
                // without comparing a single pixel.
                mirrors: IslandState.mirrorPagesFor(name),
            });
        }

        function list(): string {
            const islands = Config.data.islands ?? [];
            return JSON.stringify(islands.map((island) => ({
                name: island.name,
                anchor: island.anchor ?? {},
                offset: island.offset ?? { x: 0, y: 0 },
                size: island.size ?? { w: 1, h: 1 },
                gap: island.gap ?? 0,
                layer: island.layer ?? "top",
                page: IslandState.calledPage(island.name) || (island.page ?? ""),
                autohide: ConfigShape.resolveAutohide(Config.data, island),
                mirrors: IslandState.mirrorPagesFor(island.name),
            })));
        }
    }

    // Global autohide config (0.505, decision 11.2c/12.4): no target name,
    // so it only answers `list`, the same grammar `page list` uses for a
    // nameless read. `set` writes config.json directly (decision 4b.4) and
    // never comes through here.
    IpcHandler {
        target: "autohide"

        function list(): string {
            return JSON.stringify(Config.data.autohide ?? ConfigShape.defaultAutohide());
        }
    }

    IpcHandler {
        target: "page"

        // The trigger lives here, not on `island` (decision 1b.5):
        // `vtnc page <name> call <island>` pushes this page onto that
        // island's stack. Whatever's focused right now is captured once,
        // here — decision 1e.3b: the called page sticks to that monitor
        // until it closes, it doesn't follow focus afterwards.
        function call(name: string, island: string) {
            IslandState.call(island, name, Hyprland.focusedMonitor ? Hyprland.focusedMonitor.name : "");
        }

        function list(): string {
            const pages = Config.data.pages ?? {};
            return JSON.stringify(Object.keys(pages).map((name) => ({
                name: name,
                widgetCount: (pages[name].widgets ?? []).length,
            })));
        }

        function get(name: string): string {
            const page = Config.page(name);
            if (!page) return JSON.stringify({ error: "no such page: " + name });
            return JSON.stringify(page);
        }
    }

    IpcHandler {
        target: "service"

        function list(): string {
            return JSON.stringify(ServiceRegistry.list());
        }

        function get(name: string): string {
            return JSON.stringify({
                name: name,
                running: ServiceRegistry.isRunning(name),
                holders: ServiceRegistry.holders(name),
            });
        }
    }
}
