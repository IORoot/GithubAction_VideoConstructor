uniform float progress;
uniform bool flipx;
uniform bool flipy;
uniform sampler2D src1;
uniform sampler2D src2;
uniform sampler2D displacement;
uniform int useTexture;
uniform float threshold;
varying vec2 vUv;
void main() {
    vec4 texel1 = TEXTURE2D(src2, vUv);
    vec4 texel2 = TEXTURE2D(src1, vUv);
    vec4 transitionTexel = TEXTURE2D(displacement, vec2(flipx ? 1. - vUv.x : vUv.x, flipy ? 1. - vUv.y : vUv.y));
    float r = progress * (1.0 + threshold * 2.0) - threshold;
    float mixf = clamp((transitionTexel.r - r) * (1.0 / threshold), .0, 1.0);
    gl_FragColor = mix(texel1, texel2, mixf);
}