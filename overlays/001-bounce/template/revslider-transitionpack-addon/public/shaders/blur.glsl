uniform float left;
uniform float top;
uniform float ox;
uniform float oy;
uniform float zIn;
uniform float zOut;
uniform float roz;
uniform float rEnd;
uniform bool isShort;
uniform float prange;
uniform vec4 resolution;
uniform float intensity;
uniform float progress;
uniform sampler2D src1;
uniform sampler2D src2;
varying vec2 vUv;
const int passes = 6;
float pi = 3.141592653;

vec4 getFromColor(vec2 uv) {
    return TEXTURE2D(src1, uv);
}
vec4 getToColor(vec2 uv) {
    return TEXTURE2D(src2, uv);
}

float map(float a, float b, float c, float d, float v, float cmin, float cmax) {
    return clamp((v - a) * (d - c) / (b - a) + c, cmin, cmax);
}
vec2 mirror(vec2 v) {
    vec2 m = mod(v, 2.0);
    return mix(m, 2.0 - m, step(1.0, m));
}
vec2 rotate(vec2 uv, vec2 mid, float rotation) {
    return vec2(cos(rotation) * (uv.x - mid.x) + sin(rotation) * (uv.y - mid.y) + mid.x, cos(rotation) * (uv.y - mid.y) - sin(rotation) * (uv.x - mid.x) + mid.y);
}
vec2 zoomFunction(vec2 uv, vec2 o, float z, float m) {
    uv -= o;
    uv *= 1. + z * m;
    uv += o;
    return uv;
}
void main() {
    vec2 o = vec2(ox, oy);
    vec2 uv = (vUv - vec2(0.5)) * resolution.zw + vec2(0.5);
    float ratio = resolution.x / resolution.y;
    vec4 c1 = vec4(0.0);
    vec4 c2 = vec4(0.0);
    float disp = intensity * (0.5 - distance(0.5, progress));
    float m = progress;
    float nprog = map((0.5 - prange), (0.5 + prange), 0., 1., m, 0., 1.);
    float rm = map(0., rEnd, 0., 1., m, 0., 1.);
    o.x *= ratio;
    uv.x *= ratio;
    uv = rotate(uv, o, roz * pi * progress);
    uv.x /= ratio;
    o.x /= ratio;
    vec2 uvIn = uv;
    vec2 uvOut = uv;
    if (isShort) {
        uvIn.x -= o.x * 2.;
        uvIn.y -= o.y * 2.;
    }
    float zm = sin(pi * progress);
    if (zOut != 0.) uvOut = zoomFunction(uvOut, o, max(zOut, -0.9), progress);
    if (zIn != 0.) uvIn = zoomFunction(uvIn, o, max(zIn, -0.9), 1. - progress);
    for (int xi = 0; xi < passes; xi++) {
        float x = float(xi) / float(passes) - 0.5;
        for (int yi = 0; yi < passes; yi++) {
            float y = float(yi) / float(passes) - 0.5;
            vec2 v = vec2(x, y);
            float d = disp;
            vec2 nUvOut = vec2(uvOut.x + progress * left, uvOut.y + progress * top) + d * v;
            nUvOut = mirror(nUvOut);
            vec2 nUvIn = vec2(uvIn.x + progress * left, uvIn.y + progress * top) + d * v;
            nUvIn = mirror(nUvIn);
            if (mod(left, 2.0) != 0.) nUvIn.x *= -1.;
            if (mod(top, 2.0) != 0.) nUvIn.y *= -1.;
            c1 += getFromColor(nUvOut);
            c2 += getToColor(nUvIn);
        }
    }
    c1 /= float(passes * passes);
    c2 /= float(passes * passes);
    gl_FragColor = mix(c1, c2, nprog);
}