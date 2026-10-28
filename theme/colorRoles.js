.pragma library

// The shell's color tokens and where each comes from. matugen's whole output (`matugen … --dry-run
// -j hex`, in ~/.cache/vtnc/matugen.json) holds every role for both schemes and the tonal palettes;
// the user's mapping (Store.theme.colors[mode][token]) may point a token somewhere else.
// A spec (what the state stores) is one of:
//  - "light:<role>" / "dark:<role>"  a matugen role from that scheme (follows the wallpaper)
//  - "tone:<palette>:<tone>"         a palette tone (follows the wallpaper)
//  - "#rrggbb"                       a fixed color
//  - "oled"                          pure black in dark mode, pure white in light mode
// With no spec a token takes its default: its role in the current mode (background: M3 surface, as
// caelestia; "oled" is one click away).

var PALETTES = ["primary", "secondary", "tertiary", "neutral", "neutral_variant", "error"];
var TONES = [0, 5, 10, 15, 20, 25, 30, 35, 40, 50, 60, 70, 80, 90, 95, 98, 99, 100];
var GROUPS = ["Accent", "Surfaces", "Text", "Outline", "Error"];

// { token, role, group, title, def?, fallback } — fallback: the palette used until matugen ran
var TOKENS = [
    { token: "primary", role: "primary", group: "Accent", title: "Primary", fallback: "#99ccfa" },
    { token: "overPrimary", role: "on_primary", group: "Accent", title: "On primary", fallback: "#003352" },
    { token: "primaryContainer", role: "primary_container", group: "Accent", title: "Primary container", fallback: "#094a72" },
    { token: "overPrimaryContainer", role: "on_primary_container", group: "Accent", title: "On primary container", fallback: "#cde5ff" },
    { token: "secondary", role: "secondary", group: "Accent", title: "Secondary", fallback: "#b8c8da" },
    { token: "overSecondary", role: "on_secondary", group: "Accent", title: "On secondary", fallback: "#233240" },
    { token: "secondaryContainer", role: "secondary_container", group: "Accent", title: "Secondary container", fallback: "#394857" },
    { token: "overSecondaryContainer", role: "on_secondary_container", group: "Accent", title: "On secondary container", fallback: "#d4e4f6" },
    { token: "tertiary", role: "tertiary", group: "Accent", title: "Tertiary", fallback: "#d2bfe7" },
    { token: "overTertiary", role: "on_tertiary", group: "Accent", title: "On tertiary", fallback: "#382a4a" },
    { token: "tertiaryContainer", role: "tertiary_container", group: "Accent", title: "Tertiary container", fallback: "#4f4061" },
    { token: "overTertiaryContainer", role: "on_tertiary_container", group: "Accent", title: "On tertiary container", fallback: "#eddcff" },
    { token: "background", role: "surface", group: "Surfaces", title: "Background", fallback: "#101418" },
    { token: "tintedBackground", role: "background", group: "Surfaces", title: "Tinted background", fallback: "#101418" },
    // the screen frame and corners (2026-10-17): Auto follows the background token (Colors.qml)
    { token: "frame", role: "surface", group: "Surfaces", title: "Frame", follows: "background", fallback: "#101418" },
    { token: "surface", role: "surface", group: "Surfaces", title: "Surface", fallback: "#101418" },
    { token: "surfaceDim", role: "surface_dim", group: "Surfaces", title: "Surface dim", fallback: "#101418" },
    { token: "surfaceBright", role: "surface_bright", group: "Surfaces", title: "Surface bright", fallback: "#36393e" },
    { token: "surfaceContainerLowest", role: "surface_container_lowest", group: "Surfaces", title: "Container lowest", fallback: "#0b0f12" },
    { token: "surfaceContainerLow", role: "surface_container_low", group: "Surfaces", title: "Container low", fallback: "#181c20" },
    { token: "surfaceContainer", role: "surface_container", group: "Surfaces", title: "Container", fallback: "#1c2024" },
    { token: "surfaceContainerHigh", role: "surface_container_high", group: "Surfaces", title: "Container high", fallback: "#272a2e" },
    { token: "surfaceContainerHighest", role: "surface_container_highest", group: "Surfaces", title: "Container highest", fallback: "#313539" },
    { token: "surfaceVariant", role: "surface_variant", group: "Surfaces", title: "Surface variant", fallback: "#42474e" },
    { token: "inverseSurface", role: "inverse_surface", group: "Surfaces", title: "Inverse surface", fallback: "#e0e2e8" },
    { token: "overBackground", role: "on_background", group: "Text", title: "On background", fallback: "#e0e2e8" },
    { token: "overSurface", role: "on_surface", group: "Text", title: "On surface", fallback: "#e0e2e8" },
    { token: "overSurfaceVariant", role: "on_surface_variant", group: "Text", title: "On surface variant", fallback: "#c2c7ce" },
    { token: "overInverseSurface", role: "inverse_on_surface", group: "Text", title: "On inverse surface", fallback: "#2d3135" },
    { token: "inversePrimary", role: "inverse_primary", group: "Accent", title: "Inverse primary", fallback: "#2d628f" },
    { token: "outline", role: "outline", group: "Outline", title: "Outline", fallback: "#8c9198" },
    { token: "outlineVariant", role: "outline_variant", group: "Outline", title: "Outline variant", fallback: "#42474e" },
    { token: "shadow", role: "shadow", group: "Outline", title: "Shadow", fallback: "#000000" },
    { token: "scrim", role: "scrim", group: "Outline", title: "Scrim", fallback: "#000000" },
    { token: "error", role: "error", group: "Error", title: "Error", fallback: "#ffb4ab" },
    { token: "overError", role: "on_error", group: "Error", title: "On error", fallback: "#690005" },
    { token: "errorContainer", role: "error_container", group: "Error", title: "Error container", fallback: "#93000a" },
    { token: "overErrorContainer", role: "on_error_container", group: "Error", title: "On error container", fallback: "#ffdad6" }
];

var BY_TOKEN = {};
for (var i = 0; i < TOKENS.length; i++)
    BY_TOKEN[TOKENS[i].token] = TOKENS[i];

function isHex(s) {
    return /^#[0-9a-fA-F]{6}$/.test(String(s));
}

// the matugen roles in `data` (sorted), for the picker
function roles(data) {
    return data && data.colors ? Object.keys(data.colors).sort() : [];
}

// a token's default spec in `mode`
function defaultSpec(mode, token) {
    var t = BY_TOKEN[token];
    return t ? (t.def || mode + ":" + t.role) : "";
}

// the hex a spec points to in `data` for `mode`, or "" when it doesn't resolve
function specHex(data, mode, spec) {
    if (typeof spec !== "string" || spec === "")
        return "";
    if (spec === "oled")
        return mode === "light" ? "#ffffff" : "#000000";
    if (isHex(spec))
        return spec.toLowerCase();
    var parts = spec.split(":");
    if (!data)
        return "";
    if ((parts[0] === "light" || parts[0] === "dark") && parts.length === 2) {
        var r = data.colors && data.colors[parts[1]];
        var c = r && r[parts[0]];
        return c && isHex(c.color) ? c.color : "";
    }
    if (parts[0] === "tone" && parts.length === 3) {
        var p = data.palettes && data.palettes[parts[1]];
        var t = p && p[parts[2]];
        return t && isHex(t.color) ? t.color : "";
    }
    return "";
}

// the hex of `token` in `mode`: the user's spec, else the default, else the fallback palette
function resolve(data, mode, token, spec) {
    return specHex(data, mode, spec) || specHex(data, mode, defaultSpec(mode, token)) || (BY_TOKEN[token] ? BY_TOKEN[token].fallback : "#ff00ff");
}

// a spec as a label for the settings page ("" = the default)
function describe(spec) {
    if (typeof spec !== "string" || spec === "")
        return "Auto";
    if (spec === "oled")
        return "Pure black / white";
    if (isHex(spec))
        return spec.toLowerCase();
    var parts = spec.split(":");
    var nice = function (s) {
        return s.split("_").map(function (w) {
            return w.charAt(0).toUpperCase() + w.slice(1);
        }).join(" ");
    };
    if (parts.length === 2)
        return (parts[0] === "light" ? "Light" : "Dark") + " · " + nice(parts[1]);
    if (parts[0] === "tone" && parts.length === 3)
        return nice(parts[1]) + " · tone " + parts[2];
    return spec;
}

// a mapping ({ token: spec }) with only known tokens and string specs
function clean(map) {
    var out = {};
    if (!map || typeof map !== "object")
        return out;
    for (var k in map)
        if (BY_TOKEN[k] && typeof map[k] === "string" && map[k] !== "")
            out[k] = map[k];
    return out;
}
