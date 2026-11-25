# page

O grupo reutilizável de widgets, com grid próprio. É dona das instâncias de
widget — mexer numa page muda todas as islands que a usam (decisão 6.1).

`Page.qml` instancia um widget por entrada em `pageConfig.widgets`, posiciona
em células (convertidas para px pelo `cellPx` da tela que a island está em),
e escolhe o `module` certo. Cada module novo é uma entrada a mais no `switch` do
`Loader`, não uma mudança no resto do arquivo — hoje são `vtnc.square`,
`vtnc.clock`, `vtnc.island-editor` e `vtnc.not-built`.

Os ciclos de vida (`idle`/`called`/`popup`/`lock`) vivem na `Island`, que
decide qual `pageConfig` passar para cá — a `Page` em si não sabe em qual
ciclo está, não desenha chrome nenhum e não reage a Esc. Isso tudo é
`island/Island.qml` olhando para `pageConfig.lifecycle` (0.506) — ver
`island/README.md` para a conta inteira. A Settings (`../settings/`) usa
essa mesma `Page`, sem câmbio nenhum nela, com um `cellPx` próprio e um
`pageConfig` montado na hora a partir do `core/Config.qml` em vez de vir de
uma island — prova que o mecanismo não é exclusivo de islands de verdade
(decisão 8.3).

Uma page declara, além de `grid`/`widgets`:

- `lifecycle` (`"called"` por padrão, ou `"popup"`/`"lock"`) — decisões
  1e.0/1e.1.
- `needsKeyboard` (bool, padrão `false`) — decisão 1e.5: só quem declara
  rouba o teclado enquanto estiver chamada.
- `popupTimeout` (ms, padrão 5000) — só lido quando `lifecycle` é `"popup"`.

Nenhum dos três tem verbo de CLI nem controle na Settings ainda — como
`pages.<nome>.widgets`, são editados direto no `config.json` por enquanto
(nenhuma página da Settings edita pages, decisão de escopo da 0.503, e isso
não muda aqui).
