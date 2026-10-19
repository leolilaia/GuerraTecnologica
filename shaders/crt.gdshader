shader_type canvas_item;
uniform float linhas = 240.0;
uniform float intensidade = 0.18;

void fragment() {
	float scan = sin(UV.y * linhas * 3.14159) * 0.5 + 0.5;
	float ruido = fract(sin(dot(UV * (TIME + 1.0), vec2(12.9898, 78.233))) * 43758.5453);
	COLOR = vec4(0.0, 0.0, 0.0, scan * intensidade + ruido * 0.05);
}