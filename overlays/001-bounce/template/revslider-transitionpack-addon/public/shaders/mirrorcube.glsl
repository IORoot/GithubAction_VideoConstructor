uniform float persp;
uniform float unzoom;
uniform float reflection;
uniform float floating;
uniform vec4 resolution;
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
vec2 project(vec2 p) {
    return p * vec2(1.0, -1.2) + vec2(0.0, -floating / 100.);
}
bool inBounds(vec2 p) {
    return all(lessThan(vec2(0.0), p)) && all(lessThan(p, vec2(1.0)));
}
vec4 bgColor(vec2 p, vec2 pfr, vec2 pto) {
    vec4 c = vec4(0.0, 0.0, 0.0, 1.0);
    pfr = project(pfr);
    if (inBounds(pfr)) {
        c += mix(vec4(0.0), getFromColor(pfr), reflection * mix(1.0, 0.0, pfr.y));
    }
    pto = project(pto);
    if (inBounds(pto)) {
        c += mix(vec4(0.0), getToColor(pto), reflection * mix(1.0, 0.0, pto.y));
    }
    return c;
}
vec2 xchaos(vec2 p, float persp, float center) {
    float x = mix(p.x, 1.0 - p.x, center);
    return ((vec2(x, (p.y - 0.5 * (1.0 - persp) * x) / (1.0 + (persp - 1.0) * x)) - vec2(0.5 - distance(center, 0.5), 0.0)) * vec2(0.5 / distance(center, 0.5) * (center < 0.5 ? 1.0 : -1.0), 1.0) + vec2(center < 0.5 ? 0.0 : 1.0, 0.0));
}
void main() {
    vec2 op = (vUv - vec2(0.5)) * resolution.zw + vec2(0.5);
    float uz = unzoom * 2.0 * (0.5 - distance(0.5, progress));
    vec2 p = -uz * 0.5 + (1.0 + uz) * op;
    vec2 fromP = xchaos((p - vec2(progress, 0.0)) / vec2(1.0 - progress, 1.0), 1.0 - mix(progress, 0.0, persp), 0.0);
    vec2 toP = xchaos(p / vec2(progress, 1.0), mix(pow(progress, 2.0), 1.0, persp), 1.0);
    if (inBounds(fromP)) {
        gl_FragColor = getFromColor(fromP);
    } else if (inBounds(toP)) {
        gl_FragColor = getToColor(toP);
    } else {
        gl_FragColor = bgColor(op, fromP, toP);
    }
}