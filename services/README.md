# services

Código único e compartilhado que fala com o sistema (ou, na 0.502, com
nada: o relógio não depende de nada real) — ligado só enquanto algum widget
visível precisa, desligado quando o último sai de cena (decisão 5.2).

- `ServiceRegistry.qml` — singleton. `acquire(nome)`/`release(nome)` contam
  quem está usando; a contagem é da shell, não do widget que chama
  (decisão 5.2b). A instância do service só existe enquanto a contagem é
  maior que zero — é isso que liga/desliga.
- `clock/` — o service real desta etapa: um timer só na shell inteira
  (decisão 15.2), para não ter vinte widgets com vinte timers desalinhados.

Um `widgets/<module>` consome um service chamando
`ServiceRegistry.acquire("nome")` no `Component.onCompleted` e
`ServiceRegistry.release("nome")` no `Component.onDestruction`, e lê o
estado vivo por `ServiceRegistry.get("nome")`.
