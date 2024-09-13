uniform float prange;
uniform float left;
uniform float top;
uniform int dir;
uniform float progress;
uniform vec4 resolution;
uniform sampler2D src1;
uniform sampler2D src2;
uniform float intensity;
varying vec2 vUv;
vec2 mirror(vec2 v) {
    vec2 m = mod(v, 2.0);
    return mix(m, 2.0 - m, step(1.0, m));
}
float map(float a, float b, float c, float d, float v, float cmin, float cmax) {
    return clamp((v - a) * (d - c) / (b - a) + c, cmin, cmax);
}
void main() {
    vec2 uv = vUv;
    vec2 vw = uv - 0.5;
    vec2 vwo = vw;
    float m = progress;
    float w = m;
    float mult = (w - 0.5) * 2.;
    mult = (-(mult * mult) + 1.);
    #replaceChaos vw = mix(vwo, vw, mult * intensity / 10.);
    uv = .5 + (vw.xy);
    vec2 nUv = vec2(uv.x + m * left, uv.y + m * top);
    nUv = mirror(nUv);
    vec2 nUvIn = nUv;
    if (mod(left, 2.) != 0.) nUvIn.x *= -1.;
    if (mod(top, 2.) != 0.) nUvIn.y *= -1.;
    float nprog = map((0.5 - prange), (0.5 + prange), 0., 1., progress, 0., 1.);
    vec4 col = mix(TEXTURE2D(src1, nUv), TEXTURE2D(src2, nUvIn), nprog);
    gl_FragColor = col;
}