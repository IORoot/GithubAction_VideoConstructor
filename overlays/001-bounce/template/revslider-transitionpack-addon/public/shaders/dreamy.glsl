uniform vec4 resolution;
uniform float intensity;
uniform float progress;
uniform sampler2D src1;
uniform sampler2D src2;
varying vec2 vUv;
vec4 getFromColor(vec2 uv) {
    return TEXTURE2D(src1, uv);
}
vec4 getToColor(vec2 uv) {
    return TEXTURE2D(src2, uv);
}
vec2 offset(float progress, float x, float theta) {
    float phase = progress * progress + progress + theta;
    float shifty = 0.03 * progress * cos(10.0 * (progress + x));
    return vec2(0, shifty);
}
void main() {
    vec2 p = (vUv - vec2(0.5)) * resolution.zw + vec2(0.5);
    gl_FragColor = mix(getFromColor(p + offset(progress, p.x, 0.0)), getToColor(p + offset(1.0 - progress, p.x, 3.14)), progress);
}