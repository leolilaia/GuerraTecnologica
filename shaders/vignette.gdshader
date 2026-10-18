shader_type canvas_item;

uniform vec4 tint : source_color = vec4(0.85, 0.05, 0.1, 1.0);
uniform float intensity : hint_range(0.0, 1.0) = 0.0;

void fragment() {
	// Só as bordas escurecem, para não esconder o centro da arena
	float edge = smoothstep(0.3, 0.75, distance(UV, vec2(0.5)));
	COLOR = vec4(tint.rgb, edge * intensity * tint.a);
}
