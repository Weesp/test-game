shader_type canvas_item;
render_mode unshaded;
uniform sampler2D silhouette : filter_linear;

void fragment() {
	vec4 original = texture(TEXTURE, UV);
	float coverage = smoothstep(0.15, 0.85, texture(silhouette, UV).r);
	COLOR = vec4(original.rgb, original.a * coverage);
}
