uniform float roz;
uniform float ox;
uniform float oy;
uniform bool isShort;
uniform float iny;
uniform float Splits;
uniform float s;
uniform vec4 iColor;
uniform bool cnprog;
uniform bool useo;
uniform float grado;
uniform bool cover;
uniform bool altDir;
uniform float prange;
uniform float progress;
uniform vec4 resolution;
uniform sampler2D src1;
uniform sampler2D src2;
varying vec2 vUv;
float pi = 3.141592653;
float map(float a, float b, float c, float d, float v, float cmin, float cmax) {
    return clamp((v - a) * (d - c) / (b - a) + c, cmin, cmax);
}
vec2 rotate2D(vec2 p, float theta) {
    return p * mat2(cos(theta), -sin(theta), sin(theta), cos(theta));
}
vec2 mirror(vec2 v) {
    vec2 m = mod(v, 2.0);
    return mix(m, 2.0 - m, step(1.0, m));
}
vec2 rotateUV(vec2 uv, float rotation, vec2 mid) {
    return vec2(cos(rotation) * (uv.x - mid.x) + sin(rotation) * (uv.y - mid.y) + mid.x, cos(rotation) * (uv.y - mid.y) - sin(rotation) * (uv.x - mid.x) + mid.y);
}
vec4 cutPart(float m, float amount, vec2 uv, float minv, float maxv, float ratio, float i, float ox, float oy, float nprog) {
    if (cover) {
        minv = minv * ratio;
        maxv = maxv * ratio;
    }
    float offsmax = (Splits - 1.) / Splits;
    float offset = (Splits - i - 1.) / Splits;
    m = map((offsmax - offset) / iny, 1. - offset / iny, 0., 1., m, 0., 1.);
    float zm = sin(pi * pow(m, 2.));
    float cm = min(sin(pi * m), 0.3) / 0.3;
    float mult = sin(m * pi);
    vec4 c = vec4(0., 0., 0., 0.);
    if (cnprog) nprog = map((offsmax - offset) / max(iny / 2.5, 1.), 1. - offset / max(iny / 2.5, 1.), 0., 1., m, 0., 1.);
    float dir = altDir ? sign(mod(i, 2.0) - 0.5) : 1.;
    ox *= ratio;
    uv.x *= ratio;
    uv = rotateUV(uv, (m * amount + -sign(amount) * mult * 1. * (Splits - i) / Splits) * dir, vec2(ox, oy));
    float d = length(uv - vec2(ox, oy));
    uv.x /= ratio;
    uv *= (1. - zm * 1. * i / Splits);
    vec2 cUv = uv;
    if (isShort) {
        cUv.x -= ox / ratio * 2.;
        cUv.y -= oy * 2.;
    }
    cUv = mirror(cUv);
    uv = mirror(uv);
    float a = smoothstep(minv, minv + 0.005, d);
    float b = 1. - smoothstep(maxv, maxv + 0.005, d);
    if (minv == 0.) a = step(minv, d);
    if (maxv >= 1. * (cover ? ratio : 1.)) b = step(minv, d);
    vec4 tex = mix(TEXTURE2D(src1, uv), TEXTURE2D(src2, cUv), nprog);
    vec4 color = vec4(0.);
    if (useo || s != 0.) {
        color = iColor;
        float sh = 1. - smoothstep(minv, minv + (maxv - minv) * s, d);
        float ol = grado == 1. || grado == 2. ? 1. : mod(i, 2.);
        float gol = grado == 1. ? (Splits - i - 1.) / Splits : grado == 2. ? i / Splits : 1.;
        if (minv <= 0.) sh = 0.;
        if (useo && ol != 0.) sh = 1.;
        if (ol * (a * b) != 0. || s != 0.) tex.rgb = mix(tex, color, color.a * sh * gol * cm).rgb;
    }
    vec4 f = vec4(0.);
    return mix(f, tex, a * b);
}
void main() {
        float amount = roz * pi;
        vec2 uv = vUv;
        float ratio = resolution.x / resolution.y;
        float m = progress;
        m = map(0., 0.999, 0., 1., m, 0., 1.);
        float nprog = map((0.5 - prange), (0.5 + prange), 0., 1., m, 0., 1.);
        vec4 color = vec4(0.);
        for (int i = 0; i < splits; i++) {
            float min = float(i) / Splits;
            float max = float(i) / Splits + 1. / Splits;
            color += cutPart(m, amount, uv, min, max, ratio, float(i), ox, oy, nprog);
        }
        gl_FragColor = color;
}