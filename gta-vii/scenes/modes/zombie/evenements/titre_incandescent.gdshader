shader_type canvas_item;
uniform float horloge = 0.0;
// L'alpha du texte conserve les lettres ; la chaleur fait varier leur couleur.
void fragment() {
	vec4 lettre = texture(TEXTURE, UV) * COLOR;
	float chaleur = 0.5 + 0.5 * sin(UV.x * 35.0 - horloge * 3.0 + sin(UV.y * 18.0));
	lettre.rgb *= mix(vec3(1.0, 0.55, 0.28), vec3(1.15, 1.0, 0.8), chaleur);
	COLOR = lettre;
}
