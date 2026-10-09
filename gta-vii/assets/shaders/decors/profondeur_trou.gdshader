shader_type spatial;
// unshaded : le soleil et l'ambiance ne modifient pas la couleur calculée.
// cull_disabled : parois visibles des deux côtés ; fog_disabled : le brouillard
// ne peut pas éclaircir le noir et révéler la jonction avec le fond.
render_mode unshaded, cull_disabled, fog_disabled;

// UV.y va de la lèvre au bas de la paroi. Le noir est atteint très vite,
// même si le soleil ou la lumière ambiante sont puissants.
/**
 * Colore chaque fragment d'une paroi intérieure.
 * UV.y vaut 0 en haut, 1 en bas : la couleur atteint le noir à 32 % de la profondeur.
 * Écrit ALBEDO, sans modifier la géométrie ni la transparence.
 */
void fragment() {
	// smoothstep monte de 0 à 1 ; "1 -" inverse ce résultat pour éteindre la couleur.
	// Sur une paroi de 3 m, le noir complet commence donc à environ 0.96 m.
	float lumiere = (1.0 - smoothstep(0.0, 0.32, UV.y));
	// Les sinus ajoutent des variations sombres sur la partie encore visible.
	// Ce grain n'est pas du relief géométrique et disparaît lui aussi dans le noir.
	float grain = 0.7 + 0.3 * sin(UV.x * 63.0) * sin(UV.y * 95.0);
	ALBEDO = vec3(0.075, 0.048, 0.03) * lumiere * grain;
}
