pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Io
import "../Config"

// ═══════════════════════════════════════════
//  WALLPAPER SERVICE — Quem é o papel de parede, e o que ele tinge.
//
//  Duas responsabilidades que andam juntas de propósito: trocar a
//  imagem (awww) e derivar a paleta dela (matugen). Separar em dois
//  services faria a cor ficar para trás da imagem — é a MESMA ação.
//
//  awww é o antigo swww: o autor renomeou e o pacote declara
//  `Provides/Replaces: swww`, por isso `pacman -S swww` instala awww.
//  A CLI é a mesma.
//
//  O DAEMON: awww é cliente/daemon. O `awww-daemon` é quem desenha na
//  layer de background; `awww img` só manda a ordem pra ele. Sem
//  daemon, o comando falha na hora — mesmo papel que o hyprpaper tinha.
//
//  O lugar certo dele é o autostart do compositor:
//      exec-once = awww-daemon
//
//  Mas a shell NÃO pode depender disso em silêncio. A primeira versão
//  aqui só documentava o pré-requisito, com o argumento de que
//  processo de sessão é do compositor — e o resultado foi trocar o
//  papel de parede e nada acontecer, sem uma palavra de explicação.
//  O argumento não estava errado; o silêncio estava. Então: sondamos
//  o daemon, subimos se faltar, e guardamos o erro em `lastError` pra
//  quem mostra poder mostrar.
// ═══════════════════════════════════════════
Singleton {
    id: root

    readonly property string dir: Config.wallpaperPath
    // Nomes de arquivo (não caminhos): o diretório é o mesmo pra todos
    property var list: []
    // Caminho completo do atual (sobrevive a restart)
    readonly property string current: Persist.state.wallpaper ?? ""

    function path(file) {
        return dir + "/" + file
    }

    // ── LISTAGEM ──
    Process {
        id: lister
        stdout: StdioCollector {
            onStreamFinished: root.list =
                text.trim().split("\n").filter(f => f !== "")
        }
    }

    function refresh() {
        lister.command = ["sh", "-c",
            `ls -1 '${dir}' | grep -iE '\\.(jpe?g|png|webp)$'`]
        lister.running = true
    }

    Component.onCompleted: {
        refresh()
        ensureDaemon()
    }
    onDirChanged: refresh()

    // ── O DAEMON ──
    // `awww query` sai 0 com daemon no ar e 1 sem (verificado). É a
    // sonda: sem ela subiríamos um segundo daemon por cima do que o
    // autostart do compositor já pôs
    property bool daemonUp: false
    // Último problema, pra UI não ficar cega
    property string lastError: ""

    Process {
        id: sonda
        command: ["awww", "query"]
        onExited: code => {
            root.daemonUp = (code === 0)
            if (code !== 0)
                daemon.running = true
        }
    }

    Process {
        id: daemon
        command: ["awww-daemon"]
        onStarted: {
            root.daemonUp = true
            root.lastError = ""
        }
        onExited: code => {
            root.daemonUp = false
            // 127 = binário ausente. Vale distinguir: "não instalado"
            // e "morreu" pedem coisas diferentes de quem lê
            root.lastError = code === 127
                ? "awww não encontrado — instale o pacote awww"
                : "awww-daemon caiu (código " + code + ")"
        }
    }

    function ensureDaemon() {
        sonda.running = true
    }

    // ── APLICAR ──
    Process {
        id: setter
        onExited: code => {
            if (code === 0) {
                root.lastError = ""
                return
            }
            // Falhou: quase sempre é o daemon fora do ar. Sobe e tenta
            // UMA vez — o guarda evita ficar num laço se o problema for
            // outro (arquivo inexistente, formato não suportado)
            root.lastError = "awww img falhou (código " + code + ")"
            if (!root._retentou) {
                root._retentou = true
                root.ensureDaemon()
                reaplicar.restart()
            }
        }
    }
    property bool _retentou: false
    property string _pendente: ""

    Timer {
        id: reaplicar
        interval: 400 // respiro pro daemon subir e pegar a tela
        onTriggered: if (root._pendente !== "") root._envia(root._pendente)
    }

    function _envia(p) {
        setter.command = ["awww", "img", p,
            "--transition-type", Config.wallpaperTransition,
            "--transition-duration", String(Config.wallpaperTransitionMs / 1000),
            "--transition-fps", "60"]
        setter.running = true
    }

    function apply(file) {
        const p = path(file)
        _retentou = false
        _pendente = p
        _envia(p)
        Persist.state.wallpaper = p
        if (Config.wallpaperTintsShell)
            generate(p)
    }

    function random() {
        if (list.length === 0)
            return
        // Evita repetir o que já está na tela quando há alternativa —
        // "aleatório" que sorteia o mesmo parece que não funcionou
        let escolha = list[Math.floor(Math.random() * list.length)]
        if (list.length > 1) {
            let guarda = 8
            while (path(escolha) === current && guarda-- > 0)
                escolha = list[Math.floor(Math.random() * list.length)]
        }
        apply(escolha)
    }

    // Restaura o papel de parede salvo ao subir a shell. Sem isto, um
    // restart do awww-daemon deixa a tela vazia até você trocar na mão.
    //
    // Espera as DUAS condições: o estado carregado (pra saber QUAL) e o
    // daemon no ar (pra ter a quem mandar). A primeira versão disparava
    // só no Persist.loaded e falhava calada em todo boot, porque o
    // daemon ainda estava subindo — o mesmo erro do `apply`, num lugar
    // onde ninguém olharia
    readonly property bool _podeRestaurar:
        Persist.loaded && daemonUp && current !== ""
    property bool _restaurado: false

    on_PodeRestaurarChanged: {
        if (_podeRestaurar && !_restaurado) {
            _restaurado = true
            restore.running = true
        }
    }

    Process {
        id: restore
        command: ["awww", "img", root.current, "--transition-type", "none"]
    }

    // ═══════════════════════════════════════════
    //  MATUGEN — a paleta sai da imagem
    //
    //  `--dry-run` é essencial: sem ele o matugen escreve os templates
    //  configurados em ~/.config/matugen e recarrega apps. Nós só
    //  queremos o JSON; quem decide o que fazer com a cor é a shell.
    //
    //  `--prefer` também não é opcional: quando a imagem tem mais de
    //  uma cor candidata e não há terminal — o nosso caso, rodando da
    //  shell — o matugen ABORTA pedindo interação. Descobri isso na
    //  mão: sem a flag ele falha em "Multiple source colors found".
    // ═══════════════════════════════════════════
    Process {
        id: matugen
        stdout: StdioCollector {
            onStreamFinished: root._applyPalette(text)
        }
    }

    function generate(p) {
        matugen.command = ["matugen", "--dry-run", "-q", "-j", "hex",
            "--prefer", Config.matugenPrefer,
            "-t", Config.matugenScheme,
            "image", p]
        matugen.running = true
    }

    function _applyPalette(json) {
        let c
        try {
            c = JSON.parse(json).colors
        } catch (e) {
            return // matugen falhou: fica a paleta atual, não o preto
        }
        if (!c)
            return
        const cor = k => c[k] && c[k].dark ? c[k].dark.color : ""
        const set = (campo, chave) => {
            const v = cor(chave)
            if (v !== "")
                Theme.data[campo] = v
        }

        // O MAPA. O que fica de FORA importa tanto quanto o que entra:
        //  · `bg` é fixo #000000 — decisão de projeto, o preto não
        //    negocia (e é o que segura a coerência da ilha);
        //  · `hoverLayer` é branco com ALFA, uma camada que soma sobre
        //    o que estiver embaixo. Trocar por uma cor opaca do
        //    matugen quebraria a mira em todo lugar da shell.
        set("accent", "primary")
        set("textPrimary", "on_surface")
        set("textSecondary", "on_surface_variant")
        set("textMuted", "outline")
        set("danger", "error")
        set("card", "surface_container")
        set("surface", "surface_container_high")
    }
}
