# core

A base que não conhece ninguém acima dela: nenhum arquivo aqui importa
`island/`, `page/` ou `modules/`.

- `grid.mjs` — matemática pura (célula base × fator do monitor, âncora +
  deslocamento → geometria em pixels). Testada em node (`tests/unit/`).
- `config-shape.mjs` — defaults e lookups sobre o documento de config. Pura,
  sem I/O, também testada em node.
- `Paths.qml` — onde o config/estado do vtnc vivem (`~/.config/vtnc`,
  `~/.local/state/vtnc`), com override por `VTNC_CONFIG_DIR`/`VTNC_STATE_DIR`
  para o ambiente de teste descartável.
- `Config.qml` — lê `config.json` com `FileView`/`watchChanges`, para captar
  um `set` da CLI sem round-trip de IPC.
- `IslandState.qml` — só em memória: a pilha de pages que um `call` empilha
  por cima da idle de cada island (até 5, decisão 1e.2), e qual page cada
  espelho está de fato desenhando (0.506, para o critério 3 — observável
  por `vtnc island <nome> get`'s `mirrors`, sem olhar pixel). Nunca grava em
  disco; é isso que faz `call` ser momentâneo e `set` permanente. A pilha e
  o desempilhar (`end`) são `ConfigShape.pushCall`/`popCall`/`topOfCall`,
  puros e testados em node — este arquivo só guarda o estado reativo por
  cima.
- `CliRunner.qml` — a única porta para o binário `cli/vtnc` de verdade
  (`Quickshell.shellDir` acha onde ele mora). A Settings usa isto para toda
  mudança (decisão 6.3): nunca escreve em `Config` nem no arquivo
  diretamente.
- `HoverCursor.qml` (0.505) — pergunta a posição do mouse a `hyprctl
  cursorpos` de tempos em tempos (só leitura — ver `island/README.md`'s
  seção de autohide para o motivo de não dar para fazer isso com uma
  superfície de verdade).
- `HyprlandSync.qml` (0.507) — fica de olho na seção `hyprland` da config e,
  quando ela muda **e** o consentimento foi dado (decisão 10.3b), dispara
  `vtnc hyprland generate`. É isto que quer dizer "a shell roda `hyprctl
  reload` sozinha" (decisão 7.2): quem dispara é a shell em execução, nunca
  o `vtnc hyprland set`, que só escreve o `config.json` como todo `set`
  (decisão 4b.4). Compara `JSON.stringify` da seção, não a config inteira,
  para não re-gerar quando o que mudou foi uma island; e como a assinatura
  começa vazia, uma shell recém-aberta re-sincroniza por conta própria se o
  consentimento já tinha sido dado antes.
- `plugin-manifest.mjs` (0.512) — o que um `plugin.json` precisa ter, e o
  que um `meta.json` de module e de face precisam ter. Tudo funcao pura: o
  node valida nos testes e na CLI, o QML valida na shell, com o mesmo
  codigo. Aqui tambem mora a faixa de API (`PLUGIN_API_MIN`/`CURRENT`): um
  inteiro cumulativo, e um plugin fora da faixa e recusado **pela faixa**,
  com motivo escrito, em vez de quebrar no meio da carga.
- `plugin-catalog.mjs` (0.512) — o catalogo montado a partir do que a
  varredura achou: quais plugins existem, quais modules e faces cada um
  traz, e a URL do QML de cada coisa. Substituiu o `widget-registry.mjs` e o
  `widget-catalog.mjs` da 0.509/0.508, que importavam cada meta **a mao** —
  ali a lista de quem existe era codigo escrito dentro da shell, e era por
  isso que nada de fora dela podia entrar. Aqui ela e dado, e o proprio vtnc
  entra por ele como qualquer plugin.

  A lista de faces de um module nao mora aqui nem no meta do module: ela e
  **derivada** do `module` que cada face declara (decisao 3.5), que era a
  unica forma de ela nao existir escrita em dois lugares que podem
  discordar. Como a face nomeia o module pelo nome completo, uma face pode
  vestir o module de **outro plugin** — e o que faz "qualquer um escreve
  estilos" ser verdade. Daqui tambem sai a URL de uma face, com queda para
  o `defaultFace` do module quando o nome pedido nao existe: a config e um
  arquivo que o usuario edita a mao, e um nome errado nao pode fazer o
  widget sumir da tela.

  Nada aqui lanca excecao. Um plugin quebrado vira um problema na lista e
  os outros continuam carregando — a mesma regra da 3.4d que ja valia para
  uma declaracao de opcao invalida.
- `PluginRegistry.qml` (0.512) — a varredura do lado da shell; o lado node
  e `cli/lib/plugins.js`, e os dois chamam o mesmo `buildCatalog`. Medido
  com `qs` antes de escrever: `Qt.labs.folderlistmodel` lista pastas, e um
  `FileView { blockLoading: true }` criado em tempo de execucao le arquivo
  de forma **sincrona** — o catalogo inteiro se monta dentro de uma funcao,
  sem cascata de callbacks. So a listagem de pastas e assincrona, e por
  isso um plugin instalado entra no catalogo um instante depois de a shell
  subir; quem desenha reage a `catalog` mudar.

  Pegadinha medida aqui: com uma pasta que nao existe, o `FolderListModel`
  nao fica vazio — ele continua listando o diretorio corrente, e a shell
  "achou" um plugin para cada pasta do proprio repositorio. Confere-se a
  pasta que ele de fato abriu antes de acreditar no que ele lista.
- `face-schema.mjs` (0.510) — o que uma face pode declarar como opcao, e
  o que a shell aceita como valor. A decisao 3.4d da a forma ao arquivo
  inteiro: a face DESCREVE, a shell DECIDE. Por isso `min`/`max`, a lista
  do `choice`, os papeis de cor e o teto do texto sao impostos aqui, de
  fora, e por isso uma declaracao ruim e DESCARTADA (`partitionSchema`) em
  vez de derrubar a face inteiro — a shell tem de ser modulavel e
  confiavel ao mesmo tempo, e um meta mal escrito de terceiro nao pode
  tirar tudo do ar. `resolveOptions` entrega so o que a face declarou, com
  o default no lugar de qualquer valor que nao sirva mais; `withOption` e
  `storedOptionsFor` guardam por nome de face, que e o que faz a 4.4
  funcionar sem codigo nenhum "lembrando" das opcoes antigas.
- `palette.mjs` (0.510) — papel de cor em cor de verdade, **provisorio**
  (decisao 3.4c) ate o bloco de Appearance existir. Nenhuma face conhece
  estes valores: a cor ja chega resolvida a ele. Trocar esta tabela troca a
  shell inteira de uma vez, que e exatamente o motivo de o controle ser
  `role` e nao um seletor de cor livre.
- `hyprland-lua.mjs` (0.507) — a geração do texto Lua, pura, sem I/O (quem
  escreve e recarrega é `cli/lib/hyprland-write.js`). Fica separada do
  `config-shape.mjs` porque trata da sintaxe do Hyprland, não da forma do
  documento de config. As teclas saem em `[[...]]` (string de colchete longo
  do Lua) porque uma tecla ou comando digitado pelo usuário pode conter
  aspas ou contrabarra; isso só quebra se o texto contiver `]]`, contra o
  que nada aqui protege.

Os tipos QML daqui são expostos via `qmldir` (singletons), não por import de
arquivo único — ver nota em `../AGENTS.md`-adjacente: imports de arquivo
único com `as` não funcionam de forma confiável neste Quickshell.
