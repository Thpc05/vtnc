# core

A base que não conhece ninguém acima dela: nenhum arquivo aqui importa
`island/`, `page/` ou `widgets/`.

- `grid.mjs` — matemática pura (célula base × fator do monitor, âncora +
  deslocamento → geometria em pixels). Testada em node (`tests/unit/`).
- `config-shape.mjs` — defaults e lookups sobre o documento de config. Pura,
  sem I/O, também testada em node.
- `Paths.qml` — onde o config/estado do vtnc vivem (`~/.config/vtnc`,
  `~/.local/state/vtnc`), com override por `VTNC_CONFIG_DIR`/`VTNC_STATE_DIR`
  para o ambiente de teste descartável.
- `Config.qml` — lê `config.json` com `FileView`/`watchChanges`, para captar
  um `set` da CLI sem round-trip de IPC.
- `IslandState.qml` — só em memória: qual page um `call` pôs por cima da
  idle de cada island. Nunca grava em disco; é isso que faz `call` ser
  momentâneo e `set` permanente.

Os tipos QML daqui são expostos via `qmldir` (singletons), não por import de
arquivo único — ver nota em `../AGENTS.md`-adjacente: imports de arquivo
único com `as` não funcionam de forma confiável neste Quickshell.
