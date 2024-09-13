uniform int endx;
uniform int endy;
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
float Rand(vec2 v) {
    return fract(sin(dot(v.xy, vec2(12.9898, 78.233))) * 43758.5453);
}
vec2 Rotate(vec2 v, float a) {
    mat2 rm = mat2(cos(a), -sin(a), sin(a), cos(a));
    return rm * v;
}
float CosInterpolation(float x) {
    return -cos(x * 3.14159265358979323) / 2. + .5;
}
float POW2(float X) {
    return X * X;
}
float POW3(float X) {
    return X * X * X;
}
void main() {
    vec2 newUV = (vUv - vec2(0.5)) * resolution.zw + vec2(0.5);
    vec2 p = newUV.xy / vec2(1.0).xy - .5;
    vec2 rp = p;
    float rpr = (progress * 2. - 1.);
    float z = -(rpr * rpr * 2.) + 3.;
    float az = abs(z);
    rp *= az;
    rp += mix(vec2(.5, .5), vec2(float(endx) + .5, float(endy) + .5), POW2(CosInterpolation(progress)));
    vec2 mrp = mod(rp, 1.);
    vec2 crp = rp;
    bool onEnd = int(floor(crp.x)) == endx && int(floor(crp.y)) == endy;
    if (!onEnd) {
        float ang = float(int(Rand(floor(crp)) * 4.)) * .5 * 3.14159265358979323;
        mrp = vec2(.5) + Rotate(mrp - vec2(.5), ang);
    }
    if (onEnd || Rand(floor(crp)) > .5) {
        gl_FragColor = getToColor(mrp);
    } else {
        gl_FragColor = getFromColor(mrp);
    }
}