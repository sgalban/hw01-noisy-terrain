#version 300 es
precision highp float;

uniform vec2 u_PlanePos; // Our location in the virtual world displayed by the plane
uniform highp int u_Time;
uniform highp int u_UseLight;

in vec3 fs_Pos;
in vec4 fs_Nor;
in vec4 fs_Col;

in float fs_Sine;

in float fs_Moisture;

out vec4 out_Col; // This is the final output color that you will see on your
                  // screen for the pixel that is currently being processed.

const vec2 SEED2 = vec2(0.31415, 0.6456);
const vec3 SEED3 = vec3(0.1, 0.22, 0.31);

const float PI = 3.1415926;

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

float cubicFalloff(float t) {
    return t * t * (3.0 - 2.0 * t);
}

float steepFalloff(float t, float falloffStart, float falloffLength) {
    if (t < falloffStart) {
        return 0.0;
    }
    else if (t > falloffStart + falloffLength){
        return 1.0;
    }
    float adjusted = (t - falloffStart) / falloffLength;
    return quinticFalloff(adjusted);
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

    vec2 gradient0 = normalize(random2(corner0, SEED2) * 2.0 - vec2(1.0));
    vec2 gradient1 = normalize(random2(corner1, SEED2) * 2.0 - vec2(1.0));
    vec2 gradient2 = normalize(random2(corner2, SEED2) * 2.0 - vec2(1.0));
    vec2 gradient3 = normalize(random2(corner3, SEED2) * 2.0 - vec2(1.0));
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
        total += perlin(noisePos, curFrequency) * curAmplitude;
        curFrequency *= FREQUENCY_FACTOR;
    }
    return total;
}

// I tried to make this 3D, but it cut my framerate in half, so I'm not doing that now
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

float worley(vec2 noisePos, float frequency) {
    vec2 point = noisePos * frequency;
    vec2 cell = floor(point);

    // Check the neighboring cells for the closest cell point
    float closestDistance = 2.0;
    for (int i = 0; i < 9; i++) {
        vec2 curCell = cell + vec2(i % 3 - 1, floor(float(i / 3) - 1.0));
        vec2 cellPoint = vec2(curCell) + random2(vec2(curCell), SEED2);
        closestDistance = min(closestDistance, distance(cellPoint, point));
    }
    return clamp(0.0, 1.0, closestDistance);
}

vec3 getMountainsColor(vec3 pos) {
    float t = min(pos.y * 0.15 + ((fbm(pos.xz, 3, 0.5)) - 0.5) * 0.4, 1.0);

    float largeFbm = fbm(fs_Pos.xz + u_PlanePos, 3, 0.075);
    float smallPerlin = recursivePerlin(pos.xz, 2, 5.0);
    float mediumPerlin = recursivePerlin(fs_Pos.xz + u_PlanePos, 2, 1.0);

    const vec3 COL0 = vec3(0.1, 0.4, 0.07);
    const vec3 COL1 = vec3(0.3, 0.5, 0.1);
    const vec3 COL2 = vec3(0.48, 0.35, 0.27);
    const vec3 COL3 = vec3(0.5, 0.5, 0.4);
    const vec3 COL4 = vec3(0.95, 0.97, 1.0);
    const vec3 COL5 = vec3(0.7, 0.6, 0.5);
    const vec3 COL6 = vec3(0.3, 0.3, 0.2);
    const vec3 COL7 = vec3(0.4, 0.25, 0.15) * 0.5;


    vec3 grassCol = mix(mix(COL0, COL1, smallPerlin), COL5, largeFbm);
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

vec3 getDesertColor(vec3 pos) {
    float mediumPerlin = recursivePerlin(pos.xz, 2, 1.0);
    float smallPerlin = recursivePerlin(pos.xy + vec2(pos.z), 2, 2.0);
    float heightPerturbance = fbm(pos.xz, 3, 0.5) * 0.1;
    float y = pos.y + heightPerturbance * 20.0;

    const vec3 COL1 = vec3(1.0, 0.86, 0.3);
    const vec3 COL2 = vec3(0.92, 0.70, 0.43);
    const vec3 COL3 = vec3(0.77, 0.48, 0.24);
    const vec3 COL4 = vec3(0.70, 0.61, 0.34) * 1.2;
    float heightSine = sin(y * PI) * 0.03;
    vec3 sandCol = mix(COL1, COL2, mediumPerlin) * (pos.y * 0.3 / 3.0 + 0.7);
    vec3 rockCol = mix(COL3, COL4, smallPerlin) + vec3(y * 0.02, heightSine, heightSine - y * 0.02);
    vec3 topCol = mix(COL1, COL2, smallPerlin);

    float t = pos.y / 9.0;
    if (t < 0.15) {
        return sandCol;
    }
    else if (t >= 0.15 && t < 0.25) {
        return mix(sandCol, rockCol, quinticFalloff((t - 0.15) / 0.1));
    }
    else if (t >= 0.25 && t < 0.9 - heightPerturbance) {
        return rockCol;
    }
    else {
        return mix(rockCol, topCol, quinticFalloff((t - 0.9 + heightPerturbance) / (0.1 + heightPerturbance)));
    }
}

vec3 getOceanColor(vec3 pos) {
    float time = float(u_Time) * 0.01;
    vec2 perturbenceOffset = vec2(5.4 + time, 1.3 + time);
    vec2 worleyOffset = vec2(time);

    vec2 perturbence = vec2(fbm(pos.xz, 2, 0.3), fbm(pos.xz + perturbenceOffset, 2, 0.3));
    float worley1 = worley(pos.xz - worleyOffset - perturbence * 4.0, 0.3);
    //float worley2 = worley(pos.xz - worleyOffset - perturbence * 6.0, 0.3); Too slow
    float totalWorley = worley1;//(worley1 + worley2) * 0.5;

    float smallPerlin = recursivePerlin(pos.xz * (pos.y + 1.0), 2, 1.0);
    float smallFbm = fbm(pos.xz, 2, 1.0);

    const vec3 COL1 = vec3(0.1, 0.3, 0.9);
    const vec3 COL2 = vec3(0.4, 0.55, 0.95);
    const vec3 COL3 = vec3(0.9, 0.9, 0.4);
    const vec3 COL4 = vec3(0.85, 0.6, 0.4);
    const vec3 COL5 = vec3(0.0, 1.0, 0.2);
    const vec3 COL6 = vec3(0.0, 0.6, 0.1);

    vec3 waterCol = mix(COL1, COL2, worley1);
    vec3 sandCol = mix(COL3, COL4, smallPerlin);
    vec3 grassCol = mix(COL5, COL6, smallFbm);

    float tideFactor = 0.25 * (sin(time) + 1.0);

    if (pos.y < - 1.0 + tideFactor) {
        return waterCol;
    }
    if (pos.y >= -1.0 + tideFactor && pos.y < 0.0) {
        return mix(waterCol, sandCol, quinticFalloff(pos.y + 1.0));
    }
    else if (pos.y >= 0.0 && pos.y < 0.5) {
        return sandCol;
    }
    else if (pos.y >= 0.5 && pos.y < 1.5) {
        return mix(sandCol, grassCol, cubicFalloff(pos.y - 0.5));
    }
    else {
        return grassCol;
    }
}

vec3 getSnowyColor(vec3 pos) {
    return vec3(worley(pos.xz, 0.2));
    //return vec3(1.0) * mix(0.7, 1.0, pos.y / 6.0);
}


vec3 getBiomeColor(float biome, vec3 pos) {
    //return getDesertColor(pos);
    if (biome < 0.25) {
        return getDesertColor(pos);
    }
    else if (biome >= 0.25 && biome < 0.30) {
        return mix(getDesertColor(pos), getMountainsColor(pos), (biome - 0.25) / 0.05);
    }
    else if (biome >= 0.30 && biome < 0.65) {
        return getMountainsColor(pos);
    }
    else if (biome >= 0.65 && biome < 0.75) {
        return mix(getMountainsColor(pos), getOceanColor(pos), (biome - 0.65) / 0.1);
    }
    else {
        return getOceanColor(pos);
    }
}

float getLambertianFactor(float sunAngle) {
    const float AMBIENT = 0.3;
    vec3 lightDir = vec3(cos(radians(sunAngle)), sin(radians(sunAngle)), 0.0);
    float lamberianFactor = dot(fs_Nor.xyz, lightDir);
    return max(AMBIENT, lamberianFactor);
}

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
    float t = clamp(smoothstep(40.0, 50.0, length(fs_Pos)), 0.0, 1.0); // Distance fog
    vec3 noisePos = fs_Pos + vec3(u_PlanePos.x, 0, u_PlanePos.y);

    vec3 terrainCol = getBiomeColor(fs_Moisture, noisePos);
    float sunAngle = mod(float(u_Time) * 0.1 + 90.0, 360.0);

    if (u_UseLight > 0) {
        float lambert = getLambertianFactor(sunAngle);
        terrainCol *= lambert;
    }

    out_Col = vec4(mix(terrainCol, getSkyColor(sunAngle), t), 1.0);
}
