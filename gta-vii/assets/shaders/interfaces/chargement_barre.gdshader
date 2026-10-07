shader_type canvas_item;
// Bruit défilant inspiré de « 2D fire », Febucci / Godot Shaders (CC0).
// https://godotshaders.com/shader/2d-fire/
uniform sampler2D noise_tex : repeat_enable, filter_linear;
uniform float progression = 0.0;
uniform float vitesse = 0.8;
uniform vec2 dimensions = vec2(580.0, 74.0);
uniform float debordement = 20.0;

// Animation de davididev : https://opengameart.org/content/flame-particle-system (CC BY 3.0).
uniform sampler2D animation_flamme : filter_linear, repeat_disable;
vec4 particules(vec2 p, float longueur, float hauteur_barre, float temps) {
	vec4 resultat = vec4(0.0);
	float cellule = floor(p.x / 22.0);
	for (int i = -1; i <= 1; i++) {
		float numero = cellule + float(i);
		float graine = fract(sin(numero * 17.17 + 3.1) * 1031.3);
		float racine = (numero + 0.2 + graine * 0.6) * 22.0;
		if (racine < 2.0 || racine > longueur - 2.0) continue;
		for (int couche = 0; couche < 2; couche++) {
			float age = fract(temps * (0.75 + graine * 0.45) + graine + float(couche) * 0.5);
			vec2 centre = vec2(racine + sin(age * 4.0 + numero) * age * 6.0,
				hauteur_barre * 0.35 - age * debordement * 0.75);
			vec2 taille = vec2(46.0, 72.0) * mix(1.0, 0.55, age);
			vec2 uv = (p - centre) / taille + 0.5;
			if (uv.x < 0.0 || uv.x > 1.0 || uv.y < 0.0 || uv.y > 1.0) continue;
			float image = floor(mod(temps * 28.0 + graine * 64.0 + float(couche) * 21.0, 64.0));
			vec2 case_image = vec2(mod(image, 8.0), floor(image / 8.0));
			vec4 flamme = texture(animation_flamme, (case_image + uv) / 8.0);
			// La flamme s'éteint à mesure qu'elle quitte sa source, sans coupure à la fin de sa vie.
			flamme.a *= smoothstep(0.0, 0.12, age) * (1.0 - smoothstep(0.5, 1.0, age));
			flamme.a *= smoothstep(-debordement, -debordement + 5.0, p.y);
			resultat.rgb += flamme.rgb * flamme.a * (1.0 - resultat.a);
			resultat.a += flamme.a * (1.0 - resultat.a);
		}
	}
	return resultat;
}

void fragment() {
	vec2 p = UV * dimensions - vec2(debordement);
	vec2 taille = dimensions - vec2(debordement * 2.0);
	float temps = TIME * vitesse;
	float longueur = taille.x * progression;
	vec2 uv_feu = p / vec2(180.0, 110.0) + vec2(temps * 0.035, temps * 0.2);
	vec2 torsion = vec2(texture(noise_tex, uv_feu * 0.7).r,
		texture(noise_tex, uv_feu * 0.7 + vec2(0.37)).r) - 0.5;
	float bruit = texture(noise_tex, uv_feu + torsion * 0.28).r;
	float detail = texture(noise_tex, uv_feu * 1.9 + vec2(0.31, -temps * 0.04)).r;
	// Le remplissage reste plein. Le bruit ne joue ici que sur sa couleur.
	vec2 demi = vec2(max(longueur - 4.0, 0.0), taille.y - 4.0) * 0.5;
	vec2 q = abs(p - vec2(2.0) - demi) - max(demi - vec2(3.0), vec2(0.0));
	float distance = length(max(q, vec2(0.0))) + min(max(q.x, q.y), 0.0) - 3.0;
	float interieur = 1.0 - smoothstep(-1.5, 2.5, distance);
	float chaleur = smoothstep(0.26, 0.72, bruit * 0.8 + detail * 0.2);
	vec3 couleur = mix(vec3(0.85, 0.055, 0.008), vec3(1.0, 0.42, 0.018), chaleur);
	couleur = mix(couleur, vec3(1.0, 0.86, 0.32), pow(chaleur, 2.0));
	// Le feu intérieur reste opaque ; les émissions s'y fondent avant de s'en éloigner.
	vec4 flammes = particules(p, longueur, taille.y, temps);
	float alpha = interieur + flammes.a * (1.0 - interieur);
	vec3 emissions = flammes.rgb / max(flammes.a, 0.001);
	couleur = mix(couleur, emissions, flammes.a * (1.0 - interieur * 0.65));
	COLOR = vec4(couleur, alpha * step(0.001, progression));
}


