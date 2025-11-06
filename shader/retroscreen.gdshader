shader_type canvas_item;
render_mode unshaded, blend_disabled;


uniform sampler2D screen_texture : hint_screen_texture;
uniform float crt_curve : hint_range(0.0, 1.0) = 0.02;
uniform float crt_scan_line_color : hint_range(0.0, 1.0) = 0.2;
uniform float aperture_grille_rate : hint_range(0.0, 1.0) = 0.6;
uniform float rf_switch_esque_blur : hint_range(0.0, 1.0) = 0.8;
uniform float white_noise_rate : hint_range(0.0, 1.0) = 0.0;


uniform float brightness : hint_range(-1, 1) = 0;
uniform float contrast : hint_range(0, 3) = 1.0;
uniform float saturation : hint_range(0, 3) = 1.0;
uniform float redVal : hint_range(0, 1) = 1.0;
uniform float greenVal : hint_range(0, 1) = 1.0;
uniform float blueVal : hint_range(0, 1) = 1.0;
uniform vec4 tint_color : source_color = vec4(1.0, 1.0, 1.0, 1.0);
uniform float tint_effect_factor : hint_range(0, 1) = 0.0;


mat4 contrastMatrix(float _contrast) {
    float t = (1.0 - _contrast) / 2.0;
    return mat4(
        vec4(_contrast, 0, 0, 0),
        vec4(0, _contrast, 0, 0),
        vec4(0, 0, _contrast, 0),
        vec4(t, t, t, 1)
    );
}

mat4 brightnessMatrix(float _brightness) {
    return mat4(
        vec4(1, 0, 0, 0),
        vec4(0, 1, 0, 0),
        vec4(0, 0, 1, 0),
        vec4(_brightness, _brightness, _brightness, 1)
    );
}

mat4 saturationMatrix(float _saturation) {
    vec3 luminance = vec3(0.3086, 0.6094, 0.0820);
    float oneMinusSat = 1.0 - _saturation;
    vec3 red = vec3(luminance.x * oneMinusSat);
    red += vec3(_saturation, 0, 0) * redVal;
    vec3 green = vec3(luminance.y * oneMinusSat);
    green += vec3(0, _saturation, 0) * greenVal;
    vec3 blue = vec3(luminance.z * oneMinusSat);
    blue += vec3(0, 0, _saturation) * blueVal;
    return mat4(vec4(red, 0), vec4(green, 0), vec4(blue, 0), vec4(0, 0, 0, 1));
}

float random(vec2 pos) {
    return fract(sin(dot(pos, vec2(12.9898, 78.233))) * 43758.5453);
}

void fragment() {

    vec2 crt_curve_shift = (vec2(1.0, 1.0) - sin(UV.yx * PI)) * crt_curve;
    vec2 crt_curve_scale = vec2(1.0, 1.0) + crt_curve_shift * 2.0;
    vec2 texture_fixed_uv = UV * crt_curve_scale - crt_curve_shift;
    vec2 fixed_uv = SCREEN_UV * crt_curve_scale - crt_curve_shift;


    float enable_color = float( 0.0 <= texture_fixed_uv.x && texture_fixed_uv.x <= 1.0 && 0.0 <= texture_fixed_uv.y && texture_fixed_uv.y <= 1.0 );
    vec4 base_color = vec4((texture(screen_texture, fixed_uv).rgb * (1.0 - rf_switch_esque_blur * 0.5)) +
                      ((texture(screen_texture, fixed_uv + vec2(-SCREEN_PIXEL_SIZE.x * 3.1, 0.0)).rgb +
                        texture(screen_texture, fixed_uv + vec2(SCREEN_PIXEL_SIZE.x * 3.1, 0.0)).rgb) * (rf_switch_esque_blur * 0.25) * 0.5), 1.0) * enable_color;


    vec2 aperture_grille_pixel = vec2(floor((fixed_uv.x / SCREEN_PIXEL_SIZE.x) / 3.0) * 3.0, fixed_uv.y);
    float white_noise = random(aperture_grille_pixel + vec2(sin(TIME * 0.543254), cos(TIME * 0.254323563)));
    base_color.rgb = mix(base_color.rgb, vec3(white_noise), white_noise_rate * enable_color);


    float aperture_grille_point = mod(((SCREEN_UV.x * crt_curve_scale.x) - crt_curve_shift.x) / SCREEN_PIXEL_SIZE.x, 3.0);
    float aperture_grille_r_rate = clamp(1.0 - aperture_grille_point, 0.0, 1.0) + clamp(aperture_grille_point - 2.0, 0.0, 1.0);
    float aperture_grille_g_rate = clamp(1.0 - abs(1.0 - aperture_grille_point), 0.0, 1.0);
    float aperture_grille_b_rate = 1.0 - aperture_grille_r_rate - aperture_grille_g_rate;
    base_color.rgb *= vec3(clamp(aperture_grille_r_rate, aperture_grille_rate, 1.0),
                           clamp(aperture_grille_g_rate, aperture_grille_rate, 1.0),
                           clamp(aperture_grille_b_rate, aperture_grille_rate, 1.0));


    base_color = mix(base_color, vec4(0.0, 0.0, 0.0, 1.0), float(0 == int(fixed_uv.y / SCREEN_PIXEL_SIZE.y) % 2) * crt_scan_line_color);

    vec4 final_color = brightnessMatrix(brightness) * contrastMatrix(contrast) * saturationMatrix(saturation) * mix(base_color, base_color * tint_color, tint_effect_factor);
    COLOR = final_color * enable_color;
}