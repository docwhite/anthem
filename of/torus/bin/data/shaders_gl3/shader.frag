#version 150

uniform float time;

out vec4 fragColor;

void main(){
	fragColor = vec4(0.9, sin(time), 0.0, 1.0);
}
