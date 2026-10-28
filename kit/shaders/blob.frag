#version 440
// vtnc's blob surface (stage 8, 2026-10-11; our own, after caelestia's idea of merged SDF boxes):
// the screen frame (an inverted rounded rect) and up to four rounded boxes, each merged into what's
// drawn before it with a circular smooth-min of its own radius (`smoothN`; 0 = a plain union), so
// they flow into each other like liquid. Each box has its four radii (the jelly's matrix went, 2026-10-27). Compiled with: qsb --glsl "100es,120,150" --hlsl 50 --msl 12 -o blob.frag.qsb blob.frag

layout(location = 0) in vec2 qt_TexCoord0;
layout(location = 0) out vec4 fragColor;

layout(std140, binding = 0) uniform buf {
    mat4 qt_Matrix;
    float qt_Opacity;
    vec2 itemSize;
    vec4 color;
    // the frame's own colour (Appearance → General → Frame; = color when Auto), blended into the
    // body's across the merge
    vec4 frameColor;
    // the frame's hole: centre x, y, half width, half height (half width < 0: no frame)
    vec4 frameInner;
    float frameRadius;
    // boxes: centre x, y, half width, half height (half width < 0: unused); radii tl, tr, br, bl; the
    // merge radius
    vec4 box0;
    vec4 radii0;
    float smooth0;
    vec4 box1;
    vec4 radii1;
    float smooth1;
    vec4 box2;
    vec4 radii2;
    float smooth2;
    vec4 box3;
    vec4 radii3;
    float smooth3;
};

// a rounded box centred at the origin, half size b, radii r = (tl, tr, br, bl) (y grows down)
float sdBox(vec2 p, vec2 b, vec4 r) {
    float rr = p.x > 0.0 ? (p.y > 0.0 ? r.z : r.y) : (p.y > 0.0 ? r.w : r.x);
    rr = min(rr, min(b.x, b.y));
    vec2 q = abs(p) - b + rr;
    return min(max(q.x, q.y), 0.0) + length(max(q, 0.0)) - rr;
}

// circular smooth min: the blend is a circular arc of radius k tangent to both shapes
float smin(float a, float b, float k) {
    if (k <= 0.0)
        return min(a, b);
    return max(k, min(a, b)) - length(max(vec2(k) - vec2(a, b), vec2(0.0)));
}

// a box's distance (a large one when unused)
float boxDist(vec2 p, vec4 box, vec4 radii) {
    if (box.z < 0.0)
        return 1e5;
    return sdBox(p - box.xy, box.zw, radii);
}

float merge(float d, vec2 p, vec4 box, vec4 radii, float k) {
    if (box.z < 0.0)
        return d;
    return smin(d, sdBox(p - box.xy, box.zw, radii), k);
}

void main() {
    vec2 p = qt_TexCoord0 * itemSize;
    float d = 1e5;
    if (frameInner.z >= 0.0)
        d = -sdBox(p - frameInner.xy, frameInner.zw, vec4(frameRadius));
    float df = d;
    d = merge(d, p, box0, radii0, smooth0);
    d = merge(d, p, box1, radii1, smooth1);
    d = merge(d, p, box2, radii2, smooth2);
    d = merge(d, p, box3, radii3, smooth3);
    // the colour: the frame's where the frame is nearer than any body, the body's elsewhere, blended
    // over half the island's merge radius (the flares)
    float db = min(min(boxDist(p, box0, radii0), boxDist(p, box1, radii1)), min(boxDist(p, box2, radii2), boxDist(p, box3, radii3)));
    float band = max(1.0, smooth0 * 0.5);
    vec4 c = mix(color, frameColor, clamp(0.5 + (db - df) / (2.0 * band), 0.0, 1.0));
    // a one pixel soft edge
    float aa = max(fwidth(d), 1e-4);
    float a = clamp(0.5 - d / aa, 0.0, 1.0);
    fragColor = vec4(c.rgb * c.a, c.a) * a * qt_Opacity;
}
