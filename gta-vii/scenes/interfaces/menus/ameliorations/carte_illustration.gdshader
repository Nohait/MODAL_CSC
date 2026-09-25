shader_type canvas_item;


// Rayon horizontal des coins, en UV.
// 0.15 = 15 % de la largeur.
uniform float radius_x : hint_range(0.0, 0.5, 0.01) = 0.20;

// Rayon vertical.
// Différent de radius_x car notre zone n'est pas carrée.
uniform float radius_y : hint_range(0.0, 0.5, 0.01) = 0.20;


void fragment() {
	vec2 uv = UV;

	// Godot nous donne la couleur originale de l'image.
	vec4 image_color = texture(TEXTURE, uv);

	float mask = 1.0;


	/* ---------- COIN HAUT-GAUCHE ---------- */

	if (uv.x < radius_x && uv.y < radius_y) {

		vec2 p = vec2(
			uv.x / radius_x,
			uv.y / radius_y
		);

		// Centre du quart de cercle : (1, 1)
		float distance_to_center =
			length(p - vec2(1.0));

		if (distance_to_center > 1.0) {
			mask = 0.0;
		}
	}


	/* ---------- COIN HAUT-DROIT ---------- */

	if (uv.x > 1.0 - radius_x && uv.y < radius_y) {

		vec2 p = vec2(
			(1.0 - uv.x) / radius_x,
			uv.y / radius_y
		);

		float distance_to_center =
			length(p - vec2(1.0));

		if (distance_to_center > 1.0) {
			mask = 0.0;
		}
	}


	/* ---------- COIN BAS-GAUCHE ---------- */

	if (uv.x < radius_x && uv.y > 1.0 - radius_y) {

		vec2 p = vec2(
			uv.x / radius_x,
			(1.0 - uv.y) / radius_y
		);

		float distance_to_center =
			length(p - vec2(1.0));

		if (distance_to_center > 1.0) {
			mask = 0.0;
		}
	}


	/* ---------- COIN BAS-DROIT ---------- */

	if (
		uv.x > 1.0 - radius_x &&
		uv.y > 1.0 - radius_y
	) {

		vec2 p = vec2(
			(1.0 - uv.x) / radius_x,
			(1.0 - uv.y) / radius_y
		);

		float distance_to_center =
			length(p - vec2(1.0));

		if (distance_to_center > 1.0) {
			mask = 0.0;
		}
	}


	// On ne modifie que la transparence de l'image.
	image_color.a *= mask;

	COLOR = image_color;
}