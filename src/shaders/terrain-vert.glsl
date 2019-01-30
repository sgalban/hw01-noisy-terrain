#version 300 es


uniform mat4 u_Model;
uniform mat4 u_ModelInvTr;
uniform mat4 u_ViewProj;
uniform vec2 u_PlanePos; // Our location in the virtual world displayed by the plane

in vec4 vs_Pos;
in vec4 vs_Nor;
in vec4 vs_Col;

out vec3 fs_Pos;
out vec4 fs_Nor;
out vec4 fs_Col;

out float fs_Sine;
out float fs_Biome;

const vec2 SEED2 = vec2(0.1234, 0.5678);
const float MAX_AMPLITUDE = 40.0;

float random1( vec2 p , vec2 seed) {
    return fract(sin(dot(p + seed, vec2(127.1, 311.7))) * 43758.5453);
}

float random1( vec3 p , vec3 seed) {
    return fract(sin(dot(p + seed, vec3(987.654, 123.456, 531.975))) * 85734.3545);
}

vec2 random2( vec2 p , vec2 seed) {
    return fract(sin(vec2(dot(p + seed, vec2(311.7, 127.1)), dot(p + seed, vec2(269.5, 183.3)))) * 85734.3545);
}

float fbm(vec2 pos) {
    pos /= 10.0;
    float value = 0.0;
    float amplitude = 0.5;
    float frequency = 0.0;
    float persistence = 0.25;

    for (int i = 0; i < 10; i++) {
        value += amplitude * random1(pos, vec2(0));
        pos *= persistence;
        amplitude *= .5;
    }
    return value;
}

float quinticFalloff(float t) {
    return t * t * t * (t * (6.0 * t - 15.0) + 10.0);
}

float perlin (vec2 noisePos, float frequency, vec2 seed) {
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

    vec2 gradient0 = normalize(random2(corner0, seed) * (random1(corner0, seed) > 0.5 ? 1.0 : -1.0));
    vec2 gradient1 = normalize(random2(corner1, seed) * (random1(corner1, seed) > 0.5 ? 1.0 : -1.0));
    vec2 gradient2 = normalize(random2(corner2, seed) * (random1(corner2, seed) > 0.5 ? 1.0 : -1.0));
    vec2 gradient3 = normalize(random2(corner3, seed) * (random1(corner3, seed) > 0.5 ? 1.0 : -1.0));
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
        total += perlin(noisePos, curFrequency, SEED2) * curAmplitude;
        curFrequency *= FREQUENCY_FACTOR;
    }
    return total;
}

float brownianNoise(vec2 noisePos, vec2 seed) {
    vec2 cellPos = vec2(floor(noisePos.x), floor(noisePos.y));

    // Get the noise at the corners of the cells
    float corner0 = random1(cellPos + vec2(0.0, 0.0), seed);
    float corner1 = random1(cellPos + vec2(1.0, 0.0), seed);
    float corner2 = random1(cellPos + vec2(0.0, 1.0), seed);
    float corner3 = random1(cellPos + vec2(1.0, 1.0), seed);

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

int getBiome(float temperature, float moisture) {
    if (temperature > 0.555 && moisture < 0.4) {
        return 1; // Desert
    }
    else {
        return 0; // Hills
    }
}

void main() {
    /*float moisture = perlin(vs_Pos.xz + u_PlanePos, 0.01, SEED2 + vec2(0.4));
    float temperature = perlin(vs_Pos.xz + u_PlanePos, 0.015, SEED2 + vec2(0.2));

    float vertHeight = 0.0;

    int biome = getBiome(temperature, moisture);

    if (biome == 0) {
        vertHeight = (pow(recursivePerlin(vs_Pos.xz + u_PlanePos, 4, 0.1), 3.0)) * MAX_AMPLITUDE;
    }
    else if (biome == 1) {
        vertHeight = 0.0;
    }*/
    int biome = 0;
    fs_Biome = float(biome);
    float vertHeight = pow(fbm(vs_Pos.xz + u_PlanePos, 7, 0.1), 3.0) * 10.0;
    vec4 modelposition = vec4(vs_Pos.x, vertHeight, vs_Pos.z, 1);
    fs_Pos = modelposition.xyz;

    modelposition = u_Model * modelposition;
    gl_Position = u_ViewProj * modelposition;
}
