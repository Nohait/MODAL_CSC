// Adapté de « 2D fire », Godot Shaders / Febucci, code sous licence CC0.
// https://godotshaders.com/shader/2d-fire/
shader_type canvas_item;

uniform sampler2D bruit_feu : repeat_enable, filter_linear;
uniform vec4 couleur_coeur : source_color = vec4(1.0, 0.88, 0.42, 1.0);
uniform vec4 couleur_flame : source_color = vec4(1.0, 0.36, 0.045, 1.0);
uniform vec4 couleur_bord : source_color = vec4(0.65, 0.065, 0.015, 1.0);
uniform float vitesse : hint_range(0.1, 2.0) = 0.55;
uniform float opacite : hint_range(0.0, 1.0) = 0.8;

void fragment() {
	// Le bruit remonte ; le gradient laisse une base pleine et découpe des pointes.
	vec2 coord = UV * vec2(2.8, 1.0) + vec2(0.0, TIME * vitesse);
	float bruit = texture(bruit_feu, coord).r;
	float gradient = pow(UV.y, 0.8) * 1.12;
	gradient -= smoothstep(0.28, 0.5, abs(UV.x - 0.5)) * 0.7;
	float bord = smoothstep(bruit - 0.025, bruit + 0.025, gradient);
	float flamme = smoothstep(bruit + 0.12, bruit + 0.18, gradient);
	float coeur = smoothstep(bruit + 0.32, bruit + 0.38, gradient);
	vec3 couleur = mix(couleur_bord.rgb, couleur_flame.rgb, flamme);
	couleur = mix(couleur, couleur_coeur.rgb, coeur);
	// Fondu de la base pour éviter une coupure rectangulaire sous le titre.
	float masque = 1.0 - smoothstep(0.78, 1.0, UV.y);
	COLOR = vec4(couleur, bord * masque * opacite);
}
