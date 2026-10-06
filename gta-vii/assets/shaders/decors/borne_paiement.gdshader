shader_type spatial;
uniform sampler2D couleur : source_color, filter_linear_mipmap;
uniform float intensite_ecran : hint_range(0.0, 5.0) = 1.8;
void fragment() {
	vec3 base = texture(couleur, UV).rgb;
	float gris = dot(base, vec3(0.299, 0.587, 0.114));
	// Atténuer le violet d'origine pour raccorder la borne au mobilier du parking.
	ALBEDO = mix(base, vec3(gris) * vec3(0.8, 0.9, 1.0), 0.65);
	ROUGHNESS = 0.65;
	// L'écran est peint dans l'atlas : seule cette partie émet de la lumière.
	float ecran = step(0.075, UV.x) * step(UV.x, 0.195) * step(0.75, UV.y) * step(UV.y, 0.85);
	EMISSION = base * ecran * intensite_ecran;
}
