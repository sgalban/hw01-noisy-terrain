#version 300 es
precision highp float;

uniform vec2 u_PlanePos; // Our location in the virtual world displayed by the plane
uniform int u_Time;

in vec3 fs_Pos;
in vec4 fs_Nor;
in vec4 fs_Col;

in float fs_Sine;

in float fs_Biome;

out vec4 out_Col; // This is the final output color that you will see on your
                  // screen for the pixel that is currently being processed.

const vec2 SEED2 = vec2(0.31415, 0.6456);
const vec3 SEED3 = vec3(0.1, 0.22, 0.31);

float random1( vec2 p , vec2 seed) {
    return fract(sin(dot(p + seed, vec2(127.1, 311.7))) * 43758.5453);
}

float random1( vec3 p , vec3 seed) {
    return fract(sin(dot(p + seed, vec3(987.654, 123.456, 531.975))) * 85734.3545);
}

vec2 random2( vec2 p , vec2 seed) {
    return fract(sin(vec2(dot(p + seed, vec2(311.7, 127.1)), dot(p + seed, vec2(269.5, 183.3)))) * 85734.3545);
}

float quinticFalloff(float t) {
    return t * t * t * (t * (6.0 * t - 15.0) + 10.0);
}

float perlin (vec2 noisePos, float frequency) {
    vec2 pos = noisePos * frequency;
    vec2 cellPos = vec2(floor(pos.x), floor(pos.y));

    vec2 corner0 = cellPos + vec2(0.0, 0.0);
    vec2 corner1 = cellPos + vec2(1.0, 0.0);
    vec2 corner2 = cellPos + vec2(0.0, 1.0);
    vec2 corner3 = cellPos + vec2(1.0, 1.0);

    vec2 posVec0 = pos - corner0;
    vec2 posVec1 = pos - corner1;
    vec2 posVec2 = pos - corner2;
    vec2 posVec3 = pos - corner3; 

    vec2 gradient0 = normalize(random2(corner0, SEED2) * (random1(corner0, SEED2) > 0.5 ? 1.0 : -1.0));
    vec2 gradient1 = normalize(random2(corner1, SEED2) * (random1(corner1, SEED2) > 0.5 ? 1.0 : -1.0));
    vec2 gradient2 = normalize(random2(corner2, SEED2) * (random1(corner2, SEED2) > 0.5 ? 1.0 : -1.0));
    vec2 gradient3 = normalize(random2(corner3, SEED2) * (random1(corner3, SEED2) > 0.5 ? 1.0 : -1.0));
    float val0 = dot(posVec0, gradient0);
    float val1 = dot(posVec1, gradient1);
    float val2 = dot(posVec2, gradient2);
    float val3 = dot(posVec3, gradient3);

    float tx = quinticFalloff(fract(pos.x));
    float ty = quinticFalloff(fract(pos.y));
    float lerpedCol = mix(mix(val0, val1, tx), mix(val2, val3, tx), ty);

    return (lerpedCol + 1.0) / 2.0;
}

float recursivePerlin(vec2 noisePos, int octaves, float frequency) {
    const float PERSISTENCE = 0.5;
    const float FREQUENCY_FACTOR = 2.0;

    float total = 0.0;
    float curAmplitude = 1.0;
    float curFrequency = frequency;
    for (int curOctave = 0; curOctave < octaves; curOctave++) {
        curAmplitude *= PERSISTENCE;
        total += perlin(noisePos, curFrequency) * curAmplitude;
        curFrequency *= FREQUENCY_FACTOR;
    }
    return total;
}

// I tried to make this 3D, but it cut my framerate in half
float brownianNoise(vec2 noisePos, vec2 seed) {
    vec2 boxPos = vec2(floor(noisePos.x), floor(noisePos.y));

    // Get the noise at the corners of the cells
    float corner0 = random1(boxPos + vec2(0.0, 0.0), seed);
    float corner1 = random1(boxPos + vec2(1.0, 0.0), seed);
    float corner2 = random1(boxPos + vec2(0.0, 1.0), seed);
    float corner3 = random1(boxPos + vec2(1.0, 1.0), seed);

    // Get cubic interpolation factors
    float tx = smoothstep(0.0, 1.0, fract(noisePos.x));
    float ty = smoothstep(0.0, 1.0, fract(noisePos.y));

    // Perform bicubic interpolation
    return mix(mix(corner0, corner1, tx), mix(corner2, corner3, tx), ty);
}

float fbm(vec2 noisePos, int numOctaves, float startFrequency) {
    float totalNoise = 0.0;
    float normalizer = 0.0;
    const float PERSISTENCE = 0.5;

    for (int i = 0; i < numOctaves; i++) {
        float frequency = pow(2.0, float(i)) * startFrequency;
        float amplitude = pow(PERSISTENCE, float(i));
        normalizer += amplitude;
        totalNoise += brownianNoise(noisePos * frequency, SEED2) * amplitude;
    }
    return totalNoise / normalizer;
}

vec3 getMountainsColor(vec3 pos) {
    float t = min(pos.y * 0.15 + ((fbm(pos.xz, 3, 0.5)) - 0.5) * 0.4, 1.0);

    float largeFbm = fbm(pos.xz, 3, 0.075);
    float smallFbm = fbm(pos.xz, 5, 5.0);

    float mediumPerlin = recursivePerlin(pos.xz, 2, 1.0);

    const vec3 COL0 = vec3(0.1, 0.4, 0.07);
    const vec3 COL1 = vec3(0.3, 0.5, 0.1);
    const vec3 COL2 = vec3(0.48, 0.35, 0.27);
    const vec3 COL3 = vec3(0.5, 0.5, 0.4);
    const vec3 COL4 = vec3(0.95, 0.97, 1.0);
    const vec3 COL5 = vec3(0.7, 0.6, 0.5);
    const vec3 COL6 = vec3(0.3, 0.3, 0.2);
    const vec3 COL7 = vec3(0.4, 0.25, 0.15) * 0.5;


    vec3 grassCol = mix(mix(COL0, COL1, smallFbm), COL5, largeFbm);
    vec3 mudCol = mix(COL2, COL7, mediumPerlin);
    vec3 rockCol = mix(COL3, COL6, mediumPerlin);

    if (t < 0.2) {
        return grassCol;
    }
    else if (t >= 0.2 && t < 0.3) {
        return mix(grassCol, mudCol, quinticFalloff((t - 0.2) / 0.1));
    }
    else if (t >= 0.3 && t < 0.5) {
        return mix(mudCol, rockCol, quinticFalloff((t - 0.3) / 0.2));
    }
    else if (t >= 0.5 && t < 0.8) {
        return mix(rockCol, COL4, quinticFalloff((t - 0.5) / 0.3));
    }
    else {
        return COL4;
    }
}

vec3 getBiomeColor(int biome, vec3 pos) {
    if (biome == 0) {
        return getMountainsColor(pos);
    }
    if (biome == 1) {
        return vec3(1, 1, 0);
    }
}

float getLambertianFactor(float sunAngle) {
    const float AMBIENT = 0.3;
    /*if (sunAngle < 0.0 || sunAngle > 180.0) {
        return AMBIENT;
    }*/
    vec3 lightDir = vec3(cos(radians(sunAngle)), sin(radians(sunAngle)), 0.0);
    float lamberianFactor = dot(fs_Nor.xyz, lightDir);
    return max(AMBIENT, lamberianFactor);
}

void main() {
    float t = clamp(smoothstep(40.0, 50.0, length(fs_Pos)), 0.0, 1.0); // Distance fog
    vec3 skyColor = vec3(0.64, 0.91, 1.0);
    vec3 noisePos = fs_Pos + vec3(u_PlanePos.x, 0, u_PlanePos.y);

    vec3 terrainCol = getBiomeColor(int(floor(fs_Biome)), noisePos);
    //float sunAngle = mod(float(u_Time), 360.0);
    //float lambert = getLambertianFactor(sunAngle);
    //terrainCol *= lambert;

    out_Col = vec4(mix(terrainCol, skyColor, t), 1.0);
}
