#version 330
#include "Shared/Common.glsl"

in vec2 fragTexCoord;
out vec4 finalColor;

uniform float time;
uniform vec2 resolution;

void main()
{
    vec2 uv = gl_FragCoord.xy / resolution.xy;
    vec2 center = vec2(0.5, 0.5);
    float radius = 0.3;
    float lineWidth = 0.01;
    float dist = distance(uv, center);
    vec3 color = palette(time);

    float circle = smoothstep(radius + lineWidth, radius, dist) -
            smoothstep(radius, radius - lineWidth, dist);

    finalColor = vec4(color * circle, 1.0);
}
