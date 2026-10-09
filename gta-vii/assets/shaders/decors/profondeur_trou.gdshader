shader_type spatial;
render_mode unshaded, cull_disabled, fog_disabled;

void fragment() {
	// Une pénombre neutre disparaît rapidement dans le noir, sans motif de vagues sur les parois.
	float lumiere = 1.0 - smoothstep(0.0, 0.22, UV.y);
	ALBEDO = vec3(0.025, 0.027, 0.03) * lumiere;
}
