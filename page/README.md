# page

O grupo reutilizável de widgets, com grid próprio. É dona das instâncias de
widget — mexer numa page muda todas as islands que a usam (decisão 6.1).

`Page.qml` instancia um widget por entrada em `pageConfig.widgets`, posiciona
em células (convertidas para px pelo `cellPx` da tela que a island está em),
e escolhe o `type` certo. A 0.51 só tem um type (`vtnc.square`); um segundo
type só precisa de uma nova entrada no `switch` do `Loader`, não de mudar o
resto do arquivo.

Os ciclos de vida (`idle`/`called`) vivem na `Island`, que decide qual
`pageConfig` passar para cá — a Page em si não sabe em qual ciclo está.
