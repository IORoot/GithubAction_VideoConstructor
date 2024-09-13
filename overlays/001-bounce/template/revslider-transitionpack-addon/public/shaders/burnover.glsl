uniform vec4 resolution;
uniform float progress;
uniform sampler2D src1;
uniform sampler2D src2;
uniform sampler2D displacement;
uniform int useTexture;
varying vec2 vUv;
void main() {
    float p = progress;
    vec2 uv = (vUv - vec2(0.5)) * resolution.zw + vec2(0.5);
    vec4 col = vec4(0.);
    vec4 heightmap = TEXTURE2D(displacement, uv).rrra;
    vec4 background = TEXTURE2D(src1, uv);
    vec4 foreground = TEXTURE2D(src2, uv);
    float t = p * 1.2;
    vec4 erosion = smoothstep(t - .2, t, heightmap);
    vec4 border = smoothstep(0., .1, erosion) - smoothstep(.1, 1., erosion);
    col = (1. - erosion) * foreground + erosion * background;
    vec4 leadcol = vec4(1., .5, .1, 1.);
    vec4 trailcol = vec4(0.2, .4, 1., 1.);
    vec4 fire = mix(leadcol, trailcol, smoothstep(0.8, 1., border)) * 2.;
    col += border * fire;
    gl_FragColor = col;
}