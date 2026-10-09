shader_type canvas_item;

uniform sampler2D silhouette;
uniform float recharge : hint_range(0.0, 1.0) = 1.0;
uniform vec4 couleur_remplissage : source_color = vec4(0.75, 0.16, 0.1, 1.0);

void fragment() {
	vec4 contour = texture(TEXTURE, UV);
	// Remplir la silhouette de bas en haut, en gardant le métal clair devant.
	float niveau = mix(0.91, 0.08, recharge);
	float rempli = smoothstep(niveau - 0.008, niveau + 0.008, UV.y);
	if (recharge <= 0.0) rempli = 0.0;
	if (recharge >= 1.0) rempli = 1.0;
	float interieur = texture(silhouette, UV).a * rempli * couleur_remplissage.a;
	float alpha = contour.a + interieur * (1.0 - contour.a);
	// Reflets fixes et relief proches du cadre des jauges, sans halo envahissant.
	float reflet = exp(-abs(UV.y - (0.22 + UV.x * 0.25)) * 28.0);
	float relief = mix(1.25, 0.65, UV.y);
	vec3 metal = mix(vec3(1.0, 0.84, 0.53), vec3(0.72, 0.49, 0.23), UV.y);
	metal += vec3(reflet * 0.22);
	vec3 email = couleur_remplissage.rgb * relief + vec3(0.28, 0.16, 0.1) * reflet;
	vec3 teinte = (metal * contour.a + email * interieur * (1.0 - contour.a)) / max(alpha, 0.001);
	COLOR = vec4(teinte, alpha);
}
