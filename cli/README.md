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

Os sete namespaces de topo da decisão 4b.3 todos aparecem em `vtnc help`;
hoje só `island`, `page` e `service` têm verbo — os outros (`widget`,
`monitor`, `preset`, `theme`) existem só para a lista não ficar incompleta
depois.

`set` em island valida antes de escrever: chave desconhecida ou valor que
aponta para algo que não existe (uma page inexistente, uma camada que não é
`background`/`bottom`/`top`/`overlay`) é recusado com erro e `config.json`
fica como estava — nunca escreve um config que a própria shell não
conseguiria ler de volta (o princípio por trás da decisão 5.4, aplicada
aqui ao `set`, não só ao Settings).

As chaves aceitas por `set` em island são uma lista fechada (decisão
0.502i): `page`, `layer`, e — desde a 0.503, para a página Islands da
Settings — `anchor`, `offset` e `size`. As três últimas são objetos, não
escalares, então chegam como um único argumento JSON
(`set anchor '{"top":true,"left":true}'`); `core/config-shape.mjs` faz o
parse e valida o formato antes de qualquer coisa chegar perto do arquivo.
