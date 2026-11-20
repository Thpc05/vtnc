# tools

## Ambiente de teste: dois modos

**Padrão: Hyprland aninhado** (`headless/nested.sh`). Lançar o binário do
Hyprland de dentro de uma sessão Hyprland real abre uma nova instância
aninhada, numa janela, isolada da sessão real — é a forma documentada pelo
próprio wiki do Hyprland de testá-lo. `nested.sh start <env-file>` sobe essa
instância com dois outputs headless (FullHD e QuadHD, o par real do Theo) e
escreve `WAYLAND_DISPLAY`/`HYPRLAND_INSTANCE_SIGNATURE` em `<env-file>`;
`nested.sh stop <env-file>` a derruba.

Cuidado real: preserve o ambiente do chamador ao lançar — em especial
`WAYLAND_DISPLAY` — porque é dele que o backend Wayland aninhado do
Aquamarine tira seu *allocator*. Um `env -i` quebra isso silenciosamente
(foi o primeiro erro deste passo). Nunca rode `hyprctl dispatch` contra a
instância aninhada nem troque de workspace nela; selecione sempre pelo
`HYPRLAND_INSTANCE_SIGNATURE` para não confundir com a sessão real.

Limitações conhecidas: janelas sem foco renderizam a 15fps por padrão (não
confie nisso para timing/suavidade); D-Bus é da sessão inteira, não do
compositor aninhado (notificações/portais vão esbarrar na sessão real —
isole com `dbus-run-session` se for testar isso).

**Não usamos weston nem sway.** O aninhado é a forma documentada e correta
de testar o Hyprland; trocar de compositor hospedeiro não traria nada e
fugiria do caminho já comprovado pelo próprio projeto.

**Opt-in: a tela real do Theo.** Só quando o aninhado não dá confiabilidade
suficiente: suavidade/tempo de animação, comportamento real de múltiplos
monitores no hardware dele, qualquer coisa de sessão inteira (portais,
atalhos globais, notificação real), e a aceitação visual final. Pedir
autorização a cada vez, dizendo o que vai rodar e por quanto tempo, e como
abortar — nunca entrar nesse modo por conta própria.

**Antes de qualquer compositor**: as camadas 1 (lógica pura), 2 (compilação
do QML) e 4 (visual) não precisam de nenhum compositor —
`QT_QPA_PLATFORM=offscreen` cobre as três. Só a camada 3 (contrato da CLI) e
a geometria real de uma island precisam do aninhado.

## Arquivos

- `headless/nested.sh` — sobe/derruba o Hyprland aninhado.
- `headless/hyprland.lua` — config descartável do aninhado.
