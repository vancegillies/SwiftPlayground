#version 330
#include "Shared/Common.glsl"

in vec2 fragTexCoord;
out vec4 finalColor;

uniform float time;
uniform vec2 resolution;

void main() {
    vec2 uv = getNormalizedUV(gl_FragCoord.xy, resolution);
    vec2 uv0 = uv;
    vec3 finalCol = vec3(0.0);

    for (int i = 0; i < 4; i++) {
        uv = fract(uv * 1.5) - 0.5;
        float d = length(uv) * exp(-length(uv0));
        vec3 col = palette(length(uv0) + i * 0.4 + time * 0.4);
        d = sin(d * 8.0 + time) / 8.0;
        d = abs(d);
        d = 0.02 / d;
        finalCol += col * d;
    }

    // Add some tone mapping to prevent overexposure
    finalCol = finalCol / (10.0 + finalCol);

    finalColor = vec4(finalCol, 1.0);
}
