const int Samples = 32;
float warp = 2.;
float mapPow = .5;
const float power = 9.0;
uniform float ox;
uniform float oy;
uniform float zIn;
uniform float zOut;
uniform float warpIn;
uniform float warpOut;
uniform float blur;
uniform float roz;
uniform float rEnd;
uniform bool isShort;
uniform float prange;
uniform float progress;
uniform vec4 resolution;
uniform sampler2D src1;
uniform sampler2D src2;
varying vec2 vUv;
float pi = 3.141592653;
vec2 mirror(vec2 v) {
    vec2 m = mod(v, 2.0);
    return mix(m, 2.0 - m, step(1.0, m));
}
float map(float a, float b, float c, float d, float v, float cmin, float cmax) {
    return clamp((v - a) * (d - c) / (b - a) + c, cmin, cmax);
}
float map(float a, float b, float c, float d, float v) {
    return (v - a) * (d - c) / (b - a) + c;
}
float powerOut(float t) {
    return 1.0 - pow(1.0 - t, power);
}
float mapToEase(float a, float b, float v, float z) {
    return powerOut(map(a, b, 0., 1., v)) / (warp);
}
vec4 rayBlur(vec2 uv, vec2 uvo, vec2 o, float m, float nprog) {
    vec2 dirOut = mix(uvo, uv, step(zOut, 0.)) - o;
    vec2 dirIn = mix(uv, uvo, step(zIn, 0.)) - o;
    float bm = sin(pi * m);
    float Blur = blur != 0. ? blur * bm * max(zOut, -.9) : 0.;
    float iBlur = blur != 0. ? blur * bm * max(zIn, -.9) : 0.;
    if (isShort) {
        uvo.x -= o.x * 2.;
        uvo.y -= o.y * 2.;
    }
    vec4 color = vec4(0.);
    for (int i = 0; i < Samples; i += 2) {
        color += mix(TEXTURE2D(src1, mirror(uv + float(i) / float(Samples) * dirOut * Blur)), TEXTURE2D(src2, mirror(uvo + float(i) / float(Samples) * dirIn * iBlur)), nprog);
        color += mix(TEXTURE2D(src1, mirror(uv + float(i + 1) / float(Samples) * dirOut * Blur)), TEXTURE2D(src2, mirror(uvo + float(i + 1) / float(Samples) * dirIn * iBlur)), nprog);
    }
    return color / float(Samples);
}
vec2 hitEffect(vec2 uv, vec2 o, float m, sampler2D t, float z, bool animOut) {
    z = max(z, -0.9);
    m = 1. - sin(pi * m);
    float dist = distance(o, uv);
    float angle = atan(uv.y - o.y, uv.x - o.x);
    vec2 uvo = uv;
    dist = mix(mapToEase(0., pow(animOut ? warpOut : warpIn, mapPow), dist, z), dist, m);
    uv.x = o.x + cos(angle) * dist;
    uv.y = o.y + sin(angle) * dist;
    uv = mix(uv, uvo, m);
    return uv;
}
vec2 zoom(vec2 uv, vec2 o, float z, float m) {
    uv -= o;
    uv *= 1. + z * m;
    uv += o;
    return uv;
}
vec2 rotate(vec2 uv, vec2 mid, float rotation) {
    return vec2(cos(rotation) * (uv.x - mid.x) + sin(rotation) * (uv.y - mid.y) + mid.x, cos(rotation) * (uv.y - mid.y) - sin(rotation) * (uv.x - mid.x) + mid.y);
}
void main() {
    vec2 o = vec2(ox, oy);
    vec2 uv = vUv;
    float ratio = resolution.x / resolution.y;
    float m = progress;
    float nprog = map((0.5 - prange), (0.5 + prange), 0., 1., m, 0., 1.);
    float rm = map(0., rEnd, 0., 1., m, 0., 1.);
    o.x *= ratio;
    uv.x *= ratio;
    uv = rotate(uv, o, roz * pi * rm);
    uv.x /= ratio;
    o.x /= ratio;
    vec2 uvo = uv;
    vec2 uvz = uv;
    if (warpOut != 0.) uv = hitEffect(uv, o, 1. - m, src1, zOut, true);
    if (warpIn != 0.) uvo = hitEffect(uvo, o, m, src2, zIn, false);
    if (zOut != 0.) uv = zoom(uv, o, max(zOut, -0.9), m);
    if (zIn != 0.) uvo = zoom(uvo, o, max(zIn, -0.9), 1. - m);
    gl_FragColor = rayBlur(uv, uvo, o, m, nprog);
}