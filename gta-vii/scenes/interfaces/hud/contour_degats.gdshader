shader_type canvas_item;

void fragment() {
	// Garder le centre dégagé : la couleur apparaît seulement près des bords.
	vec2 bord = abs(UV - vec2(0.5)) * 2.0;
	float intensite = smoothstep(0.65, 1.0, max(bord.x, bord.y));
	COLOR.a *= intensite;
}
