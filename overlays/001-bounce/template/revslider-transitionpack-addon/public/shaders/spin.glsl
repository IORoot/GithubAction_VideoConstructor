const int Samples = 32;
uniform float ox;
uniform float oy;
uniform float roz;
uniform float xdist;
uniform float ydist;
uniform float zoom;
uniform float intensity;
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
vec2 rotate(vec2 uv, vec2 mid, float rotation) {
    return vec2(cos(rotation) * (uv.x - mid.x) + sin(rotation) * (uv.y - mid.y) + mid.x, cos(rotation) * (uv.y - mid.y) - sin(rotation) * (uv.x - mid.x) + mid.y);
}
float map(float a, float b, float c, float d, float v) {
    return clamp((v - a) * (d - c) / (b - a) + c, 0., 1.);
}
vec2 getSample(vec2 temp, vec2 o, float ratio, int i, float intensity) {
    o.x *= ratio;
    temp.x *= ratio;
    temp = rotate(temp, o, float(i) * intensity);
    temp.x /= ratio;
    temp = mirror(temp);
    return temp;
}
vec2 zoomFunction(vec2 uv, vec2 o, float z, float m) {
    uv -= o;
    uv *= 1. + z * m;
    uv += o;
    return uv;
}
void main() {
    vec2 o = vec2(ox, oy);
    float Intensity = intensity;
    vec2 uv = vUv;
    float ratio = resolution.x / resolution.y;
    vec2 dir = uv - o;
    vec4 color = vec4(0.0, 0.0, 0.0, 0.0);
    float m = progress;
    m = map(0., 0.999, 0., 1., m);
    float mult = sin(m * pi);
    float zm = mult;
    Intensity *= pow(mult, 2.) * 0.1;
    o.x *= ratio;
    uv.x *= ratio;
    uv = rotate(uv, vec2(o.x, o.y), roz * 1. * pi * m);
    o.x /= ratio;
    uv.x /= ratio;
    if (zoom != 0.) uv = zoomFunction(uv, o, max(zoom, -0.9), zm);
    vec2 uvIn = uv;
    vec2 nO = o;
    if (isShort) {
        uvIn.x -= o.x * 2.;
        uvIn.y -= o.y * 2.;
        nO.x -= o.x * 2.;
        nO.y -= o.y * 2.;
    }
    float nprog = map((0.5 - prange), (0.5 + prange), 0., 1., m);
    vec2 bUv = uv;
    vec2 temp = bUv;
    vec2 tempIn = uv;
    for (int i = 0; i < Samples; i += 2) {
        temp = bUv;
        temp = getSample(temp, o, ratio, i, -Intensity);
        tempIn = uvIn;
        tempIn = getSample(tempIn, nO, ratio, i, -Intensity);
        color += mix(TEXTURE2D(src1, temp), TEXTURE2D(src2, tempIn), nprog);
        temp = bUv;
        temp = getSample(temp, o, ratio, i + 1, -Intensity);
        tempIn = uvIn;
        tempIn = getSample(tempIn, nO, ratio, i, -Intensity);
        color += mix(TEXTURE2D(src1, temp), TEXTURE2D(src2, tempIn), nprog);
    }
    
    gl_FragColor = color / float(Samples);
}