shader_type canvas_item;

uniform sampler2D plastique : source_color, repeat_enable, filter_linear_mipmap;
uniform vec2 taille = vec2(320.0, 70.0);
uniform float intensite : hint_range(0.0, 1.0) = 0.48;

void fragment() {
	vec4 cadre = texture(TEXTURE, UV);
	vec3 matiere = texture(plastique, UV * taille / 360.0).rgb;
	float luminosite = dot(matiere, vec3(0.2126, 0.7152, 0.0722));
	float relief = clamp(0.72 + luminosite * 3.7, 0.72, 1.45);
	float luminosite_cadre = dot(cadre.rgb, vec3(0.2126, 0.7152, 0.0722));
	float zone_fond = smoothstep(0.105, 0.145, luminosite_cadre) * (1.0 - smoothstep(0.28, 0.48, luminosite_cadre));
	cadre.rgb *= mix(1.0, relief, intensite * zone_fond);
	COLOR = cadre * COLOR;
}
