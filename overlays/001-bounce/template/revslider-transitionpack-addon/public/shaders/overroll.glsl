uniform int dir;
uniform float time;
uniform float progress;
uniform float width;
uniform float scaleX;
uniform float scaleY;
uniform float transition;
uniform float radius;
uniform float swipe;
uniform float intensity;
uniform sampler2D src1;
uniform sampler2D src2;
uniform sampler2D displacement;
uniform vec4 resolution;
varying vec2 vUv;
varying vec4 vPosition;
vec2 mirrored(vec2 v) {
    vec2 m = mod(v, 2.);
    return mix(m, 2.0 - m, step(1.0, m));
}
void main() {
    vec2 newUV = (vUv - vec2(0.5)) * resolution.zw + vec2(0.5);
    vec4 noise = TEXTURE2D(displacement, mirrored(newUV + time * 0.04));
    float prog = progress * (0.8 + intensity) - (intensity) + noise.g * (intensity);
    float intpl = dir == 0 ? pow(abs(smoothstep(0., 1., (prog * 2. - vUv.x + 0.5))), 10.) : dir == 1 ? pow(abs(smoothstep(0., 1., (prog * 2. + vUv.x - 0.5))), 10.) : dir == 2 ? pow(abs(smoothstep(0., 1., (prog * 2. + vUv.y - 0.5))), 10.) : pow(abs(smoothstep(0., 1., (prog * 2. - vUv.y + 0.5))), 10.);
    vec4 t1 = TEXTURE2D(src1, (newUV - 0.5) * (1.0 - intpl) + 0.5);
    vec4 t2 = TEXTURE2D(src2, (newUV - 0.5) * intpl + 0.5);
    gl_FragColor = mix(t1, t2, intpl);
}