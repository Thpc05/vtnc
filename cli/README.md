# cli

`vtnc <namespace> <nome> <verbo> [args...]` — a gramática da decisão 4b.2.
Para verbos sem alvo (`list`), a forma é `vtnc <namespace> <verbo> [args...]`.

- `set` escreve direto em `config.json` (decisão 4b.4), sem precisar da shell
  rodando — `core/Config.qml` capta a mudança ao vivo via `FileView`.
- `call`, `get` e `list` falam com a shell em execução pela IPC nativa do
  Quickshell (`qs ipc call`), registrada em `shell.qml` via `IpcHandler`.
  Por isso precisam da shell de pé.

`vtnc` sem argumentos inicia a shell (`qs -p <esta pasta>`). A pasta-mãe do
`cli/` dobra como a raiz da config do Quickshell, então a CLI nunca precisa
ser avisada se está falando com `vtnc-dev` ou `vtnc`.
