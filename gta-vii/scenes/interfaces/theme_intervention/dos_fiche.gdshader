shader_type canvas_item;
varying vec4 modulation;
void vertex() { modulation = COLOR; }
void fragment() {
	// Support identique pour toutes les raretés avant le retournement.
	vec2 p = UV * vec2(320.0, 500.0);
	float bord = min(min(p.x, 320.0 - p.x), min(p.y, 500.0 - p.y));
	vec3 couleur = vec3(0.118, 0.165, 0.192);
	float cadre = step(12.0, bord) * (1.0 - step(13.0, bord));
	couleur = mix(couleur, vec3(0.286, 0.357, 0.388), cadre);
	vec2 centre = abs(p - vec2(160.0, 225.0));
	float croix = max((1.0 - step(8.0, centre.x)) * (1.0 - step(32.0, centre.y)), (1.0 - step(32.0, centre.x)) * (1.0 - step(8.0, centre.y)));
	couleur = mix(couleur, vec3(0.675, 0.729, 0.749), croix);
	COLOR = vec4(couleur, step(2.0, bord)) * modulation;
}
