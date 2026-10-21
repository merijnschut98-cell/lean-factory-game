// The world behind the raised phone: blurred and dimmed (Phone). A 7x7 box
// blur of the screen, mixed towards Voltana's night blue; one pass, so it
// works in the Compatibility renderer (no screen mipmaps needed).
shader_type canvas_item;

uniform sampler2D screen : hint_screen_texture, filter_linear;
uniform float spread = 3.5;
uniform vec4 tint : source_color = vec4(0.04, 0.08, 0.16, 0.5);

void fragment() {
	vec2 step = SCREEN_PIXEL_SIZE * spread;
	vec3 sum = vec3(0.0);
	for (int x = -3; x <= 3; x++) {
		for (int y = -3; y <= 3; y++) {
			sum += texture(screen, SCREEN_UV + vec2(float(x), float(y)) * step).rgb;
		}
	}
	COLOR = vec4(mix(sum / 49.0, tint.rgb, tint.a), 1.0);
}
