shader_type canvas_item;


/* ---------- PARAMÈTRES ---------- */

uniform vec4 ember_color : source_color =
	vec4(1.0, 0.12, 0.015, 1.0);

uniform vec4 hot_color : source_color =
	vec4(1.0, 0.72, 0.08, 1.0);

uniform vec4 burnt_color : source_color =
	vec4(0.10, 0.01, 0.005, 1.0);

uniform float border_size : hint_range(0.005, 0.10) = 0.022;

uniform float glow_size : hint_range(0.005, 0.15) = 0.045;

uniform float irregularity : hint_range(0.0, 1.0) = 0.55;

uniform float animation_speed : hint_range(0.0, 3.0) = 0.35;


/* ---------- BRUIT ---------- */

float random_1d(float value) {
	return fract(
		sin(value * 91.3458) * 47453.5453
	);
}


float noise_1d(float value) {
	float i = floor(value);
	float f = fract(value);

	float a = random_1d(i);
	float b = random_1d(i + 1.0);

	f = f * f * (3.0 - 2.0 * f);

	return mix(a, b, f);
}


/* ---------- SHADER PRINCIPAL ---------- */

void fragment() {
	vec2 uv = UV;


	// Distance au bord rectangulaire le plus proche.
	float edge_distance = min(
		min(uv.x, 1.0 - uv.x),
		min(uv.y, 1.0 - uv.y)
	);


	// Bruit lent + bruit de détail.
	float position =
		uv.x * 8.7 +
		uv.y * 13.1;

	float large_noise = noise_1d(
		position * 2.5 +
		TIME * animation_speed
	);

	float detail_noise = noise_1d(
		position * 11.0 -
		TIME * animation_speed * 1.4
	);

	float ember_noise =
		large_noise * 0.7 +
		detail_noise * 0.3;


	// Le bruit fait varier l'épaisseur du bord.
	float local_border =
		border_size *
		mix(
			1.0 - irregularity,
			1.0 + irregularity,
			ember_noise
		);


	// Partie principale de la braise.
	float core =
		1.0 -
		smoothstep(
			local_border * 0.35,
			local_border,
			edge_distance
		);


	// Halo plus large et moins opaque.
	float glow =
		1.0 -
		smoothstep(
			local_border,
			local_border + glow_size,
			edge_distance
		);


	// Certaines zones deviennent très chaudes.
	float heat =
		smoothstep(
			0.58,
			0.88,
			ember_noise
		);


	// D'autres sont presque carbonisées.
	float burnt =
		1.0 -
		smoothstep(
			0.18,
			0.42,
			ember_noise
		);


	// Couleur de base.
	vec3 final_color = ember_color.rgb;

	final_color = mix(
		final_color,
		burnt_color.rgb,
		burnt * 0.85
	);

	final_color = mix(
		final_color,
		hot_color.rgb,
		heat
	);


	// Transparence finale.
	float final_alpha =
		core * (0.75 + heat * 0.25) +
		glow * 0.22;


	COLOR = vec4(
		final_color,
		clamp(final_alpha, 0.0, 1.0)
	);
}