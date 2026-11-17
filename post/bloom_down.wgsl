// Bloom, step 1 (quarter size): the bright parts of the picture (the sun, lava,
// torches, glowing blocks), averaged over a 4x4 block.

override bloom: f32 = 0.15;

fn bright(c: vec3<f32>) -> vec3<f32> {
    let l = lum(c);
    return c * smoothstep(0.75, 2.0, l);
}

fn post(input: PostInput) -> vec4<f32> {
    if bloom <= 0.0 {
        return vec4<f32>(0.0, 0.0, 0.0, 1.0);
    }
    let px = 1.0 / vec2<f32>(textureDimensions(previous));
    var sum = vec3<f32>(0.0);
    sum += bright(textureSampleLevel(previous, linear_sampler, input.uv + px * vec2<f32>(-1.0, -1.0), 0.0).rgb);
    sum += bright(textureSampleLevel(previous, linear_sampler, input.uv + px * vec2<f32>(1.0, -1.0), 0.0).rgb);
    sum += bright(textureSampleLevel(previous, linear_sampler, input.uv + px * vec2<f32>(-1.0, 1.0), 0.0).rgb);
    sum += bright(textureSampleLevel(previous, linear_sampler, input.uv + px * vec2<f32>(1.0, 1.0), 0.0).rgb);
    // The open day sky is bright everywhere: it glows only a little.
    let sky = select(1.0, 0.25, depth_at(input.uv) <= 0.0);
    return vec4<f32>(sum * 0.25 * sky, 1.0);
}
