shader_type canvas_item;
uniform vec4 teinte : source_color = vec4(0.929, 0.941, 0.914, 1.0);
uniform float survol = 0.0;
varying vec4 modulation;
void vertex() { modulation = COLOR; }
void fragment() {
	COLOR = vec4(mix(teinte.rgb, vec3(1.0), survol * 0.15), texture(TEXTURE, UV).a) * modulation;
}
