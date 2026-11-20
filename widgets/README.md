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

A 0.51 só tem `square`: um quadrado burro com texto, para provar o
tripé type/style/page com o mínimo de código possível (decisão 16.4). Sem
services — não precisa de nenhum.
