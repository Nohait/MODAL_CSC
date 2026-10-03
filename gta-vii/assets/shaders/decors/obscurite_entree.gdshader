shader_type spatial;
render_mode unshaded, cull_disabled, depth_draw_never;

uniform float debut = 0.0;
uniform float fin = 1.0;
uniform bool horizontal = false;
uniform bool inverser = false;

void fragment() {
	// La fin du passage se perd dans le noir au lieu de montrer le bord du sol.
	ALBEDO = vec3(0.0);
	float distance = horizontal ? UV.x : UV.y;
	distance = inverser ? 1.0 - distance : distance;
	ALPHA = smoothstep(0.0, 1.0, mix(debut, fin, distance));
}
