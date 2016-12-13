#ifdef GL_ES
precision mediump float;
precision mediump int;
#endif

uniform float Time;
uniform vec2  Resolution;
uniform float Pitch;
uniform float Roll;

const float Detail = 0.0025;

mat4 Rot4X(float a) {
    float c = cos(a);
    float s = sin(a);
    
    return mat4( 1, 0, 0, 0,
                 0, c,-s, 0,
                 0, s, c, 0,
                 0, 0, 0, 1);
}

mat4 Rot4Z(float a) {
    float c = cos(a);
    float s = sin(a);
    
    return mat4( c,-s, 0, 0,
                 s, c, 0, 0,
                 0, 0, 1, 0,
                 0, 0, 0, 1);
}


float sdTorus(vec3 p, vec2 t, vec3 c) {
    p -= c;
    vec2 q = vec2(length(p.xz) - t.x, p.y);
    return length(q) - t.y;
}

float sdSphere(vec3 p, vec3 c, float rad) {
    return length(p-c) - rad;
}

float sdPlane(vec3 p) {
    return p.y + 0.5;
}

float map(vec3 p) {
    mat4 rotX = Rot4X(Pitch);
    mat4 rotZ = Rot4Z(Roll);
    vec4 rotated = rotX * rotZ * vec4(p, 1.0);
    float torus = sdTorus(rotated.xyz, vec2(0.3, 0.1), vec3(0.0, 0.1, 0.0));
    float sphere = sdSphere(p, vec3(cos(Time), 0.0, sin(Time)), 0.5);
    float plane = sdPlane(p);
    
    
    
    return min(torus, plane);
}

vec3 normal(vec3 p) {
    vec2 e = vec2(0.0, Detail);
    return -normalize(vec3(
        map(p-e.yxx)-map(p+e.yxx),
        map(p-e.xyx)-map(p+e.xyx),
        map(p-e.xxy)-map(p+e.xxy)
    ));
}

float softShadow(in vec3 ro, in vec3 rd, float mint, float k) {
    float res = 1.0;
    float t = mint;
    for(int i = 0; i < 32; i++) {
        float h = map(ro + rd * t);
        if (h < 0.001) { return 0.0; }
        res = min(res, k*h/t);
        t += h;
    }
    return res;
}

float spotLight(vec3 p, vec3 n) {
    vec3 spotDir = normalize(vec3(0.0, -1.0, 0.0));
    vec3 spotPos = vec3(0.0, 1.0, 0.0);
    float coneAngle = 20.0;
    float coneDelta = 30.0;
    
    vec3 lray = normalize(spotPos - p);
    float falloff = (dot(lray, -spotDir) - cos(radians(coneDelta))) / (cos(radians(coneAngle)) - cos(radians(coneDelta)));
    float diffuse = max(0.0, dot(lray, n));
    float sh = softShadow(p, lray, 0.01, 32.0);
    return diffuse * falloff * sh;
}

float light(vec3 p, vec3 dir) {
    vec3 n = normal(p);
    float diffuse = spotLight(p, n);
    return diffuse;
}

float trace(vec3 ro, vec3 rd) {
    float t = 0.0;
    float d = 1.0;
    vec3 p;
    for (int i = 0; i < 128; ++i) {
        if (d > Detail && t < 50.0) {
            p = ro + rd * t;
            d = map(p);
            t += d;
        }
    }
    float bg = 0.0;
    float col;
    if (d < Detail) {
        col = light(p-Detail*rd, rd);
    } else {
        col = bg;    
    }
    return col;
}

mat3 setCamera( in vec3 ro, in vec3 ta)
{
    vec3 cw = normalize(ta-ro);
    vec3 cp = normalize(vec3(0.0, 1.0, 0.0));
    vec3 cu = normalize( cross(cw,-cp) );
    vec3 cv = normalize( cross(cu,-cw) );
    return mat3( cu, cv, cw );
}

void main() {
    vec2 fragCoord = gl_FragCoord.xy;
    vec2 uv = fragCoord.xy / Resolution.xy * 2.0 - 1.0;
    uv.y *= Resolution.y / Resolution.x;

    // Camera   
    vec3 ro = vec3(0.0, 1.0, -3.5);
    vec3 ta = vec3(0.0);
    mat3 ca = setCamera(ro, ta);
    vec3 rd = ca * normalize(vec3(uv.xy, 2.0));
    
    float t = trace(ro, rd);
    //float fog = 1.0 / (1.0 + t * t * 0.1);
    //vec3 fc = vec3(fog);
    //fragColor = vec4(fc,1.0);
    gl_FragColor = vec4(t, t, t, 1.0); 
}