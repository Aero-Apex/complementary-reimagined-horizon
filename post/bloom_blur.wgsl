// Bloom, step 2 (quarter size): a wide, soft blur of the bright parts.

override bloom: f32 = 0.15;

fn post(input: PostInput) -> vec4<f32> {
    if bloom <= 0.0 {
        return vec4<f32>(0.0, 0.0, 0.0, 1.0);
    }
    let px = 1.0 / vec2<f32>(textureDimensions(t_bloom_a));
    var sum = vec3<f32>(0.0);
    var weight = 0.0;
    for (var y = -2; y <= 2; y++) {
        for (var x = -2; x <= 2; x++) {
            let o = vec2<f32>(f32(x), f32(y));
            let w = exp(-dot(o, o) * 0.25);
            sum += textureSampleLevel(t_bloom_a, linear_sampler, input.uv + o * px * 1.5, 0.0).rgb * w;
            weight += w;
        }
    }
    return vec4<f32>(sum / weight, 1.0);
}
