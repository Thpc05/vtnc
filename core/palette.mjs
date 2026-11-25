// Os papeis de cor em cores de verdade (decisao 3.4c), **provisorio**.
//
// A 3.4b fechou o controle `role`: uma face nomeia um papel, nunca um
// hexadecimal. Alguem tem de traduzir papel em cor, e enquanto o bloco de
// Appearance nao existe e este arquivo - uma tabela fixa, escrita para
// combinar com o andaime cinza que a Settings usa hoje.
//
// Quando o Appearance existir, ele substitui esta tabela e nada mais muda:
// nenhuma face conhece estes valores, porque a cor ja chega resolvida a
// eles (ver resolveFaceOptions em face-schema.mjs). Trocar a tabela
// troca a shell inteira de uma vez, que e exatamente o motivo de o
// controle ser `role` e nao um seletor de cor livre.

export const PROVISIONAL_PALETTE = {
    primary: "#3a6ea5",
    accent: "#3a6ea5",
    surface: "#262626",
    surfaceAlt: "#3a3a3a",
    text: "#ffffff",
    textMuted: "#999999",
    border: "#808080",
};

// Um papel desconhecido nao pinta de transparente nem quebra o desenho:
// cai no texto, que e visivel em qualquer fundo que a shell use hoje.
// Isso nao substitui a validacao - `validateOptionValue` ja recusa um
// papel que nao existe antes de ele chegar ao config.json - e so a ultima
// rede, para o caso de a tabela e a lista de papeis sairem de sincronia.
export function colorForRole(role) {
    return PROVISIONAL_PALETTE[role] ?? PROVISIONAL_PALETTE.text;
}
