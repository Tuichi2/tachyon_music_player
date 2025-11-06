shader_type canvas_item;

uniform vec4 rect_color : source_color = vec4(1.0, 0.0, 0.0, 1.0);
uniform float white_threshold : hint_range(0.8, 1.0) = 0.95;
uniform sampler2D background_texture;

void fragment() {
    // Usar una textura personalizada como fondo
    vec4 bg_color = texture(background_texture, UV);

    bool is_white = (bg_color.r > white_threshold) &&
                    (bg_color.g > white_threshold) &&
                    (bg_color.b > white_threshold);

    if (is_white) {
        COLOR = vec4(1.0, 1.0, 1.0, 1.0);
    } else {
        COLOR = rect_color;
    }
}