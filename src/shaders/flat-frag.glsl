#version 300 es
precision highp float;
uniform int u_Time;

// The fragment shader used to render the background of the scene
// Modify this to make your background more interesting

out vec4 out_Col;

vec3 getSkyColor(float sunAngle) {
    if (sunAngle < 180.0) {
        return vec3(0.64, 0.91, 1.0);
    }
    else {
        return vec3(0.0);
    }
}

void main() {
    float sunAngle = 0.0;//;mod(float(u_Time), 360.0);
    out_Col = vec4(getSkyColor(sunAngle), 1.0);
}
