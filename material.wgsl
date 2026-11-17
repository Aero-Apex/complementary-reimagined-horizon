// Terrain lighting in Complementary Reimagined's manner, in linear light:
//  - sun or moon light through a softly filtered shadow map, tinted where it passes
//    through water or stained glass;
//  - a sky ambient that follows the time of day, and a minimum light for caves;
//  - warm block light, coloured near the `[[lights]]` blocks (soul fire, amethyst...);
//  - light through leaves and plants (subsurface), glowing blocks and optional glowing ores;
//  - LabPBR normal and specular maps when the resource packs ship them;
//  - rain: darker, glossy ground with puddles that mirror the sky;
//  - water: depth colour, waves, a fresnel mirror (the sky, or the world with reflections
//    on) and a sun glint; lava that churns and glows.

override shadows: bool = true;
override shadow_filter: u32 = 1u;          // Off, Soft, Very soft
override sun_strength: f32 = 1.0;
override ambient_strength: f32 = 1.0;
override night_brightness: f32 = 1.0;
override min_light: f32 = 0.6;
override torch_warmth: f32 = 0.7;
override block_light_strength: f32 = 1.0;
override subsurface: bool = true;
override glowing_ores: bool = false;
override use_pbr: bool = true;
override puddles: bool = true;
override water_reflections: bool = false;
override water_clarity: f32 = 0.5;
override colored_light: f32 = 2.2;
override water_foam: bool = true;
override water_refraction: bool = true;
override water_wave_strength: f32 = 1.2;

// ---------------------------------------------------------------- shadows

const DISK: array<vec2<f32>, 8> = array<vec2<f32>, 8>(
    vec2<f32>(-0.613, 0.617), vec2<f32>(0.170, -0.040), vec2<f32>(-0.299, -0.791), vec2<f32>(0.645, 0.493),
    vec2<f32>(-0.651, -0.072), vec2<f32>(0.421, -0.638), vec2<f32>(-0.034, 0.941), vec2<f32>(0.954, -0.215),
);

// How much direct light reaches the point (rgb, tinted by translucent blocks above it).
// Past the shadow map, or without it, the sky light decides.
fn sun_light(input: MaterialInput, n: vec3<f32>, pixel: vec2<f32>) -> vec3<f32> {
    let open = smoothstep(0.6, 0.95, input.light.y);
    if !shadows || frame.has_shadow == 0u {
        return vec3<f32>(open);
    }
    let dist = length(input.position);
    let slope = 1.0 - abs(dot(n, frame.light_direction));
    let bias = frame.shadow_center_texel * (1.2 + dist * 0.035 + slope * 1.5);
    let p = shadow_position(input.position + n * bias);
    if any(p.xy < vec2<f32>(0.0)) || any(p.xy > vec2<f32>(1.0)) || p.z > 1.0 {
        return vec3<f32>(open);
    }
    var lit = 0.0;
    if shadow_filter == 3u {
        // Pixelated: snap to chunky 4x4 texel blocks, then one compare tap. The
        // comparison sampler stays the same, so lit/shadow keep their meaning.
        let size = vec2<f32>(textureDimensions(shadow_map));
        let block = 4.0;
        let snapped = (floor(p.xy * size / block) * block + block * 0.5) / size;
        lit = textureSampleCompareLevel(shadow_map, shadow_sampler, snapped, p.z);
    } else if shadow_filter == 0u {
        lit = textureSampleCompareLevel(shadow_map, shadow_sampler, p.xy, p.z);
    } else {
        let radius = select(1.6, 3.2, shadow_filter == 2u) / frame.shadow_resolution;
        let angle = dither(pixel) * 2.0 * PI;
        let rot = mat2x2<f32>(cos(angle), sin(angle), -sin(angle), cos(angle));
        var disk = DISK;
        for (var i = 0; i < 8; i++) {
            let o = rot * disk[i] * radius;
            lit += textureSampleCompareLevel(shadow_map, shadow_sampler, p.xy + o, p.z);
        }
        lit *= 0.125;
    }
    var color = vec3<f32>(lit);
    // Through water or stained glass the light takes their colour.
    if lit > 0.0 {
        let through = textureSampleCompareLevel(shadow_map_translucent, shadow_sampler, p.xy, p.z);
        if through < 0.5 {
            let size = vec2<f32>(textureDimensions(shadow_color));
            let tc = textureLoad(shadow_color, vec2<i32>(clamp(p.xy * size, vec2<f32>(0.0), size - 1.0)), 0);
            var tint = tc.rgb;
            if tc.a >= 0.999 {
                // Water: a deeper, bluer tint.
                tint = tc.rgb * vec3<f32>(0.55, 0.8, 0.95);
            } else {
                tint = mix(vec3<f32>(1.0), tc.rgb, sat(tc.a * 1.4));
            }
            color *= mix(vec3<f32>(1.0), tint, 1.0 - through);
        }
    }
    let edge = smoothstep(frame.shadow_distance * 0.75, frame.shadow_distance, dist);
    color = mix(color, vec3<f32>(open), edge);
    return color * smoothstep(0.05, 0.3, input.light.y);
}

// ---------------------------------------------------------------- pieces of light

fn torch_color(position: vec3<f32>) -> vec3<f32> {
    let warm = mix(vec3<f32>(1.0, 0.82, 0.64), vec3<f32>(1.0, 0.46, 0.16), torch_warmth);
    let c = block_light_color(position);
    // Near a `[[lights]]` block its colour leans in; plain torches are listed warm, so a
    // soul torch beside one blends with it instead of tinting the whole area.
    return mix(warm, c.rgb * 1.6, sat(c.a * 1.15));
}

fn ggx_spec(n: vec3<f32>, v: vec3<f32>, l: vec3<f32>, rough: f32) -> f32 {
    let h = normalize(v + l);
    let nh = max(dot(n, h), 0.0);
    let nl = max(dot(n, l), 0.0);
    let a = max(rough * rough, 0.002);
    let a2 = a * a;
    let d = nh * nh * (a2 - 1.0) + 1.0;
    return a2 / (PI * d * d) * nl * 0.25;
}

fn fresnel(cos_v: f32, f0: f32) -> f32 {
    return f0 + (1.0 - f0) * pow(1.0 - cos_v, 5.0);
}

// The sky a glossy surface reflects, dimmed under a roof.
fn sky_reflection(r: vec3<f32>, sky: f32) -> vec3<f32> {
    var c = sky_gradient(r);
    if !overworld() {
        c = haze_color(r) * 0.6;
    }
    return c * (0.08 + 0.92 * smoothstep(0.4, 0.95, sky));
}

// Rain puddles: 0..1 where water stands on flat, open ground.
fn puddle(input: MaterialInput, n: vec3<f32>) -> f32 {
    if !puddles || !overworld() {
        return 0.0;
    }
    let w = frame.wetness * smoothstep(0.85, 0.97, input.light.y) * smoothstep(0.7, 0.95, n.y);
    if w <= 0.0 {
        return 0.0;
    }
    let world = (input.position + frame.camera_position).xz;
    let shape = noise2(world * 0.18) * 0.65 + noise2(world * 0.55) * 0.35;
    return smoothstep(0.45, 0.62, shape) * w;
}

// ---------------------------------------------------------------- water and lava

fn water_normal(input: MaterialInput) -> vec3<f32> {
    let xz = (input.position + frame.camera_position).xz;
    let e = 0.06;
    let h = water_wave(xz);
    let hx = water_wave(xz + vec2<f32>(e, 0.0));
    let hz = water_wave(xz + vec2<f32>(0.0, e));
    // Small ripples on top of the rolling waves.
    let t = frame.time;
    let r = vec2<f32>(
        noise2(xz * 3.0 + vec2<f32>(t * 0.8, 0.0)) - 0.5,
        noise2(xz * 3.0 + vec2<f32>(0.0, t * 0.7) + 7.0) - 0.5,
    );
    let strength = 0.09 * (1.0 - 0.7 * frame.in_water);
    let g = (vec2<f32>(hx - h, hz - h) / e * strength + r * 0.04) * water_wave_strength;
    return normalize(vec3<f32>(-g.x, 1.0, -g.y));
}

fn behind_distance(input: MaterialInput) -> f32 {
    let texel = vec2<i32>(input.screen * frame.resolution);
    let d = textureLoad(opaque_depth, texel, 0);
    if d <= 0.0 {
        return 96.0;
    }
    let ndc = vec4<f32>(input.screen.x * 2.0 - 1.0, 1.0 - input.screen.y * 2.0, d, 1.0);
    let v = frame.projection_inverse * ndc;
    return max(length(v.xyz / v.w) - length(input.position), 0.0);
}

fn shade_water(input: MaterialInput, light_in: vec3<f32>, sun: vec3<f32>) -> vec4<f32> {
    let view = normalize(input.position);
    var n = input.normal;
    if input.face == 1u {
        n = water_normal(input);
    }
    if dot(n, -view) < 0.0 {
        n = -n;
    }
    let cos_v = sat(dot(n, -view));
    let f = fresnel(cos_v, 0.02);

    let thick = behind_distance(input);
    let tinted = input.albedo.rgb * input.tint.rgb;
    let shallow = tinted * vec3<f32>(0.80, 1.05, 1.00);
    let deep = tinted * vec3<f32>(0.16, 0.38, 0.58);
    var body = mix(shallow, deep, 1.0 - exp(-thick * 0.15)) * light_in;

    // Unbound-style refraction: bend the world behind the surface by its normal,
    // then let the water's depth absorb the reds and keep the blues.
    if water_refraction && input.face == 1u {
        let uv = clamp(input.screen + n.xz * 0.014 * water_wave_strength, vec2<f32>(0.001), vec2<f32>(0.999));
        let texel = vec2<i32>(uv * frame.resolution);
        let behind = textureLoad(opaque_color, texel, 0).rgb;
        let absorb = exp(-thick * 0.09) * vec3<f32>(0.78, 0.94, 1.0);
        body = mix(body, behind * absorb * (0.7 + 0.3 * light_in), 0.55 * (1.0 - f));
    }

    let r = reflect(view, n);
    var refl = sky_reflection(r, input.light.y);
    if water_reflections && frame.has_reflection == 1u {
        let uv = clamp(input.screen + n.xz * 0.03, vec2<f32>(0.001), vec2<f32>(0.999));
        let world = textureSampleLevel(reflection, reflection_sampler, uv, 0.0).rgb;
        refl = mix(refl, world, smoothstep(0.3, 0.8, input.light.y));
    }
    let glint = ggx_spec(n, -view, frame.light_direction, 0.05) * sun * sun_color() * sun_strength * 3.0;

    let clarity = mix(0.35, 0.92, 1.0 - water_clarity);
    var alpha = sat(mix(clarity * 0.6, clarity, 1.0 - exp(-thick * 0.3)) + f * 0.6);
    var col = mix(body, refl, f) + glint;

    // Foam where the surface runs over a shallow floor or meets the shore.
    if water_foam && input.face == 1u {
        let xz = (input.position + frame.camera_position).xz;
        let shore = 1.0 - smoothstep(0.15, 2.2, thick);
        let ripple = noise2(xz * 1.6 + vec2<f32>(frame.time * 0.35, 0.0)) * 0.6
                   + noise2(xz * 4.0 - vec2<f32>(frame.time * 0.2, 0.0)) * 0.4;
        let foam = shore * smoothstep(0.38, 0.62, ripple) * 0.85;
        col = mix(col, vec3<f32>(0.85, 0.95, 1.0) * (0.35 + 0.4 * light_in), foam);
        alpha = max(alpha, foam * 0.7);
    }
    return vec4<f32>(max(col, vec3<f32>(0.0)), max(alpha, f));
}

fn shade_lava(input: MaterialInput) -> vec3<f32> {
    let xz = (input.position + frame.camera_position).xz;
    let churn = noise2(xz * 0.7 + vec2<f32>(frame.time * 0.15, -frame.time * 0.1));
    let base = input.albedo.rgb * input.tint.rgb;
    return base * (2.6 + churn * 1.4);
}

// ---------------------------------------------------------------- the stage

fn material(input: MaterialInput) -> Surface {
    let pixel = input.screen * frame.resolution;
    var base = input.albedo.rgb * input.tint.rgb;
    let sky = input.light.y;
    let block = input.light.x;
    let view = normalize(input.position);

    if input.fluid == 2u {
        return Surface(vec4<f32>(shade_lava(input), input.albedo.a));
    }

    // The surface's normal: LabPBR's where there is one.
    var n = input.normal;
    var smooth_ = 0.0;
    var f0 = 0.04;
    var pbr_emission = 0.0;
    var porosity = 0.0;
    if use_pbr && block_pbr_maps() && input.fluid == 0u {
        let nm = block_normal_map(input.uv);
        let sm = block_specular_map(input.uv);
        var t = nm.xy * 2.0 - 1.0;
        let tz = sqrt(sat(1.0 - dot(t, t)));
        let bitangent = cross(input.normal, input.tangent.xyz) * input.tangent.w;
        n = normalize(input.tangent.xyz * t.x + bitangent * t.y + input.normal * tz);
        smooth_ = sm.r;
        f0 = select(sm.g, 0.9, sm.g > 0.9);
        porosity = select(0.0, sm.b, sm.b < 0.25);
        pbr_emission = select(sm.a, 0.0, sm.a >= 0.999);
    }

    let sun = sun_light(input, n, pixel);
    let foliage = input.material == 1u || input.material == 2u;
    var ndl = dot(n, frame.light_direction);
    if foliage {
        // Leaves and plants are lit from both sides.
        ndl = abs(ndl) * 0.6 + 0.4;
    }
    ndl = max(ndl, 0.0);

    // Direct light.
    var direct = sun_color() * sun * ndl * 1.65 * sun_strength;
    if subsurface && foliage && overworld() {
        // Light shining through the leaves toward the eye.
        let through = pow(max(dot(view, frame.light_direction), 0.0), 6.0);
        direct += sun_color() * sun * through * 1.4 * sun_strength * select(0.6, 1.0, input.material == 1u);
    }

    // Sky ambient, a floor for caves, and night vision.
    var ambient = ambient_color() * ambient_strength * (sky * sky * (3.0 - 2.0 * sky));
    if overworld() {
        ambient += vec3<f32>(0.010, 0.014, 0.030) * (1.0 - daylight()) * night_brightness * sky;
    }
    let floor_light = vec3<f32>(0.0035, 0.0038, 0.0045) * min_light * 3.0;
    let vision = vec3<f32>(0.32 * frame.night_vision);

    // Block light: a soft core and a long, faint reach.
    let torch = torch_color(input.position) * (pow(block, 3.4) * 1.6 + pow(block, 1.6) * 0.1) * block_light_strength;

    let light = direct + ambient + floor_light + vision + torch + input.colored_light * colored_light;

    if input.fluid == 1u {
        return Surface(shade_water(input, light, sun));
    }

    // Rain darkens and glosses open ground, and fills puddles.
    let wet_here = select(0.0, frame.wetness * smoothstep(0.85, 0.97, sky), overworld());
    let p = puddle(input, n);
    if wet_here > 0.0 {
        base *= 1.0 - 0.35 * wet_here * (1.0 - porosity);
        smooth_ = max(smooth_, wet_here * 0.55);
        smooth_ = mix(smooth_, 0.97, p);
        n = normalize(mix(n, input.normal, p));
    }
    var col = base * light;

    // Glowing blocks: emission from the block, the specular map, or bright ore spots.
    var glow = max(input.emission, pbr_emission);
    if glowing_ores && input.material == 4u {
        let a = input.albedo.rgb;
        let spot = smoothstep(0.12, 0.35, max(a.r, max(a.g, a.b)) - min(a.r, min(a.g, a.b)));
        glow = max(glow, spot * 0.55);
    }
    col += base * glow * glow * 3.0;

    // Gloss: the sun's highlight and the sky's reflection.
    if smooth_ > 0.05 {
        let rough = 1.0 - smooth_;
        let cos_v = sat(dot(n, -view));
        let f = fresnel(cos_v, f0) * smooth_;
        let r = reflect(view, n);
        col = mix(col, sky_reflection(r, sky), f * 0.8);
        col += sun_color() * sun * ggx_spec(n, -view, frame.light_direction, rough) * smooth_ * sun_strength;
    }

    if !input.translucent {
        set_surface(n, smooth_, glow);
    }
    return Surface(vec4<f32>(max(col, vec3<f32>(0.0)), input.albedo.a));
}
