// Stylized Face SDF (Genshin Inspired)
// p is local space of the head (-1.0 to 1.0)

float sdHeadBase(vec3 p) {
    return sdEllipsoid(p, vec3(0.6, 0.75, 0.65));
}

float sdChin(vec3 p) {
    vec3 q = p - vec3(0.0, -0.4, 0.3);
    return max(abs(q.x) * 1.2 + q.y * 1.0, abs(q.z) - 0.15);
}

float sdNeck(vec3 p) {
    vec3 q = p - vec3(0.0, -0.8, 0.0);
    return sdCylinder(q.xzy, 0.6, 0.3);
}

float sdEars(vec3 p) {
    vec3 q = p;
    q.x = abs(q.x) - 0.6;
    return sdEllipsoid(q - vec3(0.0, 0.0, -0.1), vec3(0.1, 0.2, 0.15));
}

float sdFace(vec3 p) {
    float head = sdHeadBase(p);
    float d = opSmoothUnion(head, sdChin(p), 0.15);
    d = opSmoothUnion(d, sdNeck(p), 0.15);
    d = opUnion(d, sdEars(p));
    
    // Nose
    vec3 np = p - vec3(0.0, -0.1, 0.65);
    float nose = sdBox(np, vec3(0.04, 0.08, 0.1));
    d = opSmoothUnion(d, nose, 0.05);
    
    // Mouth
    vec3 mp = p - vec3(0.0, -0.3, 0.6);
    float mouth = sdBox(mp, vec3(0.15, 0.01, 0.05));
    d = opSubtraction(mouth, d);
    
    // Eye Sockets
    vec3 ep = p - vec3(0.25, 0.05, 0.6);
    ep.x = abs(ep.x);
    float eyes = sdEllipsoid(ep, vec3(0.15, 0.1, 0.08));
    d = opSmoothSubtraction(eyes, d, 0.1);
    
    return d;
}
