// Complementary Reimagined for Horizon (shader API 0.2): what every stage shares.
// Every colour here is linear light (1.0 is paper white). Colours picked by eye in
// display values are decoded with `lin` first.

const PI: f32 = 3.14159265;

fn lum(c: vec3<f32>) -> f32 {
    return dot(c, frame.luminance);
}

fn lin(c: vec3<f32>) -> vec3<f32> {
    return pow(max(c, vec3<f32>(0.0)), vec3<f32>(2.2));
}

fn sat(x: f32) -> f32 {
    return clamp(x, 0.0, 1.0);
}

fn overworld() -> bool {
    return frame.dimension == 0;
}

fn nether() -> bool {
    return frame.dimension == -1;
}

fn the_end() -> bool {
    return frame.dimension == 1;
}

// ---------------------------------------------------------------- noise

fn hash12(p: vec2<f32>) -> f32 {
    var p3 = fract(vec3<f32>(p.x, p.y, p.x) * 0.1031);
    p3 += dot(p3, p3.yzx + 33.33);
    return fract((p3.x + p3.y) * p3.z);
}

fn hash13(p: vec3<f32>) -> f32 {
    var p3 = fract(p * 0.1031);
    p3 += dot(p3, p3.zyx + 31.32);
    return fract((p3.x + p3.y) * p3.z);
}

// Smooth value noise, 0..1.
fn noise2(p: vec2<f32>) -> f32 {
    let i = floor(p);
    let f = fract(p);
    let u = f * f * (3.0 - 2.0 * f);
    let a = hash12(i);
    let b = hash12(i + vec2<f32>(1.0, 0.0));
    let c = hash12(i + vec2<f32>(0.0, 1.0));
    let d = hash12(i + vec2<f32>(1.0, 1.0));
    return mix(mix(a, b, u.x), mix(c, d, u.x), u.y);
}

// Interleaved gradient noise: a per-pixel dither that hides banding and step patterns.
fn dither(pixel: vec2<f32>) -> f32 {
    let f = fract(f32(frame.frame_index % 64u) * 0.618034);
    return fract(52.9829189 * fract(dot(pixel, vec2<f32>(0.06711056, 0.00583715))) + f);
}

// ---------------------------------------------------------------- time of day

// 0 at night, 1 by day, with a short blend around sunrise and sunset.
fn daylight() -> f32 {
    return select(0.0, smoothstep(-0.12, 0.1, frame.sun_direction.y), overworld());
}

// 1 with the sun on the horizon, 0 once it is well up (or well down).
fn sun_low() -> f32 {
    return 1.0 - smoothstep(0.0, 0.32, abs(frame.sun_direction.y));
}

// How high the sun is, 0 at the horizon or below, 1 near the top of its arc.
fn noon() -> f32 {
    return smoothstep(0.1, 0.6, frame.sun_direction.y);
}

fn wet() -> f32 {
    return max(frame.wetness, max(frame.rain * 0.5, frame.thunder));
}

// The light of the sun (or the moon by night) as it reaches the ground.
fn sun_color() -> vec3<f32> {
    if !overworld() {
        return vec3<f32>(0.0);
    }
    let noon_c = vec3<f32>(1.0, 0.92, 0.80);
    let morning = vec3<f32>(1.0, 0.70, 0.42);
    let dusk = vec3<f32>(1.0, 0.36, 0.10);
    let high = mix(morning, noon_c, noon());
    let day = mix(high, dusk, sun_low() * sun_low()) * smoothstep(-0.05, 0.08, frame.sun_direction.y);
    let moon = vec3<f32>(0.10, 0.16, 0.32) * 0.38 * smoothstep(-0.05, 0.1, frame.moon_direction.y);
    let c = select(moon, day, frame.sun_direction.y > -0.02);
    return c * (1.0 - 0.8 * wet());
}

// ---------------------------------------------------------------- the sky's colours

fn sky_zenith() -> vec3<f32> {
    let day = mix(vec3<f32>(0.11, 0.26, 0.66), vec3<f32>(0.08, 0.13, 0.36), sun_low());
    let night = vec3<f32>(0.0035, 0.0065, 0.022);
    return mix(night, day, daylight());
}

fn sky_horizon() -> vec3<f32> {
    let day = mix(vec3<f32>(0.46, 0.64, 0.94), vec3<f32>(0.95, 0.43, 0.17), sun_low());
    let night = vec3<f32>(0.016, 0.028, 0.068);
    return mix(night, day, max(daylight(), sun_low() * 0.6));
}

// The pack's sky along `d` without the sun, clouds or stars: also what water and
// wet ground reflect and what the distance fades into.
fn sky_gradient(d: vec3<f32>) -> vec3<f32> {
    let up = clamp(d.y, -1.0, 1.0);
    let t = pow(sat(up), 0.42);
    var col = mix(sky_horizon(), sky_zenith(), t);

    // A warm glow on the side of the sky the sun is setting on.
    let sun = frame.sun_direction;
    let flat_d = normalize(vec2<f32>(d.x, d.z) + vec2<f32>(1e-4, 0.0));
    let flat_s = normalize(vec2<f32>(sun.x, sun.z) + vec2<f32>(1e-4, 0.0));
    let toward = 0.5 + 0.5 * dot(flat_d, flat_s);
    let band = pow(toward, 5.0) * (1.0 - t) * sun_low() * smoothstep(-0.2, 0.05, sun.y);
    col += lin(vec3<f32>(1.0, 0.55, 0.30)) * band * 0.7;
    // Pink on the far side of a sunset.
    col += lin(vec3<f32>(0.55, 0.32, 0.50)) * pow(1.0 - toward, 3.0) * (1.0 - t) * sun_low() * 0.25 * daylight();

    // Under the horizon the sky darkens toward the ground.
    let below = 1.0 - smoothstep(-0.3, 0.0, up);
    col = mix(col, col * 0.35, below);

    // Rain greys it.
    let w = wet();
    col = mix(col, vec3<f32>(lum(col)) * 0.55, w * 0.8);
    return max(col, vec3<f32>(0.0));
}

// The colour distance fades into in each dimension.
fn haze_color(d: vec3<f32>) -> vec3<f32> {
    if overworld() {
        return sky_gradient(vec3<f32>(d.x, max(d.y, 0.02), d.z));
    }
    if nether() {
        return frame.fog_color * 0.9;
    }
    if the_end() {
        return lin(vec3<f32>(0.10, 0.07, 0.14));
    }
    return frame.fog_color;
}

// The open sky's light on everything under it.
fn ambient_color() -> vec3<f32> {
    if nether() {
        return frame.fog_color * 0.35 + lin(vec3<f32>(0.24, 0.13, 0.08)) * 0.25;
    }
    if the_end() {
        return lin(vec3<f32>(0.20, 0.15, 0.26)) * 0.6;
    }
    let day = mix(vec3<f32>(0.28, 0.40, 0.66), vec3<f32>(0.42, 0.30, 0.26), sun_low());
    let night = vec3<f32>(0.010, 0.017, 0.046);
    let base = mix(night, day * 0.85, daylight());
    return mix(base, vec3<f32>(lum(base)) * 0.8, wet() * 0.6);
}
