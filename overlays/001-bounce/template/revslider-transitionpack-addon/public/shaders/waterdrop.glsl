uniform float amplitude;
uniform float speed;
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
void main() {
    vec2 p = (vUv - vec2(0.5)) * resolution.zw + vec2(0.5);
    vec2 dir = p - vec2(.5);
    float dist = length(dir);
    float ratio = resolution.x / resolution.y;
    float maxdist = resolution.x > resolution.y ? ratio : 1. / ratio;
    ratio = maxdist;
    maxdist *= progress;
    maxdist = smoothstep(dist, dist * (1.5 * ratio + 1.5 * (1. - progress)), maxdist);
    if (dist > progress) {
        gl_FragColor = mix(getFromColor(p), getToColor(p), progress);
    } else {
        vec2 offset = dir * sin(dist * amplitude - progress * speed);
        gl_FragColor = mix(getFromColor(p + offset), getToColor(p), progress);
    }
    gl_FragColor = mix(getFromColor(p), gl_FragColor, maxdist);
}