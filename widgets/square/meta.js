// O module mais burro que existe, de proposito: ele prova a separacao
// module/face (3.1/3.5) com o minimo de codigo. Ver widgets/clock/meta.js
// para o que cada campo quer dizer.
export default {
    module: "vtnc.square",
    title: "Square",
    services: [],
    defaultFace: "default",
    provides: [
        { name: "text", kind: "string", doc: "O texto a desenhar dentro do quadrado; vem da propria instancia do widget." },
    ],
};
