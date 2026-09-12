pragma Singleton
import QtQuick
import Quickshell

// ═══════════════════════════════════════════
//  PATHS — Onde a shell guarda o que ela escreve.
//
//  Um lugar só. Antes o caminho absoluto estava copiado dentro do
//  Persist, e cada arquivo novo de estado o copiaria de novo.
//
//  ARMADILHA do FileView: o path tem que ser ABSOLUTO. "~" não
//  expande — vira um diretório literal chamado "~" ao lado do cwd, e
//  o estado some sem erro nenhum. Por isso montamos a partir de $HOME.
//
//  NÃO usamos Quickshell.statePath(): aquilo aponta pro diretório de
//  estado do próprio Quickshell (por shell), e a decisão aqui foi
//  guardar em ~/.local/state/vtnc.
// ═══════════════════════════════════════════
QtObject {
    // Fallback literal: se $HOME não vier, é melhor um caminho certo
    // pra esta máquina do que "undefined/.local/state/..."
    readonly property string home: Quickshell.env("HOME") || "/home/thpc"

    readonly property string stateDir: home + "/.local/state/vtnc"

    // ── OS ARQUIVOS ──
    // Separados por ASSUNTO, não num blob só: cada singleton de token
    // é dono do seu, e o config app edita um arquivo por painel.
    //
    // A divisão que importa: `state` é o que a SHELL escreve sozinha
    // (e você nunca edita à mão nem versiona); o resto é CONFIGURAÇÃO,
    // que você pode copiar pra outra máquina.
    readonly property string theme: stateDir + "/theme.json"
    readonly property string motion: stateDir + "/motion.json"
    readonly property string island: stateDir + "/island.json"
    readonly property string config: stateDir + "/config.json"
    readonly property string state: stateDir + "/state.json"
}
