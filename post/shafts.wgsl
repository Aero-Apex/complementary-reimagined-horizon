// Light shafts, half size: march from the eye toward each pixel through the shadow
// map and gather the air the sun (or moon) reaches. Strongest looking toward the
// light, in mist, at dawn and dusk and after rain.

override light_shafts: f32 = 0.6;

fn post(input: PostInput) -> vec4<f32> {
    if light_shafts <= 0.0 || frame.has_shadow == 0u || !overworld() || frame.eye_in != 0u {
        return vec4<f32>(0.0, 0.0, 0.0, 1.0);
    }
    let d = depth_at(input.uv);
    var p = view_position(input.uv, max(d, 0.00001));
    let reach = min(frame.shadow_distance * 0.9, 96.0);
    var len = length(p);
    if d <= 0.0 || len > reach {
        p = normalize(p) * reach;
        len = reach;
    }
    let dir = p / len;
    let steps = 10;
    let step_len = len / f32(steps);
    let jitter = dither(input.pixel);
    var lit = 0.0;
    for (var i = 0; i < steps; i++) {
        let q = dir * (f32(i) + jitter) * step_len;
        let s = shadow_position(q);
        if all(s.xy > vec2<f32>(0.0)) && all(s.xy < vec2<f32>(1.0)) {
            lit += textureSampleCompareLevel(shadow_map, shadow_sampler, s.xy, s.z);
        } else {
            lit += 1.0;
        }
    }
    lit /= f32(steps);
    // Forward scattering toward the light, and a little all round.
    let mu = dot(dir, frame.light_direction);
    let g = 0.7;
    let phase = (1.0 - g * g) / pow(1.0 + g * g - 2.0 * g * mu, 1.5) * 0.08 + 0.05;
    let density = 0.35 + 1.4 * sun_low() + 1.2 * wet();
    let amount = lit * phase * density * (len / reach) * light_shafts;
    // Under a roof the air there is mostly dark: scale by the eye's sky light.
    let under = mix(0.25, 1.0, frame.eye_light_smooth.y);
    return vec4<f32>(sun_color() * amount * under, 1.0);
}
