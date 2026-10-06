shader_type canvas_item;
uniform vec4 teinte : source_color = vec4(1.0);
uniform float survol = 0.0;
varying vec4 modulation;

void vertex() {
	modulation = COLOR;
}

void fragment() {
	vec4 dessin = texture(TEXTURE, UV);
	// Les variations d'alpha sur le contour simulent une arête éclairée et son ombre.
	vec2 pas = TEXTURE_PIXEL_SIZE * 1.5;
	float relief = texture(TEXTURE, UV - pas).a - texture(TEXTURE, UV + pas).a;
	float reflet = 0.5 + 0.5 * sin(UV.y * 4.0 - UV.x * 2.0);
	vec3 metal = mix(teinte.rgb * 0.6, mix(teinte.rgb, vec3(1.0), 0.65), reflet);
	metal += relief * 0.35 + survol * 0.12;
	COLOR = vec4(metal, dessin.a) * modulation;
}
