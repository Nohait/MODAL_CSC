shader_type spatial;
render_mode unshaded, cull_disabled, blend_mix, depth_draw_never;
uniform float charge = 0.0;
uniform float eruption = 0.0;
uniform float intensite_lave = 4.0;
uniform float relief = 0.7;
uniform float profondeur = 3.5;
uniform float largeur = 2.2;
uniform float longueur_totale = 6.0;
uniform float irregularite = 1.0;
uniform float luminosite_roche = 0.08;
uniform float proportion_fond = 0.6;
uniform vec2 portion = vec2(0.0, 1.0);
uniform sampler2D roche : source_color, filter_linear_mipmap, repeat_enable;
uniform sampler2D lave : source_color, filter_linear_mipmap, repeat_enable;
uniform sampler2D normales : hint_normal, filter_linear_mipmap, repeat_enable;
uniform sampler2D rugosite : filter_linear_mipmap, repeat_enable;
varying vec3 oeil_local;

float centre_faille(float y) {
	return 0.5 + irregularite * (sin(y * 5.3) * 0.055 + sin(y * 17.0) * 0.025);
}

float largeur_faille(float y, float cote) {
	// Chaque lèvre a ses propres cassures ; les bouts se terminent en pointe.
	float bouts = smoothstep(0.0, 0.5, y) * smoothstep(0.0, 0.7, longueur_totale - y);
	float accidents = sin(y * 12.0 + cote * 2.4) * 0.06 + sin(y * 37.0 + cote) * 0.035;
	return max(0.001, (0.34 + irregularite * accidents) * sqrt(bouts));
}

void vertex() {
	oeil_local = (inverse(MODEL_MATRIX) * vec4(CAMERA_POSITION_WORLD, 1.0)).xyz - VERTEX;
}

vec3 magma(vec2 uv) {
	// Les veines restent texturées, avec un cœur orange et des zones rouge sombre.
	vec3 texture_lave = texture(lave, uv).rgb;
	float chaleur = max(texture_lave.r, max(texture_lave.g, texture_lave.b));
	vec3 teinte = mix(vec3(1.0, 0.018, 0.001), vec3(1.0, 0.3, 0.008), smoothstep(0.1, 0.8, chaleur));
	return teinte * (0.5 + chaleur * 0.5);
}

void fragment() {
	vec2 uv = vec2(UV.x, portion.x + UV.y * portion.y);
	// Le bord reste à la surface ; l'intérieur se lit comme une cavité sous le sol.
	float axe = centre_faille(uv.y);
	float bord = largeur_faille(uv.y, UV.x < axe ? -1.0 : 1.0);
	float ouverture = smoothstep(0.05, 1.0, charge);
	float distance_bord = abs(UV.x - axe);
	float masque = 1.0 - smoothstep(bord - 0.025, bord, distance_bord);
	float pulsation = 0.92 + sin(TIME * 4.0 + uv.y * 5.0) * 0.08;
	// Une roche noire neutre : aucune émission sur le pourtour fermé.
	float grain = dot(texture(roche, uv).rgb, vec3(0.2126, 0.7152, 0.0722));
	vec3 couleur = vec3(0.008 + grain * luminosite_roche);
	vec3 lumiere = vec3(0.0);
	if (distance_bord < bord * ouverture * 0.86) {
		// Chercher une paroi virtuelle selon la perspective de la caméra.
		// Le sol réel reste intact : aucun changement de navigation ou de collision.
		vec2 pente = -vec2(oeil_local.x, -oeil_local.z) / max(abs(oeil_local.y), 0.3);
		float niveau = 1.0;
		vec2 interieur = uv;
		bool paroi = false;
		for (int i = 1; i <= 20; i++) {
			float z = float(i) / 20.0;
			vec2 echantillon = uv + pente * z * profondeur / largeur;
			float centre = centre_faille(echantillon.y);
			float roche_bord = largeur_faille(echantillon.y, echantillon.x < centre ? -1.0 : 1.0) * ouverture * (0.86 - z * 0.38);
			roche_bord += sin(echantillon.y * 31.0 + z * 18.0) * 0.018 * relief;
			interieur = echantillon;
			if (abs(echantillon.x - centre) > roche_bord) {
				niveau = z;
				paroi = true;
				break;
			}
		}
		if (paroi) {
			vec2 uv_paroi = vec2(interieur.y * 1.7, niveau * 2.0);
			float creux = texture(normales, uv_paroi).b;
			couleur = texture(roche, uv_paroi).rgb * mix(luminosite_roche, 0.01, niveau) * mix(0.6, 1.0, creux);
			// Les profondeurs rougeoient ; le haut des parois reste presque noir.
			lumiere = magma(uv_paroi) * intensite_lave * smoothstep(0.08, 0.75, niveau) * 0.65;
		} else {
			// La lave est visible tout au fond, entourée de parois presque noires.
			couleur = vec3(0.008, 0.002, 0.001);
			lumiere = magma(interieur * 1.3 + vec2(TIME * 0.012, TIME * 0.007)) * intensite_lave;
		}
		// La perspective rasante masquait presque tout le fond par les parois.
		// Réserver un cœur visible à la lave, même avec la caméra du jeu.
		float distance_centre = distance_bord / max(bord * ouverture * 0.86, 0.001);
		float fond_visible = 1.0 - smoothstep(proportion_fond * 0.7, proportion_fond, distance_centre);
		vec2 uv_fond = uv * 1.3 + clamp(pente, vec2(-0.15), vec2(0.15)) * profondeur / largeur;
		uv_fond += vec2(TIME * 0.018, TIME * 0.009);
		vec3 lave_fond = magma(uv_fond);
		couleur = mix(couleur, lave_fond * 0.35, fond_visible);
		lumiere = mix(lumiere, lave_fond * intensite_lave, fond_visible);
	}
	ALBEDO = couleur;
	ALPHA = masque;
	EMISSION = lumiere * (0.4 + charge * 0.6 + eruption * 0.3) * pulsation;
}
