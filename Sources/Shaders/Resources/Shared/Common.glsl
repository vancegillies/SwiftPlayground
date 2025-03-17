vec2 getNormalizedUV(vec2 fragCoord, vec2 resolution) {
    float aspectRatio = resolution.x / resolution.y;

    vec2 uv;
    uv.x = (fragCoord.x / resolution.x - 0.5) * 2.0;
    uv.y = (fragCoord.y / resolution.y - 0.5) * 2.0;

    if (aspectRatio > 1.0) {
        uv.x *= aspectRatio;
    } else {
        uv.y /= aspectRatio;
    }

    return uv;
}

vec3 palette(float t) {
    vec3 a = vec3(0.5, 0.5, 0.5);
    vec3 b = vec3(0.5, 0.5, 0.5);
    vec3 c = vec3(1.0, 1.0, 1.0);
    vec3 d = vec3(0.263, 0.416, 0.557);
    return a + b * cos(6.28318 * (c * t + d));
}
