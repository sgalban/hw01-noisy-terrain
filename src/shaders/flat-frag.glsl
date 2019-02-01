#version 300 es
precision highp float;
uniform int u_Time;

// The fragment shader used to render the background of the scene
// Modify this to make your background more interesting

out vec4 out_Col;

vec3 cubicInterp(vec3 v1, vec3 v2, float t) {
    return mix(v1, v2, smoothstep(0.0, 1.0, t));
}

vec3 getSkyColor(float sunAngle) {
    vec3 COL1 = vec3(0.08, 0.02, 0.16);
    vec3 COL2 = vec3(1.00, 0.68, 0.59);
    vec3 COL3 = vec3(0.21, 0.77, 1.00);

    if (sunAngle < 5.0) {
        return COL2;
    }
    else if (sunAngle >= 5.0 && sunAngle < 30.0) {
        return cubicInterp(COL2, COL3, (sunAngle - 5.0) / 25.0);
    }
    else if (sunAngle >= 30.0 && sunAngle < 150.0) {
        return COL3;
    }
    else if (sunAngle >= 150.0 && sunAngle < 175.0) {
        return cubicInterp(COL3, COL2, (sunAngle - 150.0) / 25.0);
    }
    else if (sunAngle >= 175.0 && sunAngle < 185.0) {
        return COL2;
    }
    else if (sunAngle >= 185.0 && sunAngle < 210.0) {
        return cubicInterp(COL2, COL1, (sunAngle - 185.0) / 25.0);
    }
    else if (sunAngle >= 210.0 && sunAngle < 330.0) {
        return COL1;
    }
    else if (sunAngle >= 330.0 && sunAngle < 355.0) {
        return cubicInterp(COL1, COL2, (sunAngle - 330.0) / 25.0);
    }
    else {
        return COL2;
    }
}

void main() {
    float sunAngle = mod(float(u_Time) * 0.1 + 90.0, 360.0);
    out_Col = vec4(getSkyColor(sunAngle), 1.0);
}
