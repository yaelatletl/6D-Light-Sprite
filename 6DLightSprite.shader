shader_type spatial;
render_mode blend_mix,depth_draw_opaque,cull_back,diffuse_burley,specular_schlick_ggx;
uniform vec4 albedo : hint_color;
uniform sampler2D scatter_front_top_left : hint_white;
uniform sampler2D scatter_back_bottom_right : hint_white;
uniform float specular;
uniform float metallic;
uniform float roughness : hint_range(0,1);
uniform float point_size : hint_range(0,128);
uniform int particles_anim_h_frames;
uniform int particles_anim_v_frames;
uniform bool particles_anim_loop;
uniform bool debug_light_view;
uniform vec3 uv1_scale;
uniform vec3 uv1_offset;
uniform vec3 uv2_scale;
uniform vec3 uv2_offset;



void light() {
	vec4 invcamx = INV_CAMERA_MATRIX[0];
vec4 invcamy = INV_CAMERA_MATRIX[1];
vec4 invcamz = INV_CAMERA_MATRIX[2];
vec4 invcamw = INV_CAMERA_MATRIX[3];

mat3 invcam = mat3(invcamx.xyz, invcamy.xyz, invcamz.xyz);

vec3 world_normal = (vec4(NORMAL.x, NORMAL.y, NORMAL.z, 1.0) * INV_CAMERA_MATRIX).xyz;
	vec4 front_top_left = texture(scatter_front_top_left, UV);
	vec4 back_bottom_right = texture(scatter_back_bottom_right, UV);
	float hMap = (LIGHT.x > 0.0) ? (front_top_left.r) : (back_bottom_right.r); 
	float vMap = (LIGHT.y > 0.0) ? (front_top_left.g) : (back_bottom_right.g); 
	float dMap = (LIGHT.z > 0.0) ? (front_top_left.b) : (back_bottom_right.b); 
	float lightMap = hMap*LIGHT.x*LIGHT.x + vMap*LIGHT.y*LIGHT.y + dMap*LIGHT.z*LIGHT.z;
	
    DIFFUSE_LIGHT += clamp(lightMap, 0.0, 1.0) *  ATTENUATION * ALBEDO * LIGHT_COLOR;
	if (debug_light_view == true){
		DIFFUSE_LIGHT = lightMap*vec3(1.0);
	}
}

void vertex() {
	UV=UV*uv1_scale.xy+uv1_offset.xy;
	mat4 mat_world = mat4(normalize(CAMERA_MATRIX[0])*length(WORLD_MATRIX[0]),normalize(CAMERA_MATRIX[1])*length(WORLD_MATRIX[0]),normalize(CAMERA_MATRIX[2])*length(WORLD_MATRIX[2]),WORLD_MATRIX[3]);
	mat_world = mat_world * mat4( vec4(cos(INSTANCE_CUSTOM.x),-sin(INSTANCE_CUSTOM.x), 0.0, 0.0), vec4(sin(INSTANCE_CUSTOM.x), cos(INSTANCE_CUSTOM.x), 0.0, 0.0),vec4(0.0, 0.0, 1.0, 0.0),vec4(0.0, 0.0, 0.0, 1.0));
	MODELVIEW_MATRIX = INV_CAMERA_MATRIX * mat_world;
	float h_frames = float(particles_anim_h_frames);
	float v_frames = float(particles_anim_v_frames);
	float particle_total_frames = float(particles_anim_h_frames * particles_anim_v_frames);
	float particle_frame = floor(INSTANCE_CUSTOM.z * float(particle_total_frames));
	if (!particles_anim_loop) {
		particle_frame = clamp(particle_frame, 0.0, particle_total_frames - 1.0);
	} else {
		particle_frame = mod(particle_frame, particle_total_frames);
	}	UV /= vec2(h_frames, v_frames);
	UV += vec2(mod(particle_frame, h_frames) / h_frames, floor(particle_frame / h_frames) / v_frames);
}




void fragment() {
	float front_top_left = texture(scatter_front_top_left, UV).a;
	float back_bottom_right = texture(scatter_back_bottom_right, UV).a;
	vec2 base_uv = UV;
	ALBEDO = albedo.rgb;
	METALLIC = metallic;
	ROUGHNESS = roughness;
	SPECULAR = specular;
	ALPHA = albedo.a * front_top_left *back_bottom_right;
}
