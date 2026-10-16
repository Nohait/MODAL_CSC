shader_type canvas_item;

uniform float horloge = 0.0;
uniform float arrivee = 0.0;
uniform float eclat = 0.0;
uniform float puissance = 0.0;
uniform vec2 taille = vec2(1280.0, 720.0);
uniform vec4 teinte : source_color = vec4(0.67, 0.73, 0.75, 1.0);
uniform vec4 teinte_eclat : source_color = vec4(0.67, 0.73, 0.75, 1.0);

void fragment() {
	vec2 p = UV - vec2(0.5, 0.48);
	p.x *= taille.x / max(taille.y, 1.0);
	float halo = exp(-dot(p, p) * 3.5);
	vec3 fond = mix(vec3(0.045, 0.065, 0.08), vec3(0.10, 0.14, 0.17), halo);
	fond += teinte.rgb * halo * arrivee * (0.025 + puissance * 0.008);
	fond += teinte_eclat.rgb * halo * eclat * 0.12;
	COLOR = vec4(fond, 1.0);
}
