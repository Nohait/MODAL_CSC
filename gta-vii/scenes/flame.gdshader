shader_type spatial;

render_mode blend_mix, depth_draw_opaque, unshaded, cull_disabled;

uniform sampler2D noise_texture : repeat_enable, filter_nearest;
uniform vec4 color_bottom : source_color = vec4(1.0, 0.9, 0.0, 1.0);
uniform vec4 color_mid : source_color = vec4(1.0, 0.4, 0.0, 1.0);
uniform vec4 color_top : source_color = vec4(0.8, 0.1, 0.0, 1.0);
uniform float speed = 1.5;
uniform float distortion_strength = 0.2;
uniform float pixelation = 32.0;
uniform float emission_energy = 2.0;

uniform vec3 object_scale = vec3(3.2,3.2,3.2);

void vertex() {
}

void fragment() {
    vec2 pixelated_uv = floor(UV * pixelation) / pixelation;

    vec2 scroll = pixelated_uv + vec2(0.0, -TIME * speed * -1.0);
    float noise_val = texture(noise_texture, scroll).r;

    float offset = (noise_val - 0.5) * distortion_strength;
    vec2 distorted_uv = pixelated_uv + vec2(offset, 0.0);
    
   
    float mask_x = 1.0 - smoothstep(0.1, 0.8, distorted_uv.x);
    
    float mask_y = smoothstep(0.0, 0.6, distorted_uv.y); 

    float shape = mask_x * mask_y * 2.0;
    //shape = clamp(shape, 0.0, 1.0);
	shape = 1.0 ;

    float fire_intensity = noise_val * shape;

    fire_intensity = floor(fire_intensity * 4.0) / 4.0;

    vec3 fire_color = color_top.rgb;
    fire_color = mix(fire_color, color_mid.rgb, step(0.3, fire_intensity));
    fire_color = mix(fire_color, color_bottom.rgb, step(0.6, fire_intensity));

    float alpha = step(0.1, fire_intensity);

    ALBEDO = fire_color;
    EMISSION = fire_color * emission_energy;
    ALPHA = alpha;
}