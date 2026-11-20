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
