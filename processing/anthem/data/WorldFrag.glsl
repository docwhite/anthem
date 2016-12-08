#ifdef GL_ES
precision mediump float;
precision mediump int;
#endif

#define PI 3.14159265358979323846

uniform float ColorMult;
uniform float ColorPower;
uniform vec2  Offset;
uniform float Pitch;
uniform float Roll;
uniform vec2  Resolution;
uniform float Time;
uniform float Yaw;
uniform float Zoom;

uniform sampler2D texture;

varying vec4 vertTexCoord;

void main() {
    vec2 fragCoord = gl_FragCoord.xy;
    vec2 p = Zoom * fragCoord / Resolution + Offset;
    p.x *= Resolution.x / Resolution.y;

    float real = 0.5 * cos(Pitch + 0.006 * cos(Time));
    float imag = 0.5 * sin(Yaw   + 0.006 * sin(Time));
    vec2 cc = vec2( real, imag );
    cc *= 1.1;

    vec4 dm = vec4(2000.0);
    float d1 = 1000.0; // based on sine of imaginary part
    float d2 = 1000.0; // based on sine of real part
    float d3 = 1000.0; // distance to origin
    float d4 = 1000.0; // based on the fractional decimals of the complex number
    vec2 z = (-1.0 + 2.0 * p);
    for(int i = 0; i < 32; i++)
    {
        z = cc + vec2( z.x*z.x - z.y*z.y, 2.0*z.x*z.y );
        d1 = min(d1, abs(z.y + sin(z.y)));
        d2 = min(d2, abs(1.0+z.x + 0.5*sin(z.x)));
        d3 = min(d3, dot(z,z));
        d4 = min(d4, length(fract(z)-0.5));

    }
    vec3 color;

    vec3 image_sample_1 = texture(texture, vec2(0.2)).xyz;
    vec3 image_sample_2 = texture(texture, vec2(0.5)).xyz;
    vec3 image_sample_3 = texture(texture, vec2(0.8)).xyz;

    vec3 image = texture(texture, clamp(pow(abs(z.xy), vec2(0.5)), vec2(0.0), vec2(1.0))).xyz;

    color = vec3(d4);
    color = mix( color, image_sample_1, min(1.0,pow(d1*0.25,0.20)) );
    color = mix( color, image_sample_2, min(1.0,pow(d2*0.50,0.50)) );
    color = mix( color, image_sample_3, 1.0 - min(1.0,pow(d3,0.15) ));

    color = mix( color, image.xyz, pow(d3, 0.3) );
    color = ColorMult * pow(color, vec3(ColorPower));
    color = clamp( color, vec3(0.0), vec3(1.0) );

    gl_FragColor = vec4(color, 1.0);
}