// 3D Flame - Volumetric fire effect
// Created by anatole duprat - XT95/2013
// License Creative Commons Attribution-NonCommercial-ShareAlike 3.0 Unported License.
// Adapted for Live Wallpapers

precision highp float;

uniform float time;
uniform vec2 resolution;
uniform float detail;

float noise(vec3 p)
{
    vec3 i = floor(p);
    vec4 a = dot(i, vec3(1., 57., 21.)) + vec4(0., 57., 21., 78.);
    vec3 f = cos((p-i)*acos(-1.))*(-.5)+.5;
    a = mix(sin(cos(a)*a),sin(cos(1.+a)*(1.+a)), f.x);
    a.xy = mix(a.xz, a.yw, f.y);
    return mix(a.x, a.y, f.z);
}

float sphere(vec3 p, vec4 spr)
{
    return length(spr.xyz-p) - spr.w;
}

float flame(vec3 p, float t)
{
    float d = sphere(p*vec3(1.,.5,1.), vec4(.0,-1.,.0,1.));
    return d + (noise(p+vec3(.0,t*2.,.0)) + noise(p*3.)*.5)*.25*(p.y);
}

float scene(vec3 p, float t)
{
    return min(100.-length(p), abs(flame(p, t)));
}

vec4 raymarch(vec3 org, vec3 dir, float t)
{
    float d = 0.0, glow = 0.0, eps = 0.02;
    vec3 p = org;
    bool glowed = false;

    for(int i=0; i<64; i++)
    {
        d = scene(p, t) + eps;
        p += d * dir;
        if(d > eps)
        {
            if(flame(p, t) < .0)
                glowed = true;
            if(glowed)
                glow = float(i)/64.;
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

    vec3 org = vec3(0., -2., 4.);
    vec3 dir = normalize(vec3(v.x*1.6, -v.y, -1.5));

    vec4 p = raymarch(org, dir, time);
    float glow = p.w;

    vec4 col = mix(vec4(1.,.5,.1,1.), vec4(0.1,.5,1.,1.), p.y*.02+.4);

    gl_FragColor = mix(vec4(0.), col, pow(glow*2.,4.));
}
