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
//  PRÉ-REQUISITO: o `awww-daemon` precisa estar rodando (autostart do
//  Hyprland). Sem ele o `awww img` falha em silêncio — não subimos o
//  daemon daqui de propósito: gerenciar processo de sessão é do
//  compositor, não da shell.
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

    Component.onCompleted: refresh()
    onDirChanged: refresh()

    // ── APLICAR ──
    Process { id: setter }

    function apply(file) {
        const p = path(file)
        setter.command = ["awww", "img", p,
            "--transition-type", Config.wallpaperTransition,
            "--transition-duration", String(Config.wallpaperTransitionMs / 1000),
            "--transition-fps", "60"]
        setter.running = true
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
    // restart do awww-daemon deixa a tela vazia até você trocar na mão
    Connections {
        target: Persist
        function onLoadedChanged() {
            if (Persist.loaded && root.current !== "")
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
