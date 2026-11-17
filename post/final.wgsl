// The last pass, at the window's size: edge smoothing (Horizon's own anti-aliasing
// is off while a pack draws the frame), the bloom laid on, the underwater and lava
// tints, the grade (contrast, saturation, a touch of warmth) and a vignette.

override bloom: f32 = 0.15;
override saturation: f32 = 1.1;
override contrast: f32 = 1.06;
override vignette: f32 = 0.35;
override smooth_edges: bool = true;
override outlines: bool = true;
override outline_thickness: u32 = 2u;
override outline_strength: f32 = 0.9;

const OUTLINE_DIRS: array<vec2<f32>, 8> = array<vec2<f32>, 8>(
    vec2<f32>(1.0, 0.0), vec2<f32>(-1.0, 0.0), vec2<f32>(0.0, 1.0), vec2<f32>(0.0, -1.0),
    vec2<f32>(0.7, 0.7), vec2<f32>(-0.7, 0.7), vec2<f32>(0.7, -0.7), vec2<f32>(-0.7, -0.7),
);

fn tap(uv: vec2<f32>) -> vec3<f32> {
    return textureSampleLevel(previous, linear_sampler, uv, 0.0).rgb;
}

// A small FXAA-style smoother: blend along an edge where brightness steps sharply.
fn smoothed(uv: vec2<f32>, center: vec3<f32>) -> vec3<f32> {
    let px = 1.0 / vec2<f32>(textureDimensions(previous));
    let n = lum(tap(uv + vec2<f32>(0.0, -px.y)));
    let s = lum(tap(uv + vec2<f32>(0.0, px.y)));
    let w = lum(tap(uv + vec2<f32>(-px.x, 0.0)));
    let e = lum(tap(uv + vec2<f32>(px.x, 0.0)));
    // Edges are judged on a perceptual scale.
    let c = sqrt(lum(center));
    let nn = sqrt(n);
    let ss = sqrt(s);
    let ww = sqrt(w);
    let ee = sqrt(e);
    let lo = min(c, min(min(nn, ss), min(ww, ee)));
    let hi = max(c, max(max(nn, ss), max(ww, ee)));
    if hi - lo < max(0.05, hi * 0.12) {
        return center;
    }
    let horizontal = abs(nn + ss - 2.0 * c) > abs(ww + ee - 2.0 * c);
    let along = select(vec2<f32>(0.0, px.y), vec2<f32>(px.x, 0.0), horizontal) * 0.75;
    let blend = (tap(uv + along) + tap(uv - along)) * 0.5;
    return mix(center, blend, 0.55);
}

// Silhouette outlines: where the depth jumps, something in front ends against
// what is behind it (terrain, entities, items). The API has no entity-ID mask,
// so this is a depth-based rim rather than a per-entity coloured outline.
fn outline_edge(input: PostInput) -> f32 {
    if !outlines || input.depth <= 0.0 {
        return 0.0;
    }
    let size = vec2<f32>(textureDimensions(scene_depth));
    let px = f32(outline_thickness) / size;
    let p = view_position(input.uv, input.depth);
    let dist = length(p);
    if dist > 96.0 {
        return 0.0;
    }
    var edge = 0.0;
    for (var i = 0; i < 8; i++) {
        let uv = input.uv + OUTLINE_DIRS[i] * px;
        if any(uv < vec2<f32>(0.0)) || any(uv > vec2<f32>(1.0)) {
            continue;
        }
        let d = depth_at(uv);
        if d <= 0.0 {
            // A silhouette against the sky, but only near by: distant
            // foliage against the sky must not speckle the whole picture.
            edge = max(edge, 1.0 - smoothstep(24.0, 64.0, dist));
            continue;
        }
        let q = view_position(uv, d);
        // One-sided: only a foreground pixel against a clearly farther
        // background is an edge; cutout interiors never cross the threshold.
        let gap = length(q) - dist;
        let threshold = 0.4 + dist * 0.06;
        edge = max(edge, smoothstep(threshold, threshold * 4.0, gap));
    }
    return edge * outline_strength;
}

fn post(input: PostInput) -> vec4<f32> {
    var c = input.color.rgb;
    if smooth_edges {
        c = smoothed(input.uv, c);
    }
    if outlines {
        let edge = outline_edge(input);
        if edge > 0.0 {
            // A thin, neutral dark rim — no purple glow on every leaf.
            c = mix(c, vec3<f32>(0.02, 0.02, 0.03), edge);
        }
    }
    if bloom > 0.0 {
        c += textureSampleLevel(t_bloom_b, linear_sampler, input.uv, 0.0).rgb * bloom * 1.8;
    }

    // Under water: blue-green, losing red with distance; in lava: deep orange.
    c = mix(c, c * vec3<f32>(0.35, 0.70, 0.85) + vec3<f32>(0.0, 0.012, 0.02), frame.in_water * 0.85);
    c = mix(c, c * vec3<f32>(1.3, 0.5, 0.2) + vec3<f32>(0.08, 0.02, 0.0), frame.in_lava * 0.9);

    // Contrast around middle grey, then saturation around the luminance.
    let pivot = vec3<f32>(0.18);
    c = max(c, vec3<f32>(0.0));
    c = max(pivot * pow(c / pivot, vec3<f32>(contrast)), vec3<f32>(0.0));
    let grey = vec3<f32>(lum(c));
    c = max(mix(grey, c, saturation), vec3<f32>(0.0));

    if vignette > 0.0 {
        let q = input.uv - vec2<f32>(0.5);
        c *= 1.0 - dot(q, q) * vignette * 1.4;
    }
    return vec4<f32>(c, 1.0);
}
