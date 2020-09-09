shader_type spatial;
render_mode unshaded;

//Light Data
uniform sampler2D light_data : hint_black; //stores light data from lightdataview viewport texture (these lights are each mono color r, g, or b)

//Specular Data
uniform sampler2D specular_data : hint_black; // stores light data from speculardataview

//Light Colors
uniform vec4 key_light_color : hint_color; //base light color
uniform sampler2D key_light_ramp : hint_black; //controls crispness of shadow boundary
uniform vec4 shadow_color : hint_color;

//Fill Light Color
uniform vec4 fill_light_color : hint_color; //brightens color after fill light
uniform sampler2D fill_light_ramp : hint_black;

//Rim Light Color
uniform vec4 rim_light_color : hint_color; 
uniform sampler2D rim_light_ramp : hint_black; 

//Specular Variables
uniform float specular_softness : hint_range(0,1) = 0.642;
uniform float specular_size : hint_range(0,4) = 1.0; //size of specular blob
uniform vec4 specular_color : hint_color = vec4(0.77);

const float SPECULAR_SOFT_MIN = 0.0;
const float SPECULAR_SOFT_MAX = 0.6;
const float SPECULAR_HARD_MIN = 0.12;
const float SPECULAR_HARD_MAX = 0.18;


void fragment() {
	//Data
	vec3 diffuse = texture(light_data, SCREEN_UV).rgb; //sample light data viewport texture at same screen uv as main viewport
	
	//Key Light
	float key_light_value = texture(key_light_ramp, vec2(diffuse.r, 0)).r; //use key light value as U, and read from the key_light_ramp gradient
	
		vec3 out_color = key_light_value * key_light_color.rgb; //calculate color of light based on key_light_value
		out_color = max(out_color, shadow_color.rgb); //take largest color, so color is never less than shadow color
	
	//Fill Light
	float fill_light_value = texture(fill_light_ramp, vec2(diffuse.g, 0)).r; //sample fill ramp based on value of fill light in viewport texture
		out_color += fill_light_value * fill_light_color.rgb; //fill color is added because it brightens other colors
	
	//Specular 
	float specular = texture(specular_data, SCREEN_UV).r; //only need first value r because specular is pure black and white
	
	float soft_specular = smoothstep(SPECULAR_SOFT_MIN, SPECULAR_SOFT_MAX, specular * specular_size);
	float hard_specular = smoothstep(SPECULAR_HARD_MIN, SPECULAR_HARD_MAX, specular * specular_size);
	
	vec3 specular_out = mix(hard_specular, soft_specular, specular_softness) * specular_color.rgb; //linearly interpolate between the soft and hard specular
	
	out_color += specular_out;
	
	//Rim Light
	float rim_light_value = texture(rim_light_ramp, vec2(diffuse.b, 0)).r;
		out_color += rim_light_value * rim_light_color.rgb;
	
	
	
	
	
	ALBEDO = out_color; //set color as ALBEDO
}










