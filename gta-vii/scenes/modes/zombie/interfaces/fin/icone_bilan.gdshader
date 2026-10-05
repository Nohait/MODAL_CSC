shader_type canvas_item;

varying vec4 modulation;
void vertex() {
	modulation = COLOR;
}

// Éclaircir les traits des pictogrammes sans modifier les SVG utilisés par les cartes.
void fragment() {
	COLOR = vec4(vec3(0.94, 0.85, 0.69), texture(TEXTURE, UV).a) * modulation;
}
