// Ambient occlusion, step 1 (half size): how much nearby geometry hides each point
// of solid terrain from the sky, from the depth buffer and the normals the material
// stage stored. 1 open, 0 enclosed.

override ambient_occlusion: bool = true;
override ao_strength: f32 = 1.0;

const AO_DIRS: array<vec3<f32>, 8> = array<vec3<f32>, 8>(
    vec3<f32>(0.53, 0.30, 0.20), vec3<f32>(-0.42, 0.55, 0.31), vec3<f32>(0.11, -0.37, 0.62), vec3<f32>(-0.66, -0.21, 0.40),
    vec3<f32>(0.28, 0.71, 0.55), vec3<f32>(-0.15, -0.68, 0.25), vec3<f32>(0.77, -0.12, 0.48), vec3<f32>(-0.31, 0.12, 0.85),
);

fn post(input: PostInput) -> vec4<f32> {
    if !ambient_occlusion {
        return vec4<f32>(1.0);
    }
    let d = depth_at(input.uv);
    if d <= 0.0 {
        return vec4<f32>(1.0);
    }
    let size = vec2<f32>(textureDimensions(scene_depth));
    let s = surface_at(vec2<i32>(input.uv * size));
    if !s.present {
        return vec4<f32>(1.0);
    }
    let p = view_position(input.uv, d);
    let dist = length(p);
    if dist > 64.0 {
        return vec4<f32>(1.0);
    }
    let n = s.normal;
    // A tangent frame around the normal, turned per pixel.
    let up = select(vec3<f32>(0.0, 1.0, 0.0), vec3<f32>(1.0, 0.0, 0.0), abs(n.y) > 0.9);
    let t = normalize(cross(up, n));
    let b = cross(n, t);
    let a = dither(input.pixel) * 2.0 * PI;
    let ca = cos(a);
    let sa = sin(a);
    let radius = 0.6 + dist * 0.01;
    var dirs = AO_DIRS;
    var occ = 0.0;
    for (var i = 0; i < 8; i++) {
        let k = dirs[i];
        let kx = k.x * ca - k.y * sa;
        let ky = k.x * sa + k.y * ca;
        let scale = mix(0.2, 1.0, f32(i + 1) / 8.0);
        let q = p + (t * kx + b * ky + n * k.z) * radius * scale + n * 0.02;
        let clip = frame.projection * frame.view * vec4<f32>(q, 1.0);
        if clip.w <= 0.0 {
            continue;
        }
        let ndc = clip.xyz / clip.w;
        let uv = vec2<f32>(ndc.x * 0.5 + 0.5, 0.5 - ndc.y * 0.5);
        if any(uv < vec2<f32>(0.0)) || any(uv > vec2<f32>(1.0)) {
            continue;
        }
        let sd = depth_at(uv);
        // Reversed depth: larger is nearer. Occluded if the scene is in front of the sample.
        if sd > ndc.z {
            let sp = view_position(uv, sd);
            let gap = length(q) - length(sp);
            occ += smoothstep(0.0, 0.05, gap) * (1.0 - smoothstep(radius, radius * 2.5, gap));
        }
    }
    let ao = 1.0 - occ / 8.0 * 0.85 * ao_strength;
    return vec4<f32>(vec3<f32>(sat(ao)), 1.0);
}
