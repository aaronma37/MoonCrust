#version 450

layout(location = 0) in vec3 fragNormal;
layout(location = 1) in vec3 fragPos;

layout(location = 0) out vec4 outColor;

void main() {
    vec3 lightDir = normalize(vec3(0.8, 1.0, 0.4));
    vec3 normal = normalize(fragNormal);
    float diff = max(dot(normal, lightDir), 0.2); // ambient 0.2
    
    // Neurosymbolic cheap coloring: derive color from height/position
    vec3 color = vec3(0.2, 0.7, 0.3); // leaves
    if (fragPos.y < 3.5) {
        color = vec3(0.4, 0.25, 0.1); // trunk
    }
    
    // Add some noise/variation based on world position
    color *= 0.8 + 0.2 * fract(sin(dot(floor(fragPos.xz), vec2(12.9898, 78.233))) * 43758.5453);

    outColor = vec4(color * diff, 1.0);
}
