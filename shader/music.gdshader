shader_type canvas_item;
render_mode unshaded;

uniform sampler2D tex;
uniform float hz0;
uniform float hz1;
uniform float hz2;
uniform float hz3;
uniform float hz4;
uniform float hz5;
uniform float hz6;
uniform float hz7;
uniform float hz8;
uniform float hz9;
uniform float hz10;
uniform float hz11;
uniform float hz12;
uniform float hz13;
uniform float hz14;
uniform float hz15;
uniform float hz16;
uniform float hz17;
uniform float hz18;
uniform float hz19;
uniform float hz20;
uniform float hz21;
uniform float hz22;
uniform float hz23;
uniform float hz24;
uniform float hz25;
uniform float hz26;
uniform float hz27;
uniform float hz28;
uniform float hz29;
uniform float hz30;
uniform float hz31;

float get_band(float x) {
	int band = int(floor(x * 32.0));
	float local = fract(x * 32.0);
	float a = 0.0;
	float b = 0.0;

	// Acceso directo al valor según el índice
	if (band == 0) { a = hz0; b = hz1; }
	else if (band == 1) { a = hz1; b = hz2; }
	else if (band == 2) { a = hz2; b = hz3; }
	else if (band == 3) { a = hz3; b = hz4; }
	else if (band == 4) { a = hz4; b = hz5; }
	else if (band == 5) { a = hz5; b = hz6; }
	else if (band == 6) { a = hz6; b = hz7; }
	else if (band == 7) { a = hz7; b = hz8; }
	else if (band == 8) { a = hz8; b = hz9; }
	else if (band == 9) { a = hz9; b = hz10; }
	else if (band == 10) { a = hz10; b = hz11; }
	else if (band == 11) { a = hz11; b = hz12; }
	else if (band == 12) { a = hz12; b = hz13; }
	else if (band == 13) { a = hz13; b = hz14; }
	else if (band == 14) { a = hz14; b = hz15; }
	else if (band == 15) { a = hz15; b = hz16; }
	else if (band == 16) { a = hz16; b = hz17; }
	else if (band == 17) { a = hz17; b = hz18; }
	else if (band == 18) { a = hz18; b = hz19; }
	else if (band == 19) { a = hz19; b = hz20; }
	else if (band == 20) { a = hz20; b = hz21; }
	else if (band == 21) { a = hz21; b = hz22; }
	else if (band == 22) { a = hz22; b = hz23; }
	else if (band == 23) { a = hz23; b = hz24; }
	else if (band == 24) { a = hz24; b = hz25; }
	else if (band == 25) { a = hz25; b = hz26; }
	else if (band == 26) { a = hz26; b = hz27; }
	else if (band == 27) { a = hz27; b = hz28; }
	else if (band == 28) { a = hz28; b = hz29; }
	else if (band == 29) { a = hz29; b = hz30; }
	else { a = hz30; b = hz31; }

	// Interpolacion suave entre bandas
	return smoothstep(0.0, 1.0, mix(a, b, local));
}

void fragment() {
	float value = get_band(UV.x);
	float alpha = smoothstep(value, value - 0.015, 1.0 - UV.y);

	vec4 tex_color = texture(tex, vec2(UV.x, 0.0));

	COLOR = tex_color * COLOR * alpha;
}
