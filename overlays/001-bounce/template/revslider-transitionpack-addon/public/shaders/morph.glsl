uniform vec4 resolution;
uniform float intensity;
uniform float progress;
uniform sampler2D src1;
uniform sampler2D src2;
varying vec2 vUv;
uniform float left;
uniform float top;
vec2 mirror(vec2 v) {
    vec2 m = mod(v, 2.0);
    return mix(m, 2.0 - m, step(1.0, m));
}
vec4 getFromColor(vec2 uv) {
    return TEXTURE2D(src1, mirror(uv));
}
vec4 getToColor(vec2 uv) {
    return TEXTURE2D(src2, mirror(uv));
}
void main() {
    vec2 p = (vUv - vec2(0.5)) * resolution.zw + vec2(0.5);
    vec4 ca = getFromColor(p);
    vec4 cb = getToColor(p);
    vec2 oa = (((ca.rg + ca.b) * 0.5) * 2.0 - 1.0);
    vec2 ob = (((cb.rg + cb.b) * 0.5) * 2.0 - 1.0);
    vec2 oc = mix(oa, ob, 0.5) * intensity;
    float w0 = progress;
    float w1 = 1.0 - w0;
    vec2 uvOut = p;
    vec2 uvIn = p;
    if (left != 0.) {
        uvOut.x = p.x + left * oc.x * w0;
        uvIn.x = p.x + left * oc.x * w1;
    }
    if (top != 0.) {
        uvOut.y = p.y + top * oc.y * w0;
        uvIn.y = p.y + top * oc.y * w1;
    }
    gl_FragColor = mix(getFromColor(uvOut), getToColor(uvIn), progress);
}