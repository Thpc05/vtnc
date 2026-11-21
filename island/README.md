# island

A superfície de layer-shell: âncora + deslocamento, medida em células, com
camada e uma page vestida por vez.

- `Island.qml` — o `PanelWindow`. Lê a geometria de `core/grid.mjs`, a page
  atual de `core/Config.qml` + `core/IslandState.qml` (idle vs. call).
- `IslandManager.qml` — cria uma `Island` por par (tela, island do
  config.json). Por padrão uma island aparece em todas as telas (decisão
  1c.4); escolher um subconjunto é página de Monitors, fora da 0.51.

Uma island pode ser espelhada em várias telas; todas leem o mesmo estado de
`call` em `IslandState` — um `call` não é por monitor.

## Zona exclusiva (0.504)

A reserva de espaço nunca vem do `exclusionMode` automático do `PanelWindow`
— ele só reserva quando a superfície cobre a borda inteira, e uma island
ancorada num canto sem cobrir a borda não reserva nada (risco já aceito no
grafo, medido na tela real do Theo no 0.502 e reconfirmado aqui no Hyprland
aninhado). `Island.qml` força `WlrLayershell.exclusionMode` para `Normal` e
calcula `exclusiveZone` ele mesmo, via `Grid.exclusiveZone` em
`core/grid.mjs`.

A conta, medida empiricamente contra `hyprctl monitors -j` (não deduzida da
spec do protocolo, que não documenta o caso de âncoras em canto):

- Island sem page idle (`island.page` vazio) nunca reserva — `Grid.
  exclusiveZone` já corta aqui.
- Senão, `Grid.primaryExclusiveEdge(anchor)` decide se há **uma** borda
  reservável: uma borda sozinha reserva; essa borda mais as duas
  perpendiculares (uma faixa cobrindo a tela inteira, como `top`+`left`+
  `right` numa barra) também reserva, só na borda principal; qualquer outra
  combinação — um canto puro (`top`+`left`, sem `right`), ou as duas bordas
  opostas sem as perpendiculares (`top`+`bottom`) — é ambígua para o
  Hyprland e não reserva nada, decisão 2d.3 ("só reserva no lado em que está
  ancorada").
- O valor reservado é o tamanho da island na dimensão perpendicular à borda
  (altura para `top`/`bottom`, largura para `left`/`right`) mais o gap
  (decisão 1d.5), os dois em pixels. O `offset` nunca entra nessa conta — a
  reserva é o retângulo mais o gap, não a distância até a borda.
- A reserva usa sempre `island.size`/`island.gap` do config — nunca o
  tamanho real da page que está na tela — então um `call` para uma page
  maior passa por cima das janelas sem tocar na zona (decisão 2d.4); hoje
  isso já é automático, porque `island.size` nunca muda sozinho com o
  `call`.

O gap é um número só por island, em células, nunca quatro lados (decisão
2d.3) — `vtnc island <nome> set gap <N>`, documentado em `cli/README.md` e
editável ao vivo pela página Islands da Settings.

## Autohide (0.505)

Escondida, a island some de vez — nem faixa fina, nem sombra (decisão
11.2e) — e é exatamente por isso que a zona exclusiva some com ela
(decisão 2d.2): `WlrLayershell.exclusiveZone` vira 0 enquanto estiver
escondida, e as janelas do Hyprland crescem para o espaço liberado.

**Os dois atributos da island** (decisão 11.2c): `autohide` (bool) e
`autohideMode` (`always`/`window`/`fullscreen`). Os dois são sobrescritas
opcionais — ausentes, a island usa `config.autohide.enabled`/`.mode`
globais (`core/config-shape.mjs`'s `resolveAutohide`). `window` e
`fullscreen` leem o estado de verdade do Hyprland pelo módulo
`Quickshell.Hyprland` (reativo, nunca por polling — ao contrário da posição
do mouse, abaixo): existe alguma janela na workspace focada do monitor da
island, ou alguma delas está em tela cheia.

**Qual borda, e qual animação** (decisões 11.2b/11.2e): `Grid.nearestBorder`
escolhe, entre as bordas ancoradas da island, a que ela está mais perto (o
`offset` nessa direção, em células) — um canto usa a menor das suas duas;
sem âncora nenhuma, não há borda e a distância é infinita. `Grid.
autohideAnimation` compara essa distância contra `config.autohide.distance`
(global, decisão 12.4, nunca por island): mais perto que a distância vira
`slide` (desliza para fora, na direção da borda), mais longe vira `shrink`
(encolhe). Nos dois extremos da distância — 0 ou um valor maior que
qualquer offset real — a comparação sozinha já faz todo mundo cair na
mesma animação, sem caso especial.

**Como volta** (decisão 11.2d): o mouse chegando na borda mais próxima
(sempre essa borda, mesmo para uma island que mora longe dela), ou um
`call` de outra page que não a idle. Como não existe ainda um verbo para
"terminar o call" (`core/IslandState.clearCall` existe mas nada o chama —
isso é trabalho do ciclo de vida completo, decisão 1e.2/1e.4, fora da
0.505), terminar o call aqui significa chamar a própria page idle de volta
— reaproveita o mecanismo que já existe, em vez de inventar um novo.

**A área de gatilho não existe como superfície** — o wlr-layer-shell não
tem "recebe hover mas deixa passar o clique": uma região de input que
recebe `pointer-enter` recebe o clique embaixo dela também. Em vez de criar
uma superfície (que reservaria espaço e roubaria clique de quem está atrás),
`core/HoverCursor.qml` pergunta a posição do mouse a `hyprctl cursorpos`
num Timer de 100ms — a única leitura de estado daqui que não é reativa via
`Quickshell.Hyprland`, porque o Hyprland não emite esse evento no socket.
`Grid.cursorNearBorder`/`Grid.cursorOverRect` comparam essa posição contra
a faixa na borda (a mesma distância global, em px) e contra o retângulo da
própria island (para não fechar no instante em que o mouse sai da faixa
para alcançar o conteúdo que acabou de revelar — detalhe que o grafo não
fixa, decisão de implementação).

**A reserva não some na mesma hora que o clique** — esconder desliga o
input (`mask` vazio) assim que a decisão é tomada, mas só libera a zona
exclusiva depois que a animação teria tempo de terminar (`fade`/
`slideSpeed`, o maior dos dois): senão uma janela cresceria para um espaço
que a island ainda está visualmente atravessando. Revelar é o contrário —
a reserva volta na hora, não espera a animação, para a janela já abrir
espaço assim que a island reaparece.

**`shrinkSize`** é descrito no grafo como "o tamanho ao longo da animação,
não um estado final visível" — nesta implementação isso virou o quanto a
curva de easing (`Easing.InBack`) ultrapassa o alvo a caminho de escala 0,
não um tamanho de repouso (que violaria a decisão 11.2e). É a interpretação
mais insegura deste passo — o grafo não fixa o que esse número
literalmente controla, e não há critério de aceite que meça isso
diretamente.

`fade`, `slideSpeed` e `distance` moram em `config.autohide` (global);
`shrinkSize` também, mas sem verbo de CLI — ver `cli/README.md`.
