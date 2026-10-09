shader_type spatial;
render_mode cull_disabled, specular_disabled;

uniform sampler2D texture_beton : source_color, filter_linear_mipmap, repeat_enable;
uniform vec4 couleur_beton : source_color = vec4(0.45, 0.45, 0.43, 1.0);
uniform float taille_texture : hint_range(0.2, 3.0) = 1.2;
varying vec3 position_locale;
varying vec3 normale_locale;

void vertex() {
	position_locale = VERTEX;
	normale_locale = NORMAL;
}

void fragment() {
	// Projeter la texture sur les faces verticales, sans l'étirer sur chaque segment.
	vec2 coordonnees = abs(normale_locale.x) > abs(normale_locale.z)
		? position_locale.zy : position_locale.xy;
	vec3 beton = texture(texture_beton, coordonnees * taille_texture).rgb;
	beton = mix(beton, vec3(dot(beton, vec3(0.2126, 0.7152, 0.0722))), 0.8);
	float grain = fract(sin(dot(floor(position_locale.xz * 9.0), vec2(12.9898, 78.233))) * 43758.5453);
	float charbon = smoothstep(0.05, 0.7, UV.y + grain * 0.2);
	ALBEDO = mix(beton * couleur_beton.rgb, vec3(0.025, 0.021, 0.018), charbon * 0.45);
	ROUGHNESS = 0.95;
	// La tranche reçoit la lumière en haut et se perd progressivement dans le vide.
	ALBEDO *= mix(1.0, 0.2, smoothstep(0.35, 1.0, UV.y));
}
