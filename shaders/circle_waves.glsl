precision highp float;

uniform float time;
uniform vec2 resolution;
uniform float detail;

#define PI 3.141592653589793
#define TWO_PI 6.283185307179586
#define CIRCLE_COUNT 20.0

#define COLOR_1 vec3(0.03,0.28,0.65)
#define COLOR_2 vec3(0.38,0.09,0.73)
#define COLOR_3 vec3(0.80,0.08,0.08)
#define COLOR_4 vec3(0.90,0.59,0.05)

float hash(vec2 p) {
    return fract(sin(dot(p, vec2(12.9898, 78.233))) * 43758.5453);
}

float noise(vec2 p) {
    vec2 i = floor(p);
    vec2 f = fract(p);
    vec2 u = f * f * (3.0 - 2.0 * f);

    float a = hash(i);
    float b = hash(i + vec2(1.0, 0.0));
    float c = hash(i + vec2(0.0, 1.0));
    float d = hash(i + vec2(1.0, 1.0));

    return mix(mix(a, b, u.x), mix(c, d, u.x), u.y);
}

vec3 palette(float t) {
    t = fract(t);

    if(t < 0.25) {
        return mix(COLOR_1, COLOR_2, t * 4.0);
    } else if(t < 0.5) {
        return mix(COLOR_2, COLOR_3, (t - 0.25) * 4.0);
    } else if(t < 0.75) {
        return mix(COLOR_3, COLOR_4, (t - 0.5) * 4.0);
    } else {
        return mix(COLOR_4, COLOR_1, (t - 0.75) * 4.0);
    }
}

float circleWave(vec2 uv, vec2 center, float radius, float t, float phase, float thickness) {
    float dist = length(uv - center);
    float wave = smoothstep(radius + thickness, radius, dist) -
                 smoothstep(radius, radius - thickness, dist);

    float pulse = 0.8 + 0.2 * sin(t * 2.0 + phase * 5.0);

    return wave * pulse;
}

void main() {
    vec2 fragCoord = floor(gl_FragCoord.xy / detail) * detail;

    vec2 uv = (fragCoord - 0.5 * resolution.xy) / resolution.y;
    float t = time * 0.8;

    vec3 color = vec3(0.0);

    for(float i = 0.0; i < CIRCLE_COUNT; i++) {
        float phase = i * 0.5;

        vec2 orbitCenter = vec2(cos(t * 0.3 + phase), sin(t * 0.25 + phase)) * 0.2;
        orbitCenter += vec2(cos(t * 0.7 + phase * 1.3), sin(t * 0.6 + phase * 1.1)) * 0.1;

        float radius = 0.6 + 0.3 * sin(t * 0.4 + phase);
        float thickness = 0.03 + 0.02 * sin(t * 0.5 + phase * 2.0);

        float wave = circleWave(uv, orbitCenter, radius, t, phase, thickness);

        if(wave > 0.0) {
            float hue = fract(i * 0.1 + t * 0.05);
            vec3 waveColor = palette(hue);

            float edge = 1.0 - smoothstep(0.0, 0.3, abs(length(uv - orbitCenter) - radius));
            waveColor *= 1.0 + edge * 0.8;

            float intensity = wave * (0.9 - i * 0.05);
            color += waveColor * intensity;

            float glow = exp(-abs(length(uv - orbitCenter) - radius) * 20.0);
            color += waveColor * glow * 0.2;
        }
    }

    float noiseTex = noise(uv * 100.0 + t) * 0.01;
    color += vec3(noiseTex * 0.5, noiseTex, noiseTex * 1.5);

    color = color / (color + 1.0);
    color = color * color * (3.0 - 0.5 * color);

    color.r *= 1.05;
    color.g *= 0.98;
    color.b *= 1.02;

    color = pow(color, vec3(0.92));

    gl_FragColor = vec4(color, 1.0);
}
