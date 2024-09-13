uniform int dir;
uniform float intensity;
uniform float progress;
uniform sampler2D src1;
uniform sampler2D src2;
varying vec2 vUv;
uniform vec4 resolution;
float Hash(vec2 p) {
    vec3 p2 = vec3(p.xy, 1.0);
    return fract(sin(dot(p2, vec3(37.1, 61.7, 12.4))) * 10.);
}
float noise(in vec2 p) {
    vec2 i = floor(p);
    vec2 f = fract(p);
    f *= f * (3.0 - 2.0 * f);
    return mix(mix(Hash(i + vec2(0., 0.)), Hash(i + vec2(1., 0.)), f.x), mix(Hash(i + vec2(0., 1.)), Hash(i + vec2(1., 1.)), f.x), f.y);
}
float fbm(vec2 p) {
    float v = 0.0;
    v += noise(p * 1.) * .4;
    v += noise(p * 2.) * .2;
    v += noise(p * 4.) * .135;
    return v;
}
void main() {
    float nIntensity = intensity / 3.;
    vec2 uv = (vUv - vec2(0.5)) * resolution.zw + vec2(0.5);
    vec4 src = TEXTURE2D(src1, uv);
    vec4 tgt = TEXTURE2D(src2, uv);
    vec4 col = src;
    float pr = progress;
    float d;
    float efEnd = dir == 1 || dir == 2 ? 0.5 : 0.8 * nIntensity;
    float efStart = dir == 1 || dir == 2 ? 0.5 : 1. * nIntensity - .3;
    if (dir == 0) {
        uv.x += efStart;
        d = -uv.x + 0.5 * fbm(uv * 30.1) * intensity + pr * 1.3 + efEnd * pr;
    }
    if (dir == 1) {
        uv.x -= efStart;
        d = uv.x - 0.5 * fbm(uv * 30.1) * intensity + pr * 1.3 + efEnd * pr;
    }
    if (dir == 2) {
        uv.y -= efStart;
        d = uv.y - 0.5 * fbm(uv * 30.1) * intensity + pr * 1.3 + efEnd * pr;
    }
    if (dir == 3) {
        uv.y += efStart;
        d = -uv.y + 0.5 * fbm(uv * 30.1) * intensity + pr * 1.3 + efEnd * pr;
    }
    if (d > 0.35 + (0.1 * (1. - nIntensity))) col.rgb = clamp(col.rgb - (d - 0.35 - (0.1 * (1. - nIntensity))) * 10., 0.0, 1.0);
    if (d > 0.47) {
        if (d < 0.5) col.rgb += (d - 0.4) * 35.0 * 0.4 * (0.1 + noise(100. * uv + vec2(-pr, 0.))) * vec3(1.5, 0.5, 0.0);
        else col += tgt;
    }
    gl_FragColor = col;
}