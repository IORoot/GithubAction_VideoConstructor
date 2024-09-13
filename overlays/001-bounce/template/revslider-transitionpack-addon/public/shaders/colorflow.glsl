uniform float progress;
uniform float intensity;
uniform sampler2D src1;
uniform sampler2D src2;
uniform sampler2D displacement;
uniform vec4 resolution;
varying vec2 vUv;
uniform float left;
uniform float top;
uniform float angle;
vec2 mirror(vec2 v) {
    vec2 m = mod(v, 2.0);
    return mix(m, 2.0 - m, step(1.0, m));
}
mat2 getRotM(float angle) {
    float s = sin(angle);
    float c = cos(angle);
    return mat2(c, -s, s, c);
}
const float PI = 3.1415;
void main() {
    vec2 newUV = (vUv - vec2(0.5)) * resolution.zw + vec2(0.5);
    vec4 disp = TEXTURE2D(displacement, newUV);
    vec2 dispVec = vec2(disp.r, disp.g);
    vec2 distort1 = getRotM(angle) * dispVec * intensity * progress;
    vec2 distort2 = getRotM(angle - PI) * dispVec * intensity * (1.0 - progress);
    if (left != 0.) {
        distort1.x *= left;
        distort2.x *= left;
    }
    if (top != 0.) {
        distort1.y *= top;
        distort2.y *= top;
    }
    vec2 distortedPosition1 = newUV + distort1;
    vec2 distortedPosition2 = newUV + distort2;
    vec4 t1 = TEXTURE2D(src1, mirror(distortedPosition1));
    vec4 t2 = TEXTURE2D(src2, mirror(distortedPosition2));
    gl_FragColor = mix(t1, t2, progress);
}