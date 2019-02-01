#version 300 es


uniform mat4 u_Model;
uniform mat4 u_ModelInvTr;
uniform mat4 u_ViewProj;
uniform vec2 u_PlanePos; // Our location in the virtual world displayed by the plane
uniform highp int u_Time;

in vec4 vs_Pos;
in vec4 vs_Nor;
in vec4 vs_Col;

out vec3 fs_Pos;
out vec4 fs_Nor;
out vec4 fs_Col;

out float fs_Sine;
out float fs_Moisture;
out float fs_Temperature;

const vec2 SEED2 = vec2(0.1234, 0.5678);

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

float cubicFalloff(float t) {
    return t * t * (3.0 - 2.0 * t);
}

float steepFalloff(float t, float falloffStart, float falloffLength) {
    if (t >= 1.0 || t > falloffStart + falloffLength) {
        return 1.0;
    }
    if (t < falloffStart) {
        return 0.0;
    }
    float adjusted = (t - falloffStart) / falloffLength;
    return quinticFalloff(adjusted);
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

    vec2 gradient0 = normalize(random2(corner0, seed) * 2.0 - vec2(1.0));
    vec2 gradient1 = normalize(random2(corner1, seed) * 2.0 - vec2(1.0));
    vec2 gradient2 = normalize(random2(corner2, seed) * 2.0 - vec2(1.0));
    vec2 gradient3 = normalize(random2(corner3, seed) * 2.0 - vec2(1.0));
    float val0 = dot(posVec0, gradient0);
    float val1 = dot(posVec1, gradient1);
    float val2 = dot(posVec2, gradient2);
    float val3 = dot(posVec3, gradient3);

    float tx = cubicFalloff(fract(pos.x));
    float ty = cubicFalloff(fract(pos.y));
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

    float frequency = startFrequency;
    float amplitude = PERSISTENCE;

    for (int i = 0; i < numOctaves; i++) {
        normalizer += amplitude;
        totalNoise += brownianNoise(noisePos * frequency, SEED2) * amplitude;
        frequency *= 2.0;
        amplitude *= PERSISTENCE;
    }
    return totalNoise / normalizer;
}

float getBiome(float temperature, float moisture) {
    return moisture;
}

float getMountainHeight(vec2 pos) {
    const float MAX_AMPLITUDE = 12.0;
    const float EXTRA_JAGGINESS = 2.0;
    float terrainFbm = fbm(pos, 6, 0.08);

    float fmbVal = terrainFbm;
    float height = fmbVal * fmbVal * fmbVal * MAX_AMPLITUDE;
    height = height + (mix(0.0, brownianNoise(pos, SEED2), height / MAX_AMPLITUDE)) * EXTRA_JAGGINESS;
    return height * MAX_AMPLITUDE / (MAX_AMPLITUDE + EXTRA_JAGGINESS);
}

float getDesertHeight(vec2 pos) {
    const float MAX_AMPLITUDE = 12.0;
    float mesaFbm = fbm(pos, 6, 0.03);
    float dunes = recursivePerlin(pos, 2, 0.1) * MAX_AMPLITUDE * 0.25;
    float mesas = steepFalloff(mesaFbm, 0.7, 0.1) * MAX_AMPLITUDE;
    return max(dunes, mesas);
}

float getOceanHeight(vec2 pos) {
    const float MAX_AMPLITUDE = 12.0;
    float largePerlin = recursivePerlin(pos, 2, 0.08);
    float medPerlin = recursivePerlin(pos, 2, 0.30);
    float islands = (1.0 - steepFalloff(largePerlin, 0.35, 0.2)) * MAX_AMPLITUDE * 0.2;
    return MAX_AMPLITUDE * 0.09 - islands;
}

float getHeight(vec2 pos, float biome) {
    if (biome < 0.25) {
        return getDesertHeight(pos);
    }
    else if (biome >= 0.25 && biome < 0.30) {
        return mix(getDesertHeight(pos), getMountainHeight(pos), (biome - 0.25) / 0.05);
    }
    else if (biome >= 0.30 && biome < 0.65) {
        return getMountainHeight(pos);
    }
    else if (biome >= 0.65 && biome < 0.75) {
        return mix(getMountainHeight(pos), getOceanHeight(pos), (biome - 0.65) / 0.1);
    }
    else {
        return getOceanHeight(pos);
    }
}

void main() {
    fs_Moisture = quinticFalloff(perlin(vs_Pos.xz + u_PlanePos, 0.005, SEED2 + vec2(0.4)));
    fs_Temperature = 0.0;//quinticFalloff(perlin(vs_Pos.xz + u_PlanePos, 0.015, SEED2 + vec2(0.2)));

    float biome = getBiome(fs_Temperature, fs_Moisture);

    float vertHeight = getHeight(vs_Pos.xz + u_PlanePos, biome);
    vec4 modelposition = vec4(vs_Pos.x, vertHeight, vs_Pos.z, 1);
    fs_Pos = modelposition.xyz;

    modelposition = u_Model * modelposition;
    gl_Position = u_ViewProj * modelposition;

    // Unfortunately, steepness calculations are too slow for my browser
    /*const float DPOS = 0.01;
    vec3 p1 = vec3(vs_Pos.x, vertHeight, vs_Pos.z);
    vec3 p2 = vec3(vs_Pos.x + DPOS, getHeight(vs_Pos.xz + vec2(DPOS, 0.0) + u_PlanePos), vs_Pos.z);
    vec3 p3 = vec3(vs_Pos.x, getHeight(vs_Pos.xz + vec2(0.0, DPOS) + u_PlanePos), vs_Pos.z + DPOS);
    fs_Nor = vec4(normalize(cross(p3 - p1, p2 - p1)), 0.0);*/
}
