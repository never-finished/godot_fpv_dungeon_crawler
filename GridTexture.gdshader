shader_type spatial;
render_mode blend_mix, depth_draw_opaque, cull_back, diffuse_burley, specular_schlick_ggx;

uniform vec4 base_color : source_color = vec4(0.4, 0.4, 0.5, 1.0);
uniform vec4 grid_color : source_color = vec4(0.2, 0.2, 0.3, 1.0);
uniform float grid_size = 4.0;
uniform float line_thickness = 0.05;

void fragment() {
	// Use world coordinates to map the texture so walls tile perfectly seamlessly
	vec3 world_pos = (INV_VIEW_MATRIX * vec4(VERTEX, 1.0)).xyz;
	
	// Determine which plane we are looking at to tile UVs
	vec2 uv;
	vec3 normal = abs(NORMAL);
	if (normal.y > 0.5) {
		uv = world_pos.xz; // Floor/Ceiling
	} else if (normal.z > 0.5) {
		uv = world_pos.xy; // Front/Back Wall
	} else {
		uv = world_pos.zy; // Left/Right Wall
	}
	
	// Generate grid pattern
	vec2 grid = fract(uv * grid_size);
	
	// Draw lines
	float edge_x = step(line_thickness, grid.x);
	float edge_y = step(line_thickness, grid.y);
	float is_inside = edge_x * edge_y; // 1.0 if inside the block, 0.0 if on the line
	
	// Calculate a fake normal map (bump map) based on proximity to the edge
	// We want the lines to look like deeply carved grooves
	float dist_x = smoothstep(line_thickness, line_thickness * 2.0, grid.x);
	float dist_y = smoothstep(line_thickness, line_thickness * 2.0, grid.y);
	
	// Inverse distances from the other side of the tile so it slopes up on both sides
	float dist_x2 = smoothstep(1.0, 1.0 - line_thickness * 2.0, grid.x);
	float dist_y2 = smoothstep(1.0, 1.0 - line_thickness * 2.0, grid.y);
	
	// Combine distances to get a "height" value where 0 is the groove and 1 is the high point
	float height = min(min(dist_x, dist_y), min(dist_x2, dist_y2));
	
	// Mix the colors based on whether we are in the groove or on the block
	vec4 final_color = mix(grid_color, base_color, is_inside);
	
	ALBEDO = final_color.rgb;
	ROUGHNESS = 0.8;
	
	// Create a normal from the height gradient to fake 3D lighting depth
	// This uses Central Differences math to slope the light
	vec3 bump;
	bump.x = (height - min(min(smoothstep(line_thickness, line_thickness * 2.0, grid.x + 0.01), dist_y), min(smoothstep(1.0, 1.0 - line_thickness * 2.0, grid.x + 0.01), dist_y2))) * 5.0;
	bump.y = (height - min(min(dist_x, smoothstep(line_thickness, line_thickness * 2.0, grid.y + 0.01)), min(dist_x2, smoothstep(1.0, 1.0 - line_thickness * 2.0, grid.y + 0.01)))) * 5.0;
	bump.z = 1.0;
	
	// Apply the fake 3D depth to the engine lighting calculations
	NORMALMAP = normalize(bump) * 0.5 + vec3(0.5, 0.5, 1.0);
}
