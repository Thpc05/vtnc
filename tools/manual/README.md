# tools/manual

Testes que **você** roda e **olha**, não que um agente roda e mede. Cada um
sobe uma shell de teste com um `VTNC_CONFIG_DIR` temporário — nada da sua
configuração é tocado — imprime o que fazer, e devolve tudo no Ctrl-C:
os workspaces de cada monitor, a posição do cursor, e nenhuma reserva
sobrando.

| | |
|---|---|
| `autohide-window.sh` | o autohide no modo `window`: abra e feche uma janela e veja a island sumir e voltar |

## A pegadinha que todos eles precisam evitar

A Settings abre junto com a shell (decisão 1d.6) e é uma **janela comum** do
Hyprland. No modo `window` ela conta como "existe janela" — então subir a
vtnc e olhar faz a island nascer escondida, e parece defeito. Não é: ela está
reagindo à Settings.

Por isso estes scripts sobem a shell num workspace descartável e só então
levam você para o workspace de teste. E não basta esperar a CLI responder: a
janela da Settings mapeia **depois** disso, e se o workspace já tiver mudado
ela nasce no lugar errado. Espere a janela existir, e confira que ela ficou
para trás — é o que o aviso no início do script faz.

## Ler a linha de baixo

`reserved topo` é quanto o Hyprland de fato reservou naquele monitor, lido de
`hyprctl monitors -j`. É a medida exata, não uma interpretação do tamanho de
uma janela. Com a island presente é a altura dela em pixels; escondida, zero.

Se ela ficar em zero **depois** de você apertar Ctrl-C, isso não é a island
escondida: é a shell de teste já encerrada.
