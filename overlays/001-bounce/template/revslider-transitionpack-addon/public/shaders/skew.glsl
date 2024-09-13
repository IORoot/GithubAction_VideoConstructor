uniform float left;
uniform float top;
uniform int dir;
uniform float intensity;
uniform float origin;
uniform bool sh;
uniform float shx;
uniform float shy;
uniform float shr;
uniform float shz;
uniform float shv;
uniform float prange;
uniform float progress;
uniform vec4 resolution;
uniform sampler2D src1;
uniform sampler2D src2;
varying vec2 vUv;
float pi = 3.141592653;
float map(float a, float b, float c, float d, float v) {
    return clamp((v - a) * (d - c) / (b - a) + c, 0., 1.);
}
vec2 mirror(vec2 v) {
    vec2 m = mod(v, 2.0);
    return mix(m, 2.0 - m, step(1.0, m));
}
vec2 rotateUV(vec2 uv, float rotation, vec2 mid) {
    return vec2(cos(rotation) * (uv.x - mid.x) + sin(rotation) * (uv.y - mid.y) + mid.x, cos(rotation) * (uv.y - mid.y) - sin(rotation) * (uv.x - mid.x) + mid.y);
}
vec2 getAngle(vec2 p1) {
    return vec2(.5, .5) * normalize(p1);
}
float qinticOut(float t, float power) {
    return 1.0 - pow(1. - t, power);
}
float elasticOut(float t) {
    return sin(13.0 * t * pi / shv) * pow(5.5, 3. * (t - 1.0));
}
vec2 shake(vec2 uv, float p, float shx, float shy, float tilt, float z) {
    float m = elasticOut(p);
    float n = (1. - p) * p;
    if (tilt != 0.) {
        float tmc = (1. - m) * m * n;
        uv = rotateUV(uv, tmc * tilt, vec2(.5, .5));
    }
    if (z != 0.) {
        p = p * p;
        uv.x -= 0.5;
        uv.y -= 0.5;
        uv *= (z * p * n + 1.);
        uv.x += 0.5;
        uv.y += 0.5;
    }
    if (shx != 0. && shy != 0.) {
        uv.x += m * shx * 2. * n;
        uv.y -= m * (1. - m) * shy * n;
    }
    return uv;
}
void main() {
    vec2 uv = vUv;
    vec2 vw = uv;
    vec2 vwo = vw;
    float m = progress;
    float steps = 1.0 / (max(abs(left), abs(top)) + 2.);
    float ms = m;
    if (sh) ms = qinticOut(m, 10.);
    float flip = (m - 0.5) * 2.;
    float mult = sin(ms * pi);
    mult = min(mult, 0.5);
    if (dir == 1 || dir == 2) mult /= 10.;
    if (dir == 1) {
        float shift = origin <= 0.5 ? uv.y - origin : origin - uv.y;
        float shift2 = origin == 0. || origin == 1. ? 1. : origin;
        vw.x += sign(left) * mix(shift, shift - 1., ms) * intensity;
    } else if (dir == 2) {
        float shift = origin <= 0.5 ? uv.x - origin : origin - uv.x;
        float shift2 = origin == 0. || origin == 1. ? 1. : origin;
        vw.y += sign(top) * mix(shift, shift - shift2, ms) * intensity;
    } else {
        vec2 d1 = getAngle(vec2(0.5 * top, 0.5 * left));
        vec2 d2 = getAngle(vec2(0.5 * top, 0.5 * left));
        float l1 = length(vec2(left > 0. ? 1. - uv.x : uv.x, top > 0. ? 1. - uv.y : uv.y));
        float l2 = length(vec2(left > 0. ? uv.x : 1. - uv.x, top > 0. ? uv.y : 1. - uv.y));
        vec2 a = vw + l1 * d1 * flip * (step(top * left, 0.) - 0.5) * intensity;
        vec2 b = vw + l2 * d2 * flip * (step(top * left, 0.) - 0.5) * intensity;
        vw = mix(a, b, ms);
    }
    uv = mix(vwo, vw, mult);
    if (sh) uv = shake(uv, 1. - m, shx, shy, shr, shz);
    vec2 nUv = vec2(uv.x + ms * left, uv.y + ms * top);
    nUv = mirror(nUv);
    vec2 nUvIn = nUv;
    if (mod(left, 2.0) != 0.) nUvIn.x *= -1.;
    if (mod(top, 2.0) != 0.) nUvIn.y *= -1.;
    float nprog = map((0.5 - prange), (0.5 + prange), 0., 1., ms);
    vec4 col = mix(TEXTURE2D(src1, nUv), TEXTURE2D(src2, nUvIn), nprog);
    gl_FragColor = col;
}