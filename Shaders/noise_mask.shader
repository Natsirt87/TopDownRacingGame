shader_type canvas_item;

uniform sampler2D mask;

void fragment()
{
	vec4 color = texture(TEXTURE, UV);
	color.a = texture(mask, UV).r;
	COLOR = color;
}