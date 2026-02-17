#version 450

layout(location = 0) in vec3 vColor;
layout(location = 0) out vec4 outColor;

void main() {
    // gl_PointCoord gives us (0,0) to (1,1) within the point sprite
    vec2 circ = gl_PointCoord * 2.0 - 1.0;
    float r2 = dot(circ, circ);
    
    // Discard pixels outside the circle to make it look like a sphere
    if (r2 > 1.0) discard;

    // Fake 3D lighting (Lambertian-ish)
    float z = sqrt(1.0 - r2);
    vec3 normal = vec3(circ, z);
    vec3 light_dir = normalize(vec3(0.5, 0.5, 1.0));
    float diff = max(dot(normal, light_dir), 0.1);
    
    // Ambient + Diffuse + Rim Light
    vec3 final_color = vColor * diff + pow(1.0 - z, 3.0) * 0.5;
    
    outColor = vec4(final_color, 1.0);
}
