shader_type canvas_item;

// Nastavuje sa RAZ per vrstva (v _setup_layer_offsets), fixná hodnota -
// "táto vrstva reprezentuje výškovú úroveň X".
uniform float layer_height = 0.0;

// Nastavuje sa KAŽDÝ frame z _update_layer_shader_uniforms() - kde presne
// je hráč a na akej výške práve stojí.
uniform vec2 player_world_pos = vec2(0.0, 0.0);
uniform float player_height = 0.0;

uniform float fade_radius = 100.0;
uniform float min_alpha = 0.35;

varying vec2 world_pos;

// vertex() beží raz na vrchol dlaždice - prevedie lokálnu pozíciu na
// svetovú, aby sme ju vedeli neskôr porovnať s pozíciou hráča.
void vertex() {
	world_pos = (MODEL_MATRIX * vec4(VERTEX, 0.0, 1.0)).xy;
}

// fragment() beží pre KAŽDÝ pixel dlaždice - tu sa rozhoduje o priehľadnosti.
void fragment() {
	vec4 tex_color = texture(TEXTURE, UV);
	COLOR = tex_color;

	// Táto vrstva je na úrovni hráča alebo nižšie - nemôže ho zakrývať,
	// zostane vždy plne nepriehľadná.
	if (layer_height > player_height) {
		// Čím bližšie k hráčovi, tým priehľadnejšie (plynulý prechod).
		float dist = distance(world_pos, player_world_pos);
		float t = clamp(dist / fade_radius, 0.0, 1.0);
		COLOR.a *= mix(min_alpha, 1.0, t);
	}

	
}