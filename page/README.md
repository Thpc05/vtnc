# page

O grupo reutilizável de widgets, com grid próprio. É dona das instâncias de
widget — mexer numa page muda todas as islands que a usam (decisão 6.1).

`Page.qml` instancia um widget por entrada em `pageConfig.widgets`, posiciona
em células (convertidas para px pelo `cellPx` da tela que a island está em),
e escolhe o `type` certo. Cada type novo é uma entrada a mais no `switch` do
`Loader`, não uma mudança no resto do arquivo — hoje são `vtnc.square` e
`vtnc.clock`.

Os ciclos de vida (`idle`/`called`) vivem na `Island`, que decide qual
`pageConfig` passar para cá — a Page em si não sabe em qual ciclo está.
