// Rain and snow: rain is a pale blue-grey streak, lit by the sky above it and by
// nearby torches; snow stays white. Both fade under a roof.

fn weather(input: WeatherInput) -> vec4<f32> {
    let sky = input.light.y;
    let block = input.light.x;
    let lit = ambient_color() * 2.2 * sky + sun_color() * 0.35 * sky + vec3<f32>(1.0, 0.6, 0.3) * pow(block, 3.0) * 0.8;
    if input.snow {
        let c = vec3<f32>(1.0) * (lit + vec3<f32>(0.02));
        return vec4<f32>(c, input.color.a * 0.85);
    }
    let rain = lin(vec3<f32>(0.70, 0.80, 0.95)) * (lit + vec3<f32>(0.015));
    return vec4<f32>(rain, input.color.a * 0.5);
}
