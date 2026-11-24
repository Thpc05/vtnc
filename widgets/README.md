# widgets

Cada pasta aqui é um *type*: a função do widget, nomeando os services que
usa (decisão 15.2b). Um type nunca importa outro widget.

```
widgets/<type>/
    meta.js              descreve o type (decisão 19.1)
    <Type>.qml            a implementação do type
    styles/<style>/
        meta.js           descreve o style — pertence a um único type (3.5)
        <Style>.qml
```

- `square` (0.501) — um quadrado burro com texto, para provar o tripé
  type/style/page com o mínimo de código possível (decisão 16.4). Sem
  services — não precisa de nenhum.
- `clock` (0.502) — consome o service `clock` (`../services/clock/`) e
  tem dois styles, `digital` e `compact`, escolhidos só pela configuração
  (decisão 3.1/3.5). `acquire`/`release` do service acontecem em
  `Component.onCompleted`/`onDestruction` — o `Loader` da `Page` já destrói
  o widget sozinho quando a page troca, então o desligar do service é de
  graça, não precisa de código extra para isso.
- `island-editor` (0.503, gap em 0.504, autohide em 0.505) — o controle da
  página Islands da Settings (decisão 8.3): lê uma island direto de
  `core/Config.qml` e só escreve através de `core/CliRunner.qml`, nunca em
  `Config` (decisão 6.3). Um style só, `panel`, porque Appearance (estilo
  visual da própria Settings) está fora de escopo aqui. Desde a 0.504
  também expõe o gap exclusivo da island, pelo mesmo caminho (`set gap`);
  desde a 0.505, o `autohide`/`autohideMode` da island (resolvidos com o
  global via `ConfigShape.resolveAutohide`) — ver `island/README.md` para a
  conta por trás dos dois.
- `autohide-settings` (0.505) — o único controle global do autohide na
  página Islands: a distância de gatilho (decisão 12.4), mostrada uma vez
  só, acima de cada `island-editor`. Mesma fronteira de escrita que
  `island-editor` — lê `core/Config.qml`, escreve só via `CliRunner`
  (`autohide set distance`).
- `keybinds-editor` (0.507) — a página Keybinds da Settings inteira: o
  consentimento (decisão 10.3b) e a lista de keybinds (decisão 7.5). Mesma
  fronteira de escrita que `island-editor`/`autohide-settings` — lê
  `core/Config.qml`, escreve só via `CliRunner` (`hyprland set enabled` /
  `hyprland set keybinds`). Nunca toca `~/.config/hypr` — isso só acontece
  quando o consentimento está ligado e a shell em execução reage à mudança
  (`core/HyprlandSync.qml`, ver `cli/README.md`). Primeiro widget da
  Settings com texto livre — introduz `TextInput`, só confirmado em
  `onEditingFinished`, nunca por tecla.
- `not-built` (0.503) — o que aparece nas nove páginas da Settings que
  ainda não existem (decisão 8.1). Mesmo o placeholder é um widget de
  verdade, para a Settings inteira ficar dentro do mecanismo de pages e
  widgets, sem caso especial por fora.
