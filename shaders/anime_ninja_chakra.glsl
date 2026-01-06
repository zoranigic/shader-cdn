// Anime Ninja Chakra (Naruto vibe) - abstract, no character likeness
precision highp float;

uniform float time;
uniform vec2 resolution;
uniform float detail;

#define PI 3.14159265359

// --- helpers ---
float hash21(vec2 p){
    p = fract(p*vec2(123.34, 345.45));
    p += dot(p, p+34.345);
    return fract(p.x*p.y);
}

float noise(vec2 p){
    vec2 i = floor(p);
    vec2 f = fract(p);
    float a = hash21(i);
    float b = hash21(i + vec2(1.0, 0.0));
    float c = hash21(i + vec2(0.0, 1.0));
    float d = hash21(i + vec2(1.0, 1.0));
    vec2 u = f*f*(3.0 - 2.0*f);
    return mix(mix(a,b,u.x), mix(c,d,u.x), u.y);
}

float fbm(vec2 p){
    float v = 0.0;
    float a = 0.5;
    for(int i=0;i<5;i++){
        v += a * noise(p);
        p *= 2.0;
        a *= 0.5;
    }
    return v;
}

mat2 rot(float a){
    float s = sin(a), c = cos(a);
    return mat2(c,-s,s,c);
}

float sdCircle(vec2 p, float r){ return length(p) - r; }

// simple SDF leaf-like emblem (stylized)
float sdLeaf(vec2 p){
    // center leaf body: two circles + cut
    float a = sdCircle(p - vec2(0.00, 0.02), 0.22);
    float b = sdCircle(p - vec2(0.08, 0.02), 0.18);
    float c = sdCircle(p - vec2(-0.10,0.02), 0.18);
    float body = min(b, c);
    body = max(body, -sdCircle(p - vec2(0.00,-0.06), 0.12)); // inner cut

    // swirl tail
    vec2 q = p - vec2(-0.06, -0.05);
    float ang = atan(q.y, q.x);
    float rad = length(q);
    float spiral = abs(rad - (0.10 + 0.08*(ang/PI))) - 0.03;
    float tail = spiral;

    // combine
    float leaf = min(max(body, -a), tail);
    return leaf;
}

void main(){
    vec2 uv = (gl_FragCoord.xy / resolution.xy);
    vec2 p = (gl_FragCoord.xy - 0.5*resolution.xy) / min(resolution.x, resolution.y);

    float t = time * (0.8 + 1.2*detail);

    // --- background gradient ---
    vec3 colTop = vec3(0.05, 0.07, 0.10);
    vec3 colBot = vec3(0.02, 0.02, 0.03);
    vec3 col = mix(colBot, colTop, smoothstep(0.0, 1.0, uv.y));

    // --- chakra swirl field ---
    vec2 c = p;
    float r = length(c);
    float a = atan(c.y, c.x);

    // swirl distortion
    float swirl = sin(8.0*a + 10.0*r - 2.2*t) * 0.25;
    vec2 dp = c * rot(swirl);

    float n = fbm(dp*3.0 + vec2(0.0, t*0.5));
    float ring = exp(-8.0*abs(r - (0.42 + 0.05*sin(t*1.7))));
    float core = exp(-6.0*r*r);

    // speed lines (anime-ish)
    float lines = abs(sin(30.0*a + 6.0*n - t*4.0));
    lines = smoothstep(0.75, 1.0, lines) * smoothstep(0.2, 0.9, r);

    // chakra intensity
    float chakra = (0.55*core + 1.2*ring) * (0.6 + 0.4*n);
    chakra += 0.35 * lines;

    // orange glow
    vec3 chakraCol = vec3(1.00, 0.55, 0.12);
    col += chakra * chakraCol * (0.75 + 0.5*detail);

    // --- subtle "jacket/headband" band shape (abstract) ---
    float band = smoothstep(0.18, 0.16, abs(p.y + 0.15)) * smoothstep(0.55, 0.20, abs(p.x));
    col = mix(col, vec3(0.10,0.12,0.14), band);

    // --- leaf emblem on "headband" ---
    vec2 epos = p - vec2(0.0, -0.15);
    epos *= 1.35;
    float leaf = sdLeaf(epos);
    float leafFill = smoothstep(0.01, -0.01, leaf);
    float leafEdge = smoothstep(0.02, 0.00, abs(leaf)) * 0.8;

    vec3 metal = vec3(0.55, 0.58, 0.62);
    vec3 ink   = vec3(0.08, 0.09, 0.10);

    col = mix(col, metal, leafFill*0.85);
    col = mix(col, ink, leafEdge);

    // --- vignette + final tone ---
    float vig = smoothstep(1.1, 0.2, r);
    col *= (0.75 + 0.25*vig);

    // small flicker sparkle
    float spark = smoothstep(0.995, 1.0, noise(p*40.0 + t*2.0)) * 0.35 * core;
    col += spark * vec3(1.0, 0.9, 0.7);

    // clamp
    col = pow(clamp(col, 0.0, 1.0), vec3(0.95));

    gl_FragColor = vec4(col, 1.0);
}
