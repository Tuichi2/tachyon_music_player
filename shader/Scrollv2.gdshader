shader_type canvas_item;

// ---- Scroll Shader Parameters ----
uniform float scroll_speed : hint_range(0.0, 10.0) = 1.0;
uniform vec2 scroll_direction = vec2(1.0, 0.0);

// ---- 3D Rotation Parameters ----
uniform bool isInRadians = false;

// Radian-based rotation
group_uniforms ShaderParameters.RadianRotation;
uniform float xRadians : hint_range(0, 6.2830);
uniform float yRadians : hint_range(0, 6.2830);
uniform float zRadians : hint_range(0, 6.2830);

// Degree-based rotation
group_uniforms ShaderParameters.DegreesRotation;
uniform float xDegrees : hint_range(0, 360);
uniform float yDegrees : hint_range(0, 360);
uniform float zDegrees : hint_range(0, 360);

// ---- Helper Functions ----
float degToRad(float angle) {
    return angle * PI / 180.0;
}

varying vec4 node_color;

void vertex() {
	node_color = COLOR;
    // Handle rotation parameters
    float radX = xRadians;
    float radY = yRadians;
    float radZ = zRadians;

    if (!isInRadians) {
        radX = degToRad(xDegrees);
        radY = degToRad(yDegrees);
        radZ = degToRad(zDegrees);
    }

    // Compute rotation matrix
    float cosX = cos(radX), cosY = cos(radY), cosZ = cos(radZ);
    float sinX = sin(radX), sinY = sin(radY), sinZ = sin(radZ);

    mat3 finalRot;
    finalRot[0][0] = cosZ * cosY;
    finalRot[1][0] = cosZ * sinY * sinX - sinZ * cosX;
    finalRot[2][0] = sinZ * sinX + cosZ * sinY * cosX;

    finalRot[0][1] = sinZ * cosY;
    finalRot[1][1] = cosZ * cosX + sinZ * sinY * sinX;
    finalRot[2][1] = sinZ * sinY * cosX - cosZ * sinX;

    finalRot[0][2] = -sinY;
    finalRot[1][2] = cosY * sinX;
    finalRot[2][2] = cosY * cosX;

    // Apply rotation to the vertex
    vec3 pos = vec3(VERTEX.xy, 0.0) * finalRot;
    VERTEX = pos.xy;
}

void fragment() {
    vec2 uv = UV + scroll_direction * scroll_speed * TIME;
    uv = mod(uv, vec2(1.0));
    vec4 sprite_color = texture(TEXTURE, uv);
    COLOR = sprite_color * node_color;
}
