shader_type spatial;

uniform sampler2D couleur : source_color, filter_linear_mipmap, repeat_enable;
uniform vec4 teinte : source_color = vec4(0.4, 0.43, 0.48, 1.0);
uniform float taille_texture : hint_range(0.5, 6.0) = 1.7;
varying vec3 position_monde;

void vertex() {
	position_monde = (MODEL_MATRIX * vec4(VERTEX, 1.0)).xyz;
}

void fragment() {
	vec2 uv = position_monde.xz / taille_texture;
	// Deux lectures décalées atténuent les grandes fissures répétées de cette texture.
	vec3 a = texture(couleur, uv).rgb;
	vec3 b = texture(couleur, vec2(-uv.y, uv.x) * 0.73 + vec2(0.37, 0.61)).rgb;
	float variation = 0.92 + 0.08 * sin(position_monde.x * 0.13 + sin(position_monde.z * 0.09));
	ALBEDO = mix(a, b, 0.5) * teinte.rgb * variation;
	ROUGHNESS = 0.96;
	SPECULAR = 0.05;
}
