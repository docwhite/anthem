#ifdef GL_ES
precision mediump float;
precision mediump int;
#endif

#define PI 3.14159265358979323846

uniform float Time;
uniform float Pitch;
uniform float Yaw;
uniform float Roll;
uniform vec2 Resolution;
uniform sampler2D texture;

varying vec4 vertTexCoord;

float r(vec2 n) {
    return fract(cos(dot(n,vec2(36.26,73.12)))*354.63);
}

float noise(vec2 n)
{
    vec2 fn = floor(n);
    vec2 sn = smoothstep(0.,1.,fract(n));

    float h1 = mix(r(fn),           r(fn+vec2(1,0)), sn.x);
    float h2 = mix(r(fn+vec2(0,1)), r(fn+1.)       , sn.x);
    return mix(h1,h2,sn.y);
}

float perlin(vec2 n) {
    return noise(n/32.)*0.5875+noise(n/16.)/5.+noise(n/8.)/10.+noise(n/4.)/20.+noise(n/2.)/40.+noise(n)/80.;
}

float calculate(vec2 p)
{
	vec2 c = vec2(-0.745+0.01*sin(Pitch), 0.186+0.02*cos(Yaw));

	vec2 z = p;
	vec2 dz = vec2(1.0, 0.0);

	float dist = 1e20;

	for (int i = 0; i < 128; i++)
	{
		dz = 2.0 * vec2(z.x*dz.x - z.y*dz.y, z.x*dz.y + z.y*dz.x);
		z = vec2(z.x*z.x - z.y*z.y, 2.0*z.x*z.y) + c;
		if (dot(z,z) > 200.0) break;
	}

	float d = sqrt(dot(z,z) / dot(dz,dz)) * log(dot(z,z));
	return clamp( 150*d, 0.0, 1.0 );
}

void main() {
	vec2 p = gl_FragCoord.xy / Resolution.xy;
	p = -1.0 + 2.0*p;
	p.x *= Resolution.x/Resolution.y;
	float t = calculate(p);

	vec4 color = vec4(t, t, t, 1.0);
	vec4 image = texture2D(texture, vertTexCoord.st);

	gl_FragColor = vec4(vec3(perlin(Time*16.+gl_FragCoord.xy/2.)),1.0);
}
