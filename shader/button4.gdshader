shader_type canvas_item;

uniform float strength : hint_range(0.0, 0.05) = 0.02;
uniform float speed : hint_range(0.0, 2.0) = 0.5;
uniform float frequency : hint_range(0.0, 50.0) = 20.0;
uniform vec4 tint_color : source_color = vec4(0.3, 0.5, 0.8, 0.2);

uniform sampler2D SCREEN_TEXTURE : hint_screen_texture, filter_linear_mipmap;

void fragment() {
    vec2 distortion = vec2(
        sin(TIME * speed + UV.y * frequency) * strength,
        cos(TIME * speed * 0.7 + UV.x * frequency * 1.3) * strength
    );


    vec4 screen_color = texture(SCREEN_TEXTURE, SCREEN_UV + distortion);


    COLOR = mix(screen_color, tint_color, tint_color.a);
}