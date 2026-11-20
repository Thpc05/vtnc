// Describes the type (decision 19.1). Declares the services it uses, as a
// list (decision 5.2b) — just one here, but the shape is ready for a type
// that needs several.
export default {
    type: "vtnc.clock",
    title: "Clock",
    services: ["clock"],
    styles: ["digital", "compact"],
};
