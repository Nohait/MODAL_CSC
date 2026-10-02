shader_type canvas_item;

uniform float proportion : hint_range(0.0, 1.0) = 1.0;
uniform vec4 teinte : source_color = vec4(0.6, 0.15, 0.14, 1.0);
uniform bool recharge = false;
uniform float impact : hint_range(0.0, 1.0) = 0.0;

void fragment() {
	// Le remplissage suit exactement la valeur de la ProgressBar.
	float rempli = (1.0 - smoothstep(proportion - fwidth(UV.x), proportion, UV.x)) * step(0.0001, proportion);
	float relief = mix(1.18, 0.52, UV.y) + exp(-abs(UV.y - 0.18) * 32.0) * 0.2;
	vec3 couleur = teinte.rgb * relief;
	// Dix graduations fines évoquent un instrument de mesure.
	float graduation = smoothstep(0.955, 0.99, fract(UV.x * 10.0));
	couleur = mix(couleur, vec3(0.08, 0.065, 0.055), graduation * 0.55);
	// Seul le reflet de recharge bouge ; le cadre reste stable.
	float reflet = recharge ? 0.07 * (sin(TIME * 4.0) + 1.0) : 0.0;
	// Une fine lèvre claire donne une impression de verre au-dessus du liquide.
	float verre = exp(-abs(UV.y - 0.1) * 65.0) * 0.13;
	couleur += vec3(reflet + verre + impact * 0.22);
	COLOR = vec4(couleur, rempli);
}
