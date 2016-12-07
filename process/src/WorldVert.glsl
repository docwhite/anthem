uniform mat4 transform;

attribute vec4 position;
attribute vec2 texCoord;

varying vec4 vertTexCoord;

void main() {
    gl_Position = transform * position;
    vertTexCoord = vec4(texCoord, 1.0, 1.0);
}
