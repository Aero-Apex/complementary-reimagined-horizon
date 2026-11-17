// The sky: a gradient that deepens at the zenith and burns warm toward a low sun,
// a glare around the sun and the moon, and the pack's own soft clouds in two
// layers (the manifest turns vanilla's off). Vanilla draws the sun, moon and stars
// over the result. The Nether keeps vanilla's colour; the End gets a dark violet
// sky with a faint aurora.

override cloud_amount: f32 = 0.5;
override cloud_height: f32 = 192.0;
override high_clouds: bool = true;

fn fbm(p: vec2<f32>) -> f32 {
    var v = 0.0;
    var a = 0.5;
    var q = p;
    for (var i = 0; i < 4; i++) {
        v += noise2(q) * a;
        q = q * 2.03 + vec2<f32>(17.1, 9.2);
        a *= 0.5;
    }
    return v;
}

// One cloud layer at world height `h`: colour (premultiplied) and coverage.
fn cloud_layer(d: vec3<f32>, h: f32, scale: f32, cover: f32, speed: f32, soft: f32) -> vec4<f32> {
    let cam = frame.camera_position;
    let rel = h - cam.y;
    if abs(d.y) < 0.002 || rel / d.y <= 0.0 {
        return vec4<f32>(0.0);
    }
    let t = rel / d.y;
    let p = cam.xz + d.xz * t;
    let drift = vec2<f32>(frame.time * speed, frame.time * speed * 0.35);
    let n = fbm((p + drift) * scale);
    let edge = 1.0 - cover;
    var a = smoothstep(edge, edge + soft, n);
    // Fade with distance so the layer meets the horizon softly.
    a *= 1.0 - smoothstep(1200.0, 4200.0, t);
    if a <= 0.001 {
        return vec4<f32>(0.0);
    }
    // Light: brighter where the cloud is thin and on the side facing the sun.
    let thick = smoothstep(edge, 1.0, n);
    let toward_sun = pow(max(dot(d, frame.sun_direction), 0.0), 6.0);
    let lit = sun_color() * (0.9 + 1.4 * toward_sun) * (1.0 - 0.45 * thick);
    let amb = ambient_color() * 1.6 + sky_zenith() * 0.6;
    var c = lit + amb;
    c = mix(c, vec3<f32>(lum(c)) * 0.7, wet() * 0.7);
    return vec4<f32>(c * a, a);
}

fn end_sky(d: vec3<f32>) -> vec3<f32> {
    var col = lin(vec3<f32>(0.035, 0.022, 0.05));
    let up = sat(d.y * 0.5 + 0.5);
    col += lin(vec3<f32>(0.18, 0.10, 0.26)) * pow(up, 3.0) * 0.4;
    // A slow aurora-like band.
    let w = d.xz / max(abs(d.y) + 0.3, 0.3);
    let n = fbm(w * 1.4 + vec2<f32>(frame.time * 0.02, 0.0));
    col += lin(vec3<f32>(0.45, 0.25, 0.70)) * smoothstep(0.55, 0.85, n) * 0.25 * smoothstep(0.0, 0.4, d.y);
    return col;
}

fn sky(input: SkyInput) -> vec4<f32> {
    let d = input.direction;
    if the_end() {
        return vec4<f32>(end_sky(d), input.color.a);
    }
    if !overworld() || frame.eye_in == 1u || frame.eye_in == 2u {
        return input.color;
    }

    var col = sky_gradient(d);

    // Glare: a wide warm halo and a tight bright one around the sun; a pale one round the moon.
    let day = daylight();
    let cs = max(dot(d, frame.sun_direction), 0.0);
    col += sun_color() * (pow(cs, 8.0) * 0.12 + pow(cs, 90.0) * 0.6) * smoothstep(-0.1, 0.05, frame.sun_direction.y);
    let cm = max(dot(d, frame.moon_direction), 0.0);
    col += lin(vec3<f32>(0.32, 0.40, 0.60)) * (pow(cm, 20.0) * 0.05 + pow(cm, 200.0) * 0.15) * (1.0 - day);

    // Clouds: a low cumulus layer and thin high streaks.
    if cloud_amount > 0.0 {
        let low = cloud_layer(d, cloud_height, 0.006, cloud_amount * 0.8, 1.6, 0.18);
        col = col * (1.0 - low.a * 0.92) + low.rgb * 0.92;
        if high_clouds {
            let hi = cloud_layer(d, cloud_height + 220.0, 0.0018, cloud_amount * 0.6, 3.0, 0.3);
            col = col * (1.0 - hi.a * 0.5) + hi.rgb * 0.5;
        }
    }

    // Near the horizon the sky settles into the haze.
    let haze = 1.0 - smoothstep(0.0, 0.12, abs(d.y));
    col = mix(col, haze_color(d), haze * 0.3);
    return vec4<f32>(max(col, vec3<f32>(0.0)), input.color.a);
}
