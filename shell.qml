import Quickshell
import Quickshell.Io
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

    IpcHandler {
        target: "island"

        function call(name: string, page: string) {
            IslandState.call(name, page);
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
                layer: island.layer ?? "top",
                idlePage: island.page ?? "",
                calledPage: calledPage,
                page: calledPage !== "" ? calledPage : (island.page ?? ""),
            });
        }

        function list(): string {
            const islands = Config.data.islands ?? [];
            return JSON.stringify(islands.map((island) => ({
                name: island.name,
                anchor: island.anchor ?? {},
                offset: island.offset ?? { x: 0, y: 0 },
                size: island.size ?? { w: 1, h: 1 },
                layer: island.layer ?? "top",
                page: IslandState.calledPage(island.name) || (island.page ?? ""),
            })));
        }
    }

    IpcHandler {
        target: "page"

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
