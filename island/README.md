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
