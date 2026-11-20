// The stand-in for one of the nine Settings pages the 0.503 step doesn't
// build (decision 8.1). Even the placeholder is a real widget, so every
// Settings page — built or not — is genuinely made of pages and widgets
// (decision 8.3), with nothing special-cased outside the mechanism.
export default {
    type: "vtnc.not-built",
    title: "Not built yet",
    services: [],
    styles: ["placeholder"],
};
