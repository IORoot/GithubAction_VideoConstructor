uniform float ox;
uniform float oy;
uniform float rotation;
uniform bool isShort;
uniform float intensity;
uniform float angle;
uniform float prange;
uniform float progress;
uniform vec4 resolution;
uniform sampler2D src1;
uniform sampler2D src2;
varying vec2 vUv;
float pi = 3.141592653;
vec2 rotate(vec2 uv, vec2 mid, float rotation) {
    return vec2(cos(rotation) * (uv.x - mid.x) + sin(rotation) * (uv.y - mid.y) + mid.x, cos(rotation) * (uv.y - mid.y) - sin(rotation) * (uv.x - mid.x) + mid.y);
}
float map(float a, float b, float c, float d, float v, float cmin, float cmax) {
    return clamp((v - a) * (d - c) / (b - a) + c, cmin, cmax);
}
vec2 plane3d(vec2 uv, vec2 center, float xr, float yr) {
    vec2 rd = vec2(uv.x, 0.);
    vec2 a1 = vec2(0., -1.);
    vec2 b1 = rd - a1;
    vec2 c1 = rotate(vec2(-1., 0.), vec2(center.x, 0.), yr);
    vec2 d1 = rotate(vec2(1., 0.), vec2(center.x, 0.), yr) - c1;
    float u = ((c1.y + 1.) * d1.x - c1.x * d1.y) / (d1.x * b1.y - d1.y * b1.x);
    float sx = u * b1.x;
    float sy = u * uv.y;
    rd = vec2(sy, 0.);
    vec2 b2 = rd - a1;
    vec2 c2 = rotate(vec2(-1., 0.), vec2(center.y, 0.), xr);
    vec2 d2 = rotate(vec2(1., 0.), vec2(center.y, 0.), xr) - c2;
    float v = ((c2.y + 1.) * d2.x - c2.x * d2.y) / (d2.x * b2.y - d2.y * b2.x);
    return vec2(v * sx, v * b2.x);
}
vec2 rotatePlane(vec2 uv, vec2 o, float rx, float ry) {
    uv = uv * 2. - 1.;
    uv = plane3d(uv, o, rx, ry);
    uv = (1. + uv) / 2.;
    return uv;
}
float map(float a, float b, float c, float d, float v) {
    return clamp((v - a) * (d - c) / (b - a) + c, 0., 1.);
}
vec2 mirror(vec2 v) {
    vec2 m = mod(v, 2.0);
    return mix(m, 2.0 - m, step(1.0, m));
}
vec2 zoom(vec2 uv, float p, float z) {
    float m = sin(pi * pow(p, 1.));
    if (z != 0.) {
        uv.x -= 0.5;
        uv.y -= 0.5;
        uv *= (z * m + 1.);
        uv.x += 0.5;
        uv.y += 0.5;
    }
    return uv;
}
float quarticInOut(float t) {
    return t < 0.5 ? +8.0 * pow(t, 4.0) : -8.0 * pow(t - 1.0, 4.0) + 1.0;
}
void main() {
    vec2 uv = vUv;
    float aspect = resolution.x / resolution.y;
    vec2 origin = vec2(ox, oy);
    float m = progress;
    float nprog = map((0.5 - prange), (0.5 + prange), 0., 1., m, 0., 1.);
    float tr = sin(pi * pow(map(0.0, .7, 0., 1., m), 2.));
    float rm = map(0., 1., 0., 1., m);
    rm = quarticInOut(rm);
    float rx = tr * radians(intensity) * cos(angle);
    float ry = tr * radians(intensity) * sin(angle);
    uv = zoom(uv, 1. - rm, .5);
    vec2 tUv = uv;
    tUv = rotatePlane(tUv, origin, rx, ry);
    origin.x *= aspect;
    tUv.x *= aspect;
    tUv = rotate(tUv, origin, rm * rotation);
    tUv.x /= aspect;
    vec2 tUvIn = tUv;
    if (isShort) {
        tUvIn.x -= origin.x / aspect * 2.;
        tUvIn.y -= origin.y * 2.;
    }
    tUvIn = mirror(tUvIn);
    vec2 nUv = tUv;
    nUv = mirror(nUv);
    gl_FragColor = mix(TEXTURE2D(src1, nUv), TEXTURE2D(src2, tUvIn), nprog);
}