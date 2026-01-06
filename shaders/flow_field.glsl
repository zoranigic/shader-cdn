// Flow Field - Abstract flowing energy visualization
precision highp float;

uniform vec2 resolution;
uniform float time;
uniform float detail;

const float PI = 3.14159265359;
const float PI2 = 6.28318530718;

vec3 hsv2rgb(vec3 c) {
    vec4 K = vec4(1.0, 2.0 / 3.0, 1.0 / 3.0, 3.0);
    vec3 p = abs(fract(c.xxx + K.xyz) * 6.0 - K.www);
    return c.z * mix(K.xxx, clamp(p - K.xxx, 0.0, 1.0), c.y);
}

vec2 angleToVec(float rad) {
    return vec2(sin(rad), cos(rad));
}

float hash(vec2 p) {
    return fract(sin(dot(p, vec2(127.1, 311.7))) * 43758.5453);
}

float noise(vec2 p) {
    vec2 i = floor(p);
    vec2 f = fract(p);
    f = f * f * (3.0 - 2.0 * f);

    float a = hash(i);
    float b = hash(i + vec2(1.0, 0.0));
    float c = hash(i + vec2(0.0, 1.0));
    float d = hash(i + vec2(1.0, 1.0));

    return mix(mix(a, b, f.x), mix(c, d, f.x), f.y);
}

float fbm(vec2 p) {
    float v = 0.0;
    float a = 0.5;
    for(int i = 0; i < 5; i++) {
        v += a * noise(p);
        p *= 2.0;
        a *= 0.5;
    }
    return v;
}

float sin01(float v) {
    return 0.5 + 0.5 * sin(v);
}

void main(void) {
    float mxy = max(resolution.x, resolution.y);
    vec2 uv = gl_FragCoord.xy / resolution.xy;
    vec2 xy = gl_FragCoord.xy / mxy;

    float t = time * 0.5;

    // Flow field distortion
    vec2 p = xy + 0.05 * (vec2(
        fbm(xy * 3.0 + t * 0.3) + fbm(3.0 * xy + t * 0.5),
        fbm(xy * 3.0 + 0.5 + t * 0.3) + fbm(3.0 * xy + 0.3)
    ) - 0.5);

    // Calculate flow angle
    float a = PI * pow(
        sin01(8.0 * PI * p.x + t) +
        sin01(8.0 * PI * p.y + t * 0.7),
    2.0);

    // Simulate flow accumulation over time
    float flow = 0.0;

    // Create flowing energy centers that move
    for(int i = 0; i < 3; i++) {
        float fi = float(i);
        vec2 center = vec2(
            0.5 + 0.3 * sin(t * 0.5 + fi * 2.1),
            0.5 + 0.3 * cos(t * 0.4 + fi * 1.7)
        );
        float dist = distance(xy, center);
        flow += pow(1.0 - min(1.0, max(0.0, 3.0 * dist)), 8.0);
    }

    // Add noise-based flow
    float n = fbm(p * 4.0 + t * 0.2);
    flow += 0.5 * n;
    flow = clamp(flow, 0.0, 1.0);

    // Background
    vec3 color = vec3(0.08, 0.08, 0.12);

    // Visualize flow with HSV colors
    vec3 flowColor = hsv2rgb(vec3(0.55 + 0.15 * flow, 0.9, pow(flow, 0.5)));
    color += flowColor * (0.7 + 0.3 * detail);

    // Height/contour lines
    float lineIntensity = 0.15;
    color += lineIntensity * smoothstep(0.02, 0.0, abs(fract(a * 0.5) - 0.5) - 0.48);
    color += lineIntensity * smoothstep(0.02, 0.0, abs(fract(a * 0.25 + 0.25) - 0.5) - 0.48);

    // Subtle noise grain
    color += 0.05 * (hash(uv * 500.0 + t) - 0.5);

    // Vignette
    float vig = 1.0 - 0.4 * pow(distance(uv, vec2(0.5)), 2.0);
    color *= vig;

    gl_FragColor = vec4(color, 1.0);
}
