shader_type canvas_item;

uniform float flash_modifier : hint_range(0.0, 1.0) = 0.0;

void fragment() {
    vec4 color = texture(TEXTURE, UV);
    COLOR = mix(color, vec4(1.0, 1.0, 1.0, color.a), flash_modifier);
}