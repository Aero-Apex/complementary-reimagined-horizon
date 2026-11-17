// The tone curve: Lottes' filmic curve (2016), which keeps mid-tones natural and
// rolls bright light off softly, with an exposure that opens up in caves and at
// night as the eye adjusts. On an HDR display the highlights keep climbing past
// paper white up to the display's headroom.

override exposure: f32 = 1.0;
override auto_exposure: bool = true;

fn lottes(x: vec3<f32>) -> vec3<f32> {
    let a = 1.6;
    let d = 0.977;
    let hdr_max = 8.0;
    let mid_in = 0.18;
    let mid_out = 0.267;
    let pa = pow(hdr_max, a);
    let pad = pow(hdr_max, a * d);
    let ma = pow(mid_in, a);
    let mad = pow(mid_in, a * d);
    let b = (-ma + pa * mid_out) / ((pad - mad) * mid_out);
    let c = (pad * ma - pa * mad * mid_out) / ((pad - mad) * mid_out);
    let xa = pow(max(x, vec3<f32>(0.0)), vec3<f32>(a));
    let xad = pow(max(x, vec3<f32>(0.0)), vec3<f32>(a * d));
    return xa / (xad * b + c);
}

fn tonemap(input: TonemapInput) -> vec3<f32> {
    var e = exposure;
    if auto_exposure {
        // Darker surroundings open the eye up, by up to two thirds of a stop.
        let sky = frame.eye_light_smooth.y;
        let block = frame.eye_light_smooth.x;
        let dark = (1.0 - sky * mix(0.4, 1.0, daylight())) * (1.0 - block * 0.6);
        e *= 1.0 + 0.45 * sat(dark);
    }
    let c = input.color * e;
    var m = lottes(c);
    if frame.hdr == 1u && frame.headroom > 1.0 {
        // Above about 80% the curve lifts toward the display's peak instead of flattening.
        let over = smoothstep(vec3<f32>(0.8), vec3<f32>(1.0), m);
        m = m * mix(vec3<f32>(1.0), vec3<f32>(frame.headroom), over * 0.6);
    }
    return clamp(m, vec3<f32>(0.0), vec3<f32>(frame.headroom));
}
