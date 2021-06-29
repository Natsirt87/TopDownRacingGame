shader_type canvas_item;
render_mode blend_mix;
uniform vec4 modulate : hint_color;

void fragment() {
	vec2 ps = TEXTURE_PIXEL_SIZE;

	vec4 shadow = vec4(modulate.rgb, texture(TEXTURE, UV).a * modulate.a);

	COLOR = shadow;
}
