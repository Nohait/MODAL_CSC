shader_type spatial;
render_mode unshaded;

uniform sampler2D pictogramme : source_color, filter_linear_mipmap;
uniform vec4 couleur : source_color = vec4(0.7, 0.035, 0.02, 1.0);

void fragment() {
	vec3 image = texture(pictogramme, UV).rgb;
	// Le blanc du personnage reste blanc ; seul le fond vert du fichier change de couleur.
	float blanc = smoothstep(0.65, 0.95, min(image.r, min(image.g, image.b)));
	ALBEDO = mix(couleur.rgb, vec3(0.95), blanc);
}
