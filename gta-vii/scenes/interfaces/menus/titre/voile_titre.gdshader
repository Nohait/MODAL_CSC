shader_type canvas_item;

void fragment() {
	// Le bord gauche masque doucement le raccord entre texte et scène 3D.
	float gauche = 1.0 - smoothstep(0.30, 0.57, UV.x);
	float bord = pow(abs(UV.y - 0.5) * 2.0, 3.0) * 0.48;
	COLOR = vec4(vec3(0.035, 0.025, 0.023), max(gauche, bord));
}
