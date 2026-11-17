// Waving: leaves sway, plants bend at their tops, and the water's surface rolls.
// The shadow map moves with them. Shares the material stage's module.

override waving_plants: bool = true;
override waving_water: bool = true;

fn wind() -> f32 {
    return 1.0 + wet() * 1.2;
}

fn sway(world: vec3<f32>, speed: f32, size: f32) -> vec3<f32> {
    let t = frame.time * speed;
    let phase = dot(world, vec3<f32>(0.73, 0.21, 0.57));
    let x = sin(t + phase) + 0.4 * sin(t * 2.3 + phase * 1.7);
    let z = cos(t * 0.9 + phase * 1.3) + 0.4 * sin(t * 1.7 + phase * 0.9);
    return vec3<f32>(x, 0.0, z) * size * wind();
}

// The surface's height offset at world xz, shared with the material's water normal.
fn water_wave(xz: vec2<f32>) -> f32 {
    let t = frame.time;
    var h = sin(dot(xz, vec2<f32>(0.9, 0.4)) * 1.1 + t * 1.2) * 0.5;
    h += sin(dot(xz, vec2<f32>(-0.5, 0.85)) * 1.7 + t * 1.6) * 0.3;
    h += sin(dot(xz, vec2<f32>(0.2, -0.95)) * 2.9 + t * 2.1) * 0.2;
    return h;
}

fn vertex(input: VertexInput) -> vec3<f32> {
    var p = input.position;
    let world = p + frame.camera_position;
    // Only out in the open: nothing waves deep in a cave.
    let open = smoothstep(0.3, 0.9, input.light.y);
    if waving_plants && input.material == 1u {
        p += sway(world, 1.4, 0.035) * open;
    } else if waving_plants && input.material == 2u {
        // Tops move, roots stay: the sprite's top has the smaller v.
        let top = 1.0 - fract(input.uv.y);
        p += sway(world, 1.9, 0.08) * top * open;
    } else if waving_water && input.fluid == 1u && input.face == 1u {
        p.y += (water_wave(world.xz) - 0.6) * 0.035 * (0.6 + 0.4 * open);
    }
    return p;
}
