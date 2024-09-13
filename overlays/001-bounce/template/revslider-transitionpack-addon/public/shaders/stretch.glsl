uniform float left;
uniform float top;
uniform int dir;
uniform float intensity;
uniform float twistIntensity;
uniform float twistSize;
uniform float flipTwist;
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
float map(float a, float b, float c, float d, float v) {
    return clamp((v - a) * (d - c) / (b - a) + c, 0., 1.);
}
void main() {
    float ratio = resolution.x / resolution.y;
    vec2 uv = vUv;
    vec2 uvc = uv;
    vec2 vw = uv;
    vec2 vwo = vw;
    float m = progress;
    float steps = 1.0 / (abs(left + top) + 2.);
    float ms = map(steps, 1.0 - steps, 0., 1., m);
    float flip = (m - 0.5) * 2.;
    float signFlip = -sign(left + top);
    float mult = sin(m * pi);
    if (dir == 1) {
        vw.x = uv.x * 1. / intensity;
        vw = mix(vwo, vw, mult);
        uv.x = vw.x + (-flip * signFlip > 0. ? .0 * mult : 1. * mult);
        if (twistIntensity != 0.) {
            uv.y += mult * flip * signFlip * twistIntensity / 20. * flipTwist;
            uv.y += twistIntensity * flip * pow((flip * -signFlip > 0. ? uvc.x : 1. - uvc.x), twistSize) * mult * flipTwist * ratio / 5.;
        }
    } else {
        vw.y = uv.y * 1. / intensity;
        vw = mix(vwo, vw, mult);
        uv.y = vw.y + (flip * -signFlip > 0. ? .0 * mult : 1. * mult);
        if (twistIntensity != 0.) {
            uv.x += mult * flip * twistIntensity / 20. * flipTwist;
            uv.x += twistIntensity * flip * pow((flip * -signFlip > 0. ? uvc.y : 1. - uvc.y), twistSize) * mult * flipTwist / ratio / 5.;
        }
    }
    vec2 nUv = vec2(uv.x + ms * left, uv.y + ms * top);
    nUv = mirror(nUv);
    vec2 nUvO = nUv;
    if (mod(left, 2.0) != 0.) nUv.x *= -1.;
    if (mod(top, 2.0) != 0.) nUv.y *= -1.;
    gl_FragColor = mix(TEXTURE2D(src1, nUvO), TEXTURE2D(src2, nUv), ms);
}