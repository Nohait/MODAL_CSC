shader_type canvas_item;

uniform sampler2D silhouette;
uniform float recharge : hint_range(0.0, 1.0) = 1.0;
uniform vec4 couleur_remplissage : source_color = vec4(0.75, 0.16, 0.1, 1.0);

void fragment() {
	vec4 contour = texture(TEXTURE, UV);
	// Remplir la silhouette de bas en haut, en gardant le contour clair devant.
	float niveau = mix(0.91, 0.08, recharge);
	float rempli = smoothstep(niveau - 0.008, niveau + 0.008, UV.y);
	if (recharge <= 0.0) rempli = 0.0;
	if (recharge >= 1.0) rempli = 1.0;
	float interieur = texture(silhouette, UV).a * rempli * couleur_remplissage.a;
	float alpha = contour.a + interieur * (1.0 - contour.a);
	vec3 teinte = (contour.rgb * contour.a + couleur_remplissage.rgb * interieur * (1.0 - contour.a)) / max(alpha, 0.001);
	COLOR = vec4(teinte, alpha);
}
