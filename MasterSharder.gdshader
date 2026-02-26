shader_type canvas_item;




uniform vec4 mod_color : source_color = vec4(1.0);

// DESC: ON = Perfect Loops for Exports. OFF = Smooth movement for live play.
uniform float sync_to_loop : hint_range(0.0, 1.0, 1.0) = 0.0;

// DESC: The image won't draw outside the size of this circle
uniform float mask_radius : hint_range(0.0, 1.0, 0.01) = 1.0;
// --- 1. COORDINATE WARPING (UV) ---
// DESC: stretch a mask to hide outside the radius
uniform float mask_stretch : hint_range(0.1, 6.1) = 1.0;

// DESC: Swirls the image - Use this in combination with Swirl Speed to animate the Kaleidoscope
uniform float swirl_strength : hint_range(0.0, 10.0, 0.1) = 0.0;


// DESC: Rotates when combined with Swirl Strength > 0
uniform float swirl_speed : hint_range(-4.0, 4.0, 0.1) = 0.0;

// DESC:  Radial Kaleidocsope - How many splits?
uniform float kaleido_sides : hint_range(1.0, 15.0, 1.0) = 1.0;



// 1a NEW FRACTAL EFFECTS
// DESC:  # of geometric folds 
uniform float fold_number : hint_range(0.0, 8.0, 1.0) = 0.0;
// DESC: ZOOM IN OR OUT WARPING THE IMAGE 
uniform float fold_zoom : hint_range(0.0, 6.0, 0.1) = 1.0;
// DESC: Controls rotation speed of the fractal folds. Set to 0.0 for static folds.
uniform float fold_rot_speed : hint_range(0.0, 5.0, 0.1) = 0.0;
// DESC: 1.0 = Off, 2.0+ = Grid Tiling. Use whole numbers for perfect loops.
uniform float hex_scale : hint_range(1.0, 10.0, 1.0) = 1.0;

// DESC: Controls rotation speed of individual hex tiles. Set to 0.0 to stop spinning.
uniform float hex_rot_speed : hint_range(0.0, 5.0, 0.1) = 0.0;

// DESC:  4-Way Mirror
uniform float mirror_4way : hint_range(0.0, 1.0, 1.0) = 0.0;

//RAY MARCHING DECLARATIONS
// DESC: RAY ANGLE
uniform float ray_angle : hint_range(0.0, 6.28, 0.5) = 0.0;
// DESC: HIGH VALUES SEEM GOOD HERE - IN COMBO W OTHER RAY-MARCHING SLIDERS
uniform float max_steps : hint_range(10.0, 300.0, 1.0) = 100.0;
// DESC: LOW VALUES SEEM BETTER TO ME - THIS IS A RAY MARCHING SLIDER
uniform float step_length : hint_range(0.001, 0.1, 0.001) = 0.01;
// DESC: THIS LOOKS LIKE SHINING A LIGHT FROM A DIRECTION - RAY MARCHING
uniform float ray_intensity : hint_range(0.0, 1.0, 0.1) = 0.0; // Default to 0 (Off)
// DESC: RAY-MARCHING COLOR
uniform vec4 ray_color : source_color = vec4(1.0, 0.5, 0.0, 1.0);
// DESC: BENDS THE IMAGE IN A 4-D SORTA WAY
uniform float hyperbolic_bend : hint_range(-5.0, 5.0) = 0.0;


// DESC: QUATERNIONS?
uniform vec4 q_rot = vec4(0.0, 0.0, 0.0, 1.0); // x, y, z, w (1.0 is no rotation)     // FIRST QUATERNION BASED SHADERS
// DESC : QUATERNION UV TUMBLER
uniform float tumble_strength : hint_range(0.0, 1.0) = 0.5;
// DESC : Corrupt the "purity" of the math, LOL 
uniform float glitch_factor : hint_range(0.0, 1.0) = 0.0;

// DESC: Adds a liquid-like waving distortion.
uniform float wave_strength : hint_range(0.0, 1.0, 0.01) = 0.0;

// DESC: Bends the image into a circular 'fisheye' lens.
uniform float fisheye : hint_range(-1.0, 1.0, 0.01) = 0.0;

// --- 2. COLOR & LIGHT EFFECTS ---
// DESC: Cycles through colors, 1 = one full loop per animation, 2= 2 loops per animation
uniform float hue_shift_speed : hint_range(0.0, 5.0, 1.0) = 0.0;
// DESC: Shifts colors like a thermal camera.
uniform float thermal_shift : hint_range(0.0, 1.0, 0.01) = 0.0;
// DESC: Inverts the colors (0 normal, 1 fully inverted).
uniform float invert : hint_range(0.0, 1.0, 0.01) = 0.0;
// DESC: Generates a trippy, moving plasma color field.
uniform float plasma_strength : hint_range(0.0, 1.0, 0.01) = 0.0;
// DESC: Splits Red/Blue channels (Chromatic Aberration).
uniform float rgb_split : hint_range(0.0, 0.1, 0.001) = 0.0;
// DESC: Pulsing rainbow overlay that loops perfectly.
uniform float rainbow_pulse : hint_range(0.0, 1.0, 0.01) = 0.0;

// --- 3. OVERLAYS & TEXTURE ---
// DESC: Adds animated TV static/noise.
uniform float tv_static : hint_range(0.0, 1.0, 0.01) = 0.0;
// DESC: Creates a blocky look
uniform float pixelate : hint_range(0.0, 1.0, 0.005) = 0.0;



// --- DYNAMIC UI CONTROLS ---
uniform float brightness : hint_range(-1.0, 1.0, 0.01) = 0.0;
uniform float contrast : hint_range(0.0, 2.0, 0.01) = 1.0;
uniform float saturation : hint_range(0.0, 2.0, 0.01) = 1.0;

// --- SYSTEM ---
uniform float manual_time = 0.0;


float rand(vec2 co) {
	return fract(sin(dot(co.xy ,vec2(12.9898,78.233))) * 43758.5453);
}


void fragment() {
	// --- 1. INITIAL SETUP ---
	// Removed 'center' variable to clear the warning
	vec2 uv = (UV - 0.5) * fold_zoom;
	float tau = 6.28318530718;
	


	// --- 2. UV DISTORTIONS ---
	

		// STYLE 0: RADIAL KALEIDOSCOPE
		if (kaleido_sides > 1.0) {
			vec2 p = uv; 
			float a = atan(p.y, p.x);
			float r = length(p);
			float slice = tau / kaleido_sides;
			a = mod(a, slice);
			a = abs(a - slice / 2.0);
			uv = vec2(cos(a), sin(a)) * r;
		}
	

// STYLE 1: GEOMETRIC FOLDING
if (fold_number > 0.5) {
    for (int i = 0; i < 10; i++) {
        if (float(i) >= fold_number) break;
        uv = abs(uv);
        
        // Use the new speed uniform instead of the hardcoded 0.1
        // This ensures the fractal stays still unless you move the slider
        if (fold_rot_speed > 0.01) {
            float speed_choice = mix(fold_rot_speed, floor(fold_rot_speed), sync_to_loop);
			float a_fold = manual_time * tau * speed_choice;
            float c_f = cos(a_fold); float s_f = sin(a_fold);
            uv = vec2(uv.x * c_f - uv.y * s_f, uv.x * s_f + uv.y * c_f);
        }
        
        uv -= 0.3;
    }
}

// STYLE 2: HEXAGONAL TILING
if (hex_scale > 1.1) {
    vec2 hex_uv = uv * hex_scale;
    vec2 r_hex = vec2(1.0, 1.73205);
    vec2 h_hex = r_hex * 0.5;
    
    vec2 a_hex = mod(hex_uv, r_hex) - h_hex;
    vec2 b_hex = mod(hex_uv - h_hex, r_hex) - h_hex;
    
    // Declare g_uv here so it's available for the whole block
    vec2 g_uv = dot(a_hex, a_hex) < dot(b_hex, b_hex) ? a_hex : b_hex;
    
    // Only rotate if the user wants individual tile spin
    if (hex_rot_speed > 0.01) {
        float rot_a = manual_time * tau * floor(hex_rot_speed); 
        float c_h = cos(rot_a); float s_h = sin(rot_a);
        g_uv = vec2(g_uv.x * c_h - g_uv.y * s_h, g_uv.x * s_h + g_uv.y * c_h);
    }
    
    uv = g_uv / hex_scale; 
}

		// STYLE 3: CARTESIAN 4-WAY MIRROR
		if (mirror_4way > 0.5) {
			uv = abs(uv);
		}

	


	// FISHEYE
	if (abs(fisheye) > 0.01) {
		float r = length(uv);
		uv = uv * (1.0 + r * r * fisheye);
	}

// WAVE
if (wave_strength > 0.01) {
    // Sync the wave frequency so it finishes exactly where it started
    float wave_sync = mix(10.0, floor(10.0), sync_to_loop); 
    uv.x += sin(uv.y * wave_sync + manual_time * tau) * (wave_strength * 0.05);
}

	// PIXELATE
	if (pixelate > 0.0) {
		vec2 size = vec2(textureSize(TEXTURE, 0));
		float f = mix(1.0, 0.02, pixelate);
		uv = floor(uv * size * f) / (size * f);
	}

// SWIRL
if (swirl_strength > 0.01) {
    float dist = length(uv);
    // Snap the swirl rotation speed
    float s_speed = mix(swirl_speed, floor(swirl_speed), sync_to_loop);
    float angle = (swirl_strength * dist) + (manual_time * tau * s_speed);
    float c = cos(angle); float s = sin(angle);
    uv = vec2(uv.x * c - uv.y * s, uv.x * s + uv.y * c);
}

// --- POINCARÉ DISK DISTORTION ---
// This warps the actual image geometry
//if (abs(hyperbolic_bend) > 0.1) {
 //   vec2 p = uv; // centered UVs
 //   float r = length(p);
    // The standard Poincaré mapping: p' = p / (1 - r^2)            // this code was replaced by more interesting mobius block below..
    // We'll use your bend slider to control the intensity                 // that is, the hyperbolic inversion logic. 
 //   float warp = 1.0 / (1.0 - (r * r * (hyperbolic_bend * 0.1)));
 //   uv *= warp;
//}


// Add this right before your Inversion/Warp logic
// Use this for a silky smooth, hypnotic pulse
// manual_time * tau * 0.1 means one full "breath" every 10 seconds
//float breathing_cycle = sin(manual_time * tau * 0.1); 
//float breathing_bend = hyperbolic_bend + (breathing_cycle * 0.15);   //this breathing logic looks more like a desynced loop


// --- HYPERBOLIC INVERSION (The 'Infinite Mirror' look) ---
if (abs(hyperbolic_bend) > 0.1) {
    float r = length(uv);
    // This is the magic: Inverting the space around a circle
    // As r gets small, uv gets huge, and vice-versa
    float inversion = (hyperbolic_bend * 0.1) / (r * r + 0.01);    // previous bend type (it works, replaced with next line )
   // float inversion = (breathing_bend * 0.1) / (r * r + 0.01); 
    uv *= inversion;
}


// --- QUATERNION UV TUMBLE (WITH GLITCH MODE) ---
if (tumble_strength > 0.0) {
    // 0. The Glitch Mix: 0.0 = Pure Sphere, 1.0 = Out of Whack
    vec4 q_pure = normalize(q_rot);
    vec4 q = mix(q_pure, q_rot, glitch_factor); 
    
    // 1. Map UV to 3D unit sphere (the "bubble")
    vec3 p = vec3(uv, sqrt(max(0.0, 1.0 - dot(uv, uv))));
    
    // 2. Quaternion Rotation Math
    vec3 q_xyz = q.xyz;
    float q_w = q.w;
    vec3 temp = cross(q_xyz, p) + q_w * p;
    vec3 p_rotated = p + 2.0 * cross(q_xyz, temp);
    
    // 3. Project back to 2D and mix based on strength
    uv = mix(uv, p_rotated.xy, tumble_strength);
}


	// --- 3. THE "WRAP" (CRITICAL STEP OF UV DISTORTIONS) ---
	// We wrap the UVs BEFORE we sample the texture
	vec2 wrapped_uv = fract(uv + 0.5);
	


	// --- 4. SAMPLING & COLOR EFFECTS ---
	vec4 tex;
	if (rgb_split > 0.0) {
	    float split_speed = mix(1.0, floor(1.0), sync_to_loop);
	    float split_offset = rgb_split * sin(manual_time * tau * split_speed);
		float r = texture(TEXTURE, wrapped_uv + vec2(split_offset, 0.0)).r;
		float g = texture(TEXTURE, wrapped_uv).g;
		float b = texture(TEXTURE, wrapped_uv - vec2(split_offset, 0.0)).b;
		tex = vec4(r, g, b, texture(TEXTURE, wrapped_uv).a);
	} else {
		tex = texture(TEXTURE, wrapped_uv);
	}
	

// --- RAINBOW HYPERBOLIC ----  RAY MARCHER --- START OF CODE BLOCK
// --- 5. RAY MARCHING (Now it knows what 'tex' is) ---
if (ray_intensity > 0.01) {
    vec2 current_pos = wrapped_uv; 
    float hit_dist = -1.0;
    float final_angle = ray_angle; 


    for (int i = 0; i < int(max_steps); i++) { // Cast to int here!
        float d_center = length(current_pos - 0.5);
		float pulse_freq = mix(1.0, floor(1.0), sync_to_loop);
		float portal_pulse = sin(manual_time * tau * pulse_freq + (1.0 / (d_center + 0.01)));
        final_angle += d_center * (hyperbolic_bend * 0.2);
        vec2 bent_dir = vec2(cos(final_angle), sin(final_angle));
        
        current_pos += bent_dir * (step_length * float(i) * 0.001); 
        
        if (texture(TEXTURE, fract(current_pos)).a > 0.5) {
            hit_dist = float(i) / max_steps;
            break;
        }
    }

    if (hit_dist > -1.0) {
        float fade = 1.0 - hit_dist;
        
        // --- TRIPPY COLOR LOGIC ---
        vec3 rainbow_hit;
        rainbow_hit.r = sin(final_angle);
        rainbow_hit.g = sin(final_angle + 2.0);
        rainbow_hit.b = sin(final_angle + 4.0);
        rainbow_hit = rainbow_hit * 0.5 + 0.5;

        // --- PORTAL PULSE MATH ---
        float d_center = length(current_pos - 0.5);
        float portal_pulse = sin(manual_time * tau + (1.0 / (d_center + 0.01)));
        
        // Use mod_color (your UI color picker) for the base glow
        vec3 final_glow = mix(mod_color.rgb, rainbow_hit, 0.7);
        final_glow = mix(final_glow, vec3(1.0), portal_pulse * 0.3 * ray_intensity);
        
        float mask_orig = 1.0 - tex.a; 
        
        // 1. Apply the broad, soft glow (Original mix)
        tex.rgb = mix(tex.rgb, final_glow, fade * ray_intensity * mask_orig);

        // 2. ADD THIS: The Sharp "Event Horizon" Edge
        // pow(fade, 5.0) makes the glow very tight to the edge of the image
        float horizon_glow = pow(fade, 5.0); 
        tex.rgb += mod_color.rgb * horizon_glow * ray_intensity * 2.0;

        // 3. Update Alpha so the glow shows up on transparent backgrounds
        tex.a = max(tex.a, fade * ray_intensity);
    }
} // <--- Close the Ray Marching Block// 

// --- RADIAL PLASMA (Perfectly Synced) ---
if (plasma_strength > 0.0) {
    // 1. Calculate distance (0.0 at center, 0.5 at edges)
	float dist = length(UV - 0.5);
    
    // 2. The "Sync Secret": Use a whole number for the ring count
    // By using tau * a whole number (e.g., 5.0), the wave starts 
    // and ends at the same phase (0 and 1.0)
    float ring_count = 5.0; // Higher = more rings
      // Snap the wave movement speed
    float p_speed = mix(1.0, floor(1.0), sync_to_loop);
    float v = sin(dist * (tau * ring_count) - manual_time * tau * p_speed);
    
    // 3. Simple color mapping that also uses tau for perfect color loops
    vec3 plasma_colors;
    plasma_colors.r = sin(v * 2.0 + manual_time * tau);
    plasma_colors.g = sin(v * 2.0 + 2.0 + manual_time * tau);
    plasma_colors.b = sin(v * 2.0 + 4.0 + manual_time * tau);
    plasma_colors = plasma_colors * 0.5 + 0.5;
    
    tex.rgb = mix(tex.rgb, plasma_colors, plasma_strength);
}

	// [CONTINUE WITH THERMAL, HUE SHIFT, VIGNETTE, RAINBOW PULSE...]
    // (Ensure they use 'tex.rgb' and 'wrapped_uv' for calculations)
		if (thermal_shift > 0.0) {
		float lum = dot(tex.rgb, vec3(0.299, 0.587, 0.114));
		// Thermal pulse now loops
		vec3 thermal = vec3(lum, 1.0 - lum, sin(lum * 10.0 + manual_time * tau));
		tex.rgb = mix(tex.rgb, thermal, thermal_shift);
	}

// 7. HUE SHIFT (Synchronized & Vibrant)
if (hue_shift_speed > 0.5) {
    // 1. Convert RGB to YIQ (Luminance and Chrominance)
    const mat3 rgb2yiq = mat3(vec3(0.299, 0.587, 0.114), vec3(0.596, -0.274, -0.322), vec3(0.211, -0.523, 0.312));
    const mat3 yiq2rgb = mat3(vec3(1.0, 0.956, 0.621), vec3(1.0, -0.272, -0.647), vec3(1.0, -1.106, 1.703));
    
    vec3 yiq = rgb2yiq * tex.rgb;
    
    // 2. Rotate the Chrominance (color) based on time
    // Ensure hue_shift_speed is a whole number for a perfect loop!
    // Instead of: float hue = manual_time * tau * floor(hue_shift_speed);
	float hue_speed = mix(hue_shift_speed, floor(hue_shift_speed), sync_to_loop);
	float hue = manual_time * tau * hue_speed;
    
    float chroma_cos = cos(hue);
    float chroma_sin = sin(hue);
    
    vec2 rotated_chroma = vec2(
        yiq.y * chroma_cos - yiq.z * chroma_sin,
        yiq.y * chroma_sin + yiq.z * chroma_cos
    );
    
    // 3. Convert back to RGB
    tex.rgb = yiq2rgb * vec3(yiq.x, rotated_chroma.x, rotated_chroma.y);
}
	
	if (invert > 0.0) tex.rgb = mix(tex.rgb, 1.0 - tex.rgb, invert);

	tex.rgb = (tex.rgb - 0.5) * contrast + 0.5 + brightness;
	tex.rgb = mix(vec3(dot(tex.rgb, vec3(0.299, 0.587, 0.114))), tex.rgb, saturation);

	// 4. OVERLAYS
	if (tv_static > 0.0) {
		// To make static loop, we need a 3D noise or a scrolling coordinate, 
		// but since it's random, we'll just use manual_time as a seed.
		tex.rgb += (rand(UV + floor(manual_time * 24.0)) - 0.5) * tv_static;
	}	

		// --- RAINBOW PULSE EFFECT ---
	if (rainbow_pulse > 0.0) {
		float tau = 6.28318530718;
		
		// 1. Create the cycling rainbow color based on manual_time
		// We shift the phase for R, G, and B to create the spectrum
		vec3 rainbow;
		rainbow.r = cos(manual_time * tau);
		rainbow.g = cos(manual_time * tau + 2.0);
		rainbow.b = cos(manual_time * tau + 4.0);
		
		// 2. Normalize to 0.0 - 1.0 range
		rainbow = rainbow * 0.5 + 0.5;
		
		// 3. Apply a pulsing "glow" intensity using a sine wave
		  float r_speed = mix(1.0, floor(1.0), sync_to_loop);
   		 float glow = sin(manual_time * tau * r_speed) * 0.5 + 0.5;
		
		// 4. Mix it into the final texture
		vec3 rainbow_final = mix(tex.rgb, rainbow, rainbow_pulse * glow);
		tex.rgb += (rainbow_final * rainbow_pulse * glow); 
}
    





// --- 7. FINAL MASKING & OUTPUT ---
// --- 6. ELASTIC ELLIPSE MASK ---
// Use the raw UVs (0.0 to 1.0) centered at 0.5
vec2 mask_uv = UV - 0.5;

// Apply the manual stretch
// 1.0 = Default (follows Viewport shape)
// < 1.0 = Squeezes horizontally (Vertical Oval)
// > 1.0 = Stretches horizontally (Horizontal Oval)
mask_uv.x *= mask_stretch;

float dist_from_center = length(mask_uv);

// Using a small value like 0.05 for the 'feather' creates a nice soft glow edge
float feather = 0.05; 
float mask = smoothstep(mask_radius, mask_radius - feather, dist_from_center);

// Apply the mask to the image and the ray-marched glow
tex.rgb *= mask;
tex.a *= mask;
// This adds a thin, glowing ring at the very edge of your mask
float edge_glow = smoothstep(mask_radius - 0.02, mask_radius, dist_from_center) * mask;
tex.rgb += mod_color.rgb * edge_glow * 0.5;

// --- 2026 OPTICAL POLISH: MASK FRINGE ---
// This makes the very edge of your elliptical mask look like a glass lens
if (abs(mask_radius - dist_from_center) < 0.05) {
    float fringe = smoothstep(0.05, 0.0, abs(mask_radius - dist_from_center));
    float r_fringe = texture(TEXTURE, wrapped_uv + (mask_uv * 0.01 * fringe)).r;
    float b_fringe = texture(TEXTURE, wrapped_uv - (mask_uv * 0.01 * fringe)).b;
    tex.rgb = mix(tex.rgb, vec3(r_fringe, tex.g, b_fringe), fringe * 0.5);
}
// Final Output
COLOR = tex * mod_color;
	}
	