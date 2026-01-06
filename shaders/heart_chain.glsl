//!COMMON
// Heart Chain - converted from Shadertoy ssjyWc
// Original by wyatt

#define safeSqrt(a) sqrt(abs(a) + 0.0001)

float k;

float G2(float w, float s) {
    return 0.15915494309 * exp(-0.5 * w * w / s / s) / (s * s);
}

float G1(float w, float s) {
    return 0.3989422804 * exp(-0.5 * w * w / s / s) / s;
}

float heart(vec2 u, vec2 R) {
    u -= vec2(0.5, 0.4) * R;
    u.y -= 10.0 * safeSqrt(abs(u.x));
    u.x *= 0.8;
    if (length(u) < 0.35 * R.y) return 1.0;
    return 0.0;
}

float _12(vec2 U, vec2 R) {
    return clamp(floor(U.x) + floor(U.y) * R.x, 0.0, R.x * R.y);
}

vec2 _21(float i, vec2 R) {
    return clamp(vec2(mod(i, R.x), floor(i / R.x)) + 0.5, vec2(0.0), R);
}

float sg(vec2 p, vec2 a, vec2 b) {
    float i = clamp(dot(p - a, b - a) / dot(b - a, b - a), 0.0, 1.0);
    float l = length(p - a - (b - a) * i);
    return l;
}

float hash(vec2 p) {
    vec3 p3 = fract(vec3(p.xyx) * 0.1031);
    p3 += dot(p3, p3.yzx + 33.33);
    return fract((p3.x + p3.y) * p3.z);
}

//!BUFFER_A
// Particle simulation
// iChannel0 = Buffer A (self, previous frame)
// iChannel1 = Buffer D (density field for repulsion)

#define A(U) texture2D(iChannel0, (U)/R)
#define D(U) texture2D(iChannel1, (U)/R)

void mainImage(out vec4 Q, in vec2 U) {
    vec2 R = iResolution;
    k = 0.02 * R.x * R.y;
    float i = _12(U, R);
    Q = A(U);

    vec2 f = vec2(0.0);

    if (i < k) {
        // Particle chain interactions
        for (float j = -20.0; j <= 20.0; j++) {
            if (j != 0.0) {
                vec4 a = A(_21(mod(i + j, k), R));
                vec2 r = a.xy - Q.xy;
                float l = length(r);
                f += 50.0 * r / safeSqrt(l) * (l - abs(j)) * (G1(j, 10.0) + 2.0 * G1(j, 5.0));
            }
        }

        // Density repulsion from blur field
        for (float x = -2.0; x <= 2.0; x++) {
            for (float y = -2.0; y <= 2.0; y++) {
                vec2 u = vec2(x, y);
                vec4 d = D(Q.xy + u);
                f -= 100.0 * d.w * u;
            }
        }

        if (length(f) > 0.1) f = 0.1 * normalize(f);
        Q.zw += f - 0.03 * Q.zw;
        Q.xy += f + 1.5 * Q.zw * inversesqrt(1.0 + dot(Q.zw, Q.zw));

        // Smooth with neighbors
        vec4 m = 0.5 * (A(_21(i - 1.0, R)) + A(_21(i + 1.0, R)));
        Q.zw = mix(Q.zw, m.zw, 0.1);
        Q.xy = mix(Q.xy, m.xy, 0.01);

        // Wrap around screen edges
        if (Q.x > R.x) { Q.y = 0.5 * R.y; Q.z = -10.0; }
        if (Q.x < 0.0) { Q.y = 0.5 * R.y; Q.z = 10.0; }
    }

    // Initialize on first frame - particles in heart shape
    if (I < 1) {
        if (i > k) {
            Q = vec4(R + i, 0.0, 0.0);
        } else {
            Q = vec4(0.5 * R + 0.25 * R.y * cos(6.28 * i / k + vec2(0.0, 1.57)), 0.0, 0.0);
        }
    }
}

//!BUFFER_B
// Voronoi distance field - finds nearest particle and draws lines
// iChannel0 = Buffer A (particle positions)
// iChannel1 = Buffer B (self, previous frame for propagation)

#define A(U) texture2D(iChannel0, (U)/R)
#define B(U) texture2D(iChannel1, (U)/R)

void XY(vec2 U, inout vec4 Q, vec4 q, vec2 R) {
    if (length(U - A(_21(q.x, R)).xy) < length(U - A(_21(Q.x, R)).xy)) Q.x = q.x;
}

void ZW(vec2 U, inout vec4 Q, vec4 q, vec2 R) {
    if (length(U - A(_21(q.y, R)).xy) < length(U - A(_21(Q.y, R)).xy)) Q.y = q.y;
}

void mainImage(out vec4 Q, in vec2 U) {
    vec2 R = iResolution;
    k = 0.02 * R.x * R.y;
    Q = B(U);

    // Propagate nearest particle info from neighbors
    for (int x = -1; x <= 1; x++) {
        for (int y = -1; y <= 1; y++) {
            XY(U, Q, B(U + vec2(float(x), float(y))), R);
        }
    }

    XY(U, Q, vec4(Q.x - 3.0), R);
    XY(U, Q, vec4(Q.x + 3.0), R);
    XY(U, Q, vec4(Q.x - 7.0), R);
    XY(U, Q, vec4(Q.x + 7.0), R);

    // Jump flood algorithm for fast voronoi
    int framemod = I - (I / 12) * 12;
    if (framemod == 0) {
        Q.y = _12(U, R);
    } else {
        float kk = exp2(float(11 - framemod));
        ZW(U, Q, B(U + vec2(0.0, kk)), R);
        ZW(U, Q, B(U + vec2(kk, 0.0)), R);
        ZW(U, Q, B(U - vec2(0.0, kk)), R);
        ZW(U, Q, B(U - vec2(kk, 0.0)), R);
    }

    XY(U, Q, Q.yxzw, R);

    if (I < 1) Q = vec4(_12(U, R));

    // Calculate distance to chain line segments
    vec4 a1 = A(_21(Q.x, R));
    vec4 a2 = A(_21(Q.x + 1.0, R));
    vec4 a3 = A(_21(Q.x - 1.0, R));
    float l1 = sg(U, a1.xy, a2.xy);
    float l2 = sg(U, a1.xy, a3.xy);
    float l = min(l1, l2);
    Q.z = Q.w = smoothstep(2.0, 1.0, l);
    Q.w -= 0.2 * heart(U, R);
}

//!BUFFER_C
// Horizontal Gaussian blur of the distance field
// iChannel0 = Buffer B

#define B(U) texture2D(iChannel0, (U)/R)

void mainImage(out vec4 Q, in vec2 U) {
    vec2 R = iResolution;
    Q = vec4(0.0);
    for (float x = -30.0; x <= 30.0; x++) {
        Q += G1(x, 10.0) * B(U + vec2(x, 0.0)).w;
    }
}

//!BUFFER_D
// Vertical Gaussian blur + temporal smoothing
// iChannel0 = Buffer C (horizontal blur)
// iChannel1 = Buffer D (self, previous frame)

#define C(U) texture2D(iChannel0, (U)/R)
#define D(U) texture2D(iChannel1, (U)/R)

void mainImage(out vec4 Q, in vec2 U) {
    vec2 R = iResolution;
    Q = vec4(0.0);
    for (float y = -30.0; y <= 30.0; y++) {
        Q += G1(y, 10.0) * C(U + vec2(0.0, y)).x;
    }

    // Temporal smoothing
    Q = mix(Q, D(U), 0.5);
}

//!IMAGE
// Final output - display the chain
// iChannel0 = Buffer A (not used)
// iChannel1 = Buffer B (distance field)

#define B(U) texture2D(iChannel1, (U)/R)

void mainImage(out vec4 Q, in vec2 U) {
    vec2 R = iResolution;
    Q = B(U).zzzz;
}
