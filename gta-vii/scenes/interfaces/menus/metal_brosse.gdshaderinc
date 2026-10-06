// Finition commune, calculée en pixels pour les petits et grands boutons.
vec3 metal_brosse(vec2 uv, vec2 dimensions, float accent) {
	vec2 p = uv * dimensions;
	vec2 bord = min(p, dimensions - p);
	float distance = min(bord.x, bord.y);
	float brossage = sin(p.y * 2.1) * 0.009 + sin(p.y * 0.63 + sin(p.x * 0.04)) * 0.006;
	float lumiere = exp(-pow((uv.y - 0.22) / 0.32, 2.0));
	vec3 acier = mix(vec3(0.10, 0.125, 0.15), vec3(0.38, 0.42, 0.45), lumiere);
	acier += brossage + accent * vec3(0.07, 0.075, 0.08);
	// Un filet sombre encadre le biseau clair ; le bas reçoit une ombre.
	float cadre = 1.0 - smoothstep(5.0, 7.0, distance);
	float relief = exp(-abs(distance - 3.0) * 1.0);
	vec3 rebord = vec3(0.12, 0.105, 0.085) + relief * vec3(0.42, 0.32, 0.20);
	rebord += exp(-abs(p.y - 3.0) * 0.6) * 0.22;
	acier = mix(acier, rebord, cadre);
	acier *= 1.0 - exp(-abs(p.y - (dimensions.y - 8.0)) * 0.4) * 0.22;
	// Le reflet se déplace continûment ; le survol en augmente doucement la force.
	float position_reflet = fract(TIME * 0.16) * 1.6 - 0.3;
	float reflet = exp(-pow((uv.x + uv.y * 0.18 - position_reflet) / 0.16, 2.0));
	acier += vec3(0.28, 0.29, 0.30) * reflet * accent * smoothstep(6.0, 12.0, distance);
	// Quatre petites vis encastrées : un bord lumineux et une fente sombre.
	vec2 vis = bord - vec2(13.0);
	float rayon = length(vis);
	float disque = 1.0 - smoothstep(2.0, 2.6, rayon);
	float cerclage = exp(-abs(rayon - 3.0) * 2.0);
	acier = mix(acier, vec3(0.36, 0.34, 0.29) + vis.y * 0.025, disque);
	acier += cerclage * 0.15;
	acier *= 1.0 - disque * (1.0 - smoothstep(0.3, 0.7, abs(vis.y + vis.x * 0.4))) * 0.6;
	float cuivre = exp(-abs(p.y - (dimensions.y - 11.0)) * 1.0) * smoothstep(22.0, 30.0, bord.x);
	acier += vec3(0.52, 0.28, 0.1) * cuivre * (0.3 + accent * 0.7);
	return acier;
}
