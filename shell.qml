import Quickshell
import Quickshell.Io
import Quickshell.Hyprland
import "./core/config-shape.mjs" as ConfigShape
import "./core/widget-registry.mjs" as Registry
import "./core/style-schema.mjs" as StyleSchema
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

    // 0.507: writes ~/.config/hypr/vtnc/keybinds.lua and reloads Hyprland
    // whenever config.hyprland changes and consent has been given.
    HyprlandSync {
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
                // 0.508: o que a shell de fato enxerga da page que esta
                // island veste agora. `widgetCount` torna a decisao 6.1
                // observavel - duas islands na mesma page mudam juntas, e
                // isso se le daqui sem olhar pixel; `empty` e o estado da
                // 14.3, a page que nao existe mais.
                widgetCount: ((Config.page(calledPage !== "" ? calledPage : (island.page ?? "")) ?? {}).widgets ?? []).length,
                empty: !Config.page(calledPage !== "" ? calledPage : (island.page ?? "")),
                // 0.509: o type e o style que cada widget esta vestindo de
                // fato, resolvidos pelo registro e nao copiados da config -
                // uma instancia sem `style` veste o padrao do type, e e o
                // padrao que aparece aqui. E o que torna a troca de style
                // (3.3) observavel na shell viva, e nao so no config.json.
                widgets: (((Config.page(calledPage !== "" ? calledPage : (island.page ?? "")) ?? {}).widgets) ?? []).map((widget) => {
                    const style = widget.style ?? Registry.defaultStyleOf(widget.type);
                    return {
                        type: widget.type,
                        style: style,
                        // 0.510: os valores que a shell RESOLVEU para o
                        // style — o guardado quando serve, o default
                        // declarado quando nao. Os papeis de cor saem pelo
                        // nome, e nao ja virados cor: a tabela de cores e
                        // provisoria (3.4c) e um teste nao deve depender
                        // dela. O que se quer observar aqui e a resolucao,
                        // nao a pintura.
                        options: StyleSchema.resolveOptions(
                            Registry.optionSchemaOf(widget.type, style),
                            StyleSchema.storedOptionsFor(widget, style))
                    };
                }),
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

    // Global hyprland config (0.507, decision 10.3b): no target name, same
    // nameless grammar as "autohide" above. `set` writes config.json
    // directly and never comes through here; `generate` is a local
    // write+reload (cli/vtnc), not IPC, so it doesn't appear here either.
    IpcHandler {
        target: "hyprland"

        function list(): string {
            return JSON.stringify(Config.data.hyprland ?? ConfigShape.defaultHyprland());
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
