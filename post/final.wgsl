// The last pass, at the window's size: edge smoothing (Horizon's own anti-aliasing
// is off while a pack draws the frame), the bloom laid on, the underwater and lava
// tints, the grade (contrast, saturation, a touch of warmth) and a vignette.

override bloom: f32 = 0.15;
override saturation: f32 = 1.1;
override contrast: f32 = 1.06;
override vignette: f32 = 0.35;
override smooth_edges: bool = true;

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

fn post(input: PostInput) -> vec4<f32> {
    var c = input.color.rgb;
    if smooth_edges {
        c = smoothed(input.uv, c);
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
