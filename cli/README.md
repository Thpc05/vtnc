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

Desde a 0.504, `gap` entrou na mesma lista: um número inteiro só, nunca
quatro lados (decisão 2d.3) — `vtnc island bar set gap 2`. É o gap exclusivo
que soma ao retângulo da island na hora de pedir a reserva de espaço ao
Hyprland; ver `island/README.md` para a conta.

Desde a 0.505, `autohide` (booleano) e `autohideMode` (`always`/`window`/
`fullscreen`) também entraram na lista — `vtnc island bar set autohide true`,
`vtnc island bar set autohideMode window`. Os dois são sobrescritas
opcionais: ausentes, a island usa o valor global.

Desde a 0.506, o gatilho mora na page, não na island (decisão 1b.5):
`vtnc island <nome> call` não existe mais — a CLI recusa com uma mensagem
dizendo para onde foi, em vez de falhar na IPC sem explicação. A forma
certa é `vtnc page <nome> call <island>`, que empilha `<nome>` por cima da
idle do `<island>` (até 5 de fundo, decisão 1e.2). Desempilhar é por
island, não por page — `vtnc island <nome> end` tira um nível (volta à
anterior, ou à idle quando a pilha esvazia); é o mesmo verbo que Esc,
clique-fora, o × do popup e o tempo do popup chamam por baixo
(`core/IslandState.end`, ver `island/README.md`).

O namespace `autohide` (0.505) é global, sem nome de alvo — a mesma gramática
de `page list`/`service list`: `vtnc autohide set <chave> <valor>` aceita
`enabled`, `mode` e `distance` (decisão 12.4: a distância de gatilho é
global, nunca por island — é ela que decide qual das duas animações do
autohide uma island recebe, ver `island/README.md`); `vtnc autohide list`
devolve o objeto global inteiro. `fade`, `slideSpeed` e `shrinkSize` também
moram em `config.autohide`, mas não ganharam verbo aqui nem controle na
Settings nesta etapa — só o que o passo pediu explicitamente
(`autohide`/`autohideMode`/distância) entrou na CLI; os três ficam editáveis
só à mão no `config.json` por enquanto.
