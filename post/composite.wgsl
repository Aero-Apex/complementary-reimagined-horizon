// The world's picture, finished: ambient occlusion laid on (gently, and less on
// glowing things), the light shafts added (smoothed up from half size), and a soft
// aerial haze that pulls far terrain toward the sky's colour.

override ambient_occlusion: bool = true;
override haze: f32 = 0.5;

fn soft(t: texture_2d<f32>, uv: vec2<f32>) -> vec3<f32> {
    let px = 1.0 / vec2<f32>(textureDimensions(t));
    var c = textureSampleLevel(t, linear_sampler, uv + px * vec2<f32>(-0.75, -0.75), 0.0).rgb;
    c += textureSampleLevel(t, linear_sampler, uv + px * vec2<f32>(0.75, -0.75), 0.0).rgb;
    c += textureSampleLevel(t, linear_sampler, uv + px * vec2<f32>(-0.75, 0.75), 0.0).rgb;
    c += textureSampleLevel(t, linear_sampler, uv + px * vec2<f32>(0.75, 0.75), 0.0).rgb;
    return c * 0.25;
}

fn post(input: PostInput) -> vec4<f32> {
    var c = input.color.rgb;
    let d = input.depth;

    if ambient_occlusion && d > 0.0 {
        let occlusion = soft(t_ao, input.uv).r;
        let size = vec2<f32>(textureDimensions(scene_depth));
        let s = surface_at(vec2<i32>(input.uv * size));
        // Glowing surfaces (the material stored their glow) keep their light.
        let keep = select(0.0, sat(s.data * 2.0), s.present);
        c *= mix(occlusion, 1.0, keep);
    }

    if d > 0.0 && haze > 0.0 && frame.eye_in == 0u {
        let p = view_position(input.uv, d);
        let dist = length(p);
        var density = 0.0;
        if overworld() {
            // Thicker low down and after rain; thin by a clear noon.
            let height = (p.y + frame.camera_position.y - 62.0) / 80.0;
            density = (0.0009 + 0.0035 * wet() + 0.0012 * sun_low()) * exp(-max(height, 0.0) * 1.5);
        } else if nether() {
            density = 0.006;
        } else if the_end() {
            density = 0.002;
        }
        let f = (1.0 - exp(-dist * density * haze * 2.0)) * smoothstep(0.0, 24.0, dist);
        c = mix(c, haze_color(p / max(dist, 0.001)), f);
    }

    c += soft(t_shafts, input.uv);
    return vec4<f32>(max(c, vec3<f32>(0.0)), 1.0);
}
