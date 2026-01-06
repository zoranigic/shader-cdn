// 3D Flame - Volumetric fire effect (Optimized)
// Created by anatole duprat - XT95/2013
// License Creative Commons Attribution-NonCommercial-ShareAlike 3.0 Unported License.
// Adapted and optimized for Live Wallpapers

precision highp float;

uniform float time;
uniform vec2 resolution;
uniform float detail;

// Simplified noise - faster than original
float noise(vec3 p)
{
    vec3 i = floor(p);
    vec3 f = fract(p);
    f = f * f * (3.0 - 2.0 * f);  // Smoothstep

    float n = i.x + i.y * 57.0 + i.z * 113.0;

    float a = fract(sin(n) * 43758.5453);
    float b = fract(sin(n + 1.0) * 43758.5453);
    float c = fract(sin(n + 57.0) * 43758.5453);
    float d = fract(sin(n + 58.0) * 43758.5453);
    float e = fract(sin(n + 113.0) * 43758.5453);
    float f1 = fract(sin(n + 114.0) * 43758.5453);
    float g = fract(sin(n + 170.0) * 43758.5453);
    float h = fract(sin(n + 171.0) * 43758.5453);

    return mix(
        mix(mix(a, b, f.x), mix(c, d, f.x), f.y),
        mix(mix(e, f1, f.x), mix(g, h, f.x), f.y),
        f.z
    );
}

float flame(vec3 p, float t)
{
    float d = length(p * vec3(1.0, 0.5, 1.0) - vec3(0.0, -1.0, 0.0)) - 1.0;
    // Single noise call instead of two
    float n = noise(p + vec3(0.0, t * 2.0, 0.0));
    return d + n * 0.3 * p.y;
}

float scene(vec3 p, float t)
{
    return min(100.0 - length(p), abs(flame(p, t)));
}

vec4 raymarch(vec3 org, vec3 dir, float t)
{
    float glow = 0.0;
    vec3 p = org;
    bool glowed = false;

    // Reduced iterations: 64 -> 40
    for(int i = 0; i < 40; i++)
    {
        float d = scene(p, t) + 0.02;
        p += d * dir;

        if(d > 0.02)
        {
            if(flame(p, t) < 0.0)
                glowed = true;
            if(glowed)
                glow = float(i) / 40.0;
        }
    }
    return vec4(p, glow);
}

void main()
{
    // Detail pixelation
    vec2 fragCoord = floor(gl_FragCoord.xy / detail) * detail;

    vec2 v = -1.0 + 2.0 * fragCoord.xy / resolution.xy;
    v.x *= resolution.x / resolution.y;

    vec3 org = vec3(0.0, -2.0, 4.0);
    vec3 dir = normalize(vec3(v.x * 1.6, -v.y, -1.5));

    vec4 p = raymarch(org, dir, time);
    float glow = p.w;

    // Fire colors: orange to blue
    vec4 col = mix(vec4(1.0, 0.5, 0.1, 1.0), vec4(0.1, 0.5, 1.0, 1.0), p.y * 0.02 + 0.4);

    gl_FragColor = mix(vec4(0.0), col, pow(glow * 2.0, 4.0));
}
