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
