//
//  ThermostatShaders.metal
//  DemoView
//
//  Metal shaders for thermostat visual effects
//

#include <metal_stdlib>
#include <SwiftUI/SwiftUI_Metal.h>
using namespace metal;

// MARK: - Noise Functions

float hash(float2 p) {
    return fract(sin(dot(p, float2(127.1, 311.7))) * 43758.5453);
}

float noise(float2 p) {
    float2 i = floor(p);
    float2 f = fract(p);
    f = f * f * (3.0 - 2.0 * f);

    float a = hash(i);
    float b = hash(i + float2(1.0, 0.0));
    float c = hash(i + float2(0.0, 1.0));
    float d = hash(i + float2(1.0, 1.0));

    return mix(mix(a, b, f.x), mix(c, d, f.x), f.y);
}

float smoothNoise(float2 p) {
    float2 i = floor(p);
    float2 f = fract(p);

    // Quintic interpolation for smoother results
    float2 u = f * f * f * (f * (f * 6.0 - 15.0) + 10.0);

    float a = hash(i);
    float b = hash(i + float2(1.0, 0.0));
    float c = hash(i + float2(0.0, 1.0));
    float d = hash(i + float2(1.0, 1.0));

    return mix(mix(a, b, u.x), mix(c, d, u.x), u.y);
}

float fbm(float2 p, int octaves) {
    float value = 0.0;
    float amplitude = 0.5;
    float frequency = 1.0;
    for (int i = 0; i < octaves; i++) {
        value += amplitude * smoothNoise(p * frequency);
        frequency *= 2.0;
        amplitude *= 0.5;
    }
    return value;
}

// MARK: - Thermostat Plasma Fill

[[stitchable]] half4 thermostatPlasma(
    float2 position,
    SwiftUI::Layer layer,
    float2 size,
    float temperature,  // 0 = cold, 1 = hot
    float time
) {
    half4 original = layer.sample(position);
    if (original.a < 0.01h) return original;

    float2 uv = position / size;
    half temp = half(temperature);

    // === PLASMA SWIRL PATTERNS ===
    // Multiple rotating plasma arms
    float2 center = float2(0.5, 0.5);
    float2 toCenter = uv - center;
    float angle = atan2(toCenter.y, toCenter.x);
    float dist = length(toCenter);

    // Swirling vortex - rotates based on temperature
    float swirl1 = sin(angle * 3.0 + dist * 12.0 - time * 4.0) * 0.5 + 0.5;
    float swirl2 = sin(angle * 5.0 - dist * 8.0 + time * 3.0) * 0.5 + 0.5;
    float swirl3 = cos(angle * 2.0 + dist * 15.0 - time * 5.0) * 0.5 + 0.5;

    // === ELECTRIC TENDRILS ===
    float tendril1 = pow(abs(sin(uv.y * 20.0 + sin(uv.x * 10.0 + time * 6.0) * 3.0)), 8.0);
    float tendril2 = pow(abs(sin(uv.y * 25.0 - cos(uv.x * 8.0 - time * 5.0) * 4.0)), 6.0);
    float tendril3 = pow(abs(cos(uv.x * 15.0 + sin(uv.y * 12.0 + time * 4.0) * 2.0)), 7.0);
    float tendrils = max(max(tendril1, tendril2), tendril3);

    // === RISING ENERGY WAVES ===
    float wave1 = sin(uv.y * 8.0 - time * 6.0 + sin(uv.x * 6.0) * 2.0) * 0.5 + 0.5;
    float wave2 = sin(uv.y * 12.0 - time * 8.0 - cos(uv.x * 4.0) * 3.0) * 0.5 + 0.5;
    float waves = wave1 * wave2;
    waves = pow(waves, 0.7);

    // === BRIGHT CORE ===
    float coreX = abs(uv.x - 0.5) * 2.0;
    float core = 1.0 - pow(coreX, 1.2);
    core = max(0.0, core);

    // Pulsating core
    float corePulse = sin(time * 8.0) * 0.15 + sin(time * 12.0) * 0.1;
    core *= (1.0 + corePulse);

    // === SPARKING PARTICLES ===
    float spark1 = pow(noise(uv * 50.0 + time * 10.0), 15.0);
    float spark2 = pow(noise(uv * 40.0 - time * 8.0 + 100.0), 12.0);
    float spark3 = pow(noise(uv * 60.0 + float2(time * 6.0, -time * 9.0)), 18.0);
    float sparks = (spark1 + spark2 + spark3) * 3.0;

    // === ENERGY BLOBS ===
    float blob1 = smoothNoise(float2(uv.x * 4.0 + sin(time * 2.0), uv.y * 5.0 - time * 3.0));
    float blob2 = smoothNoise(float2(uv.x * 6.0 - cos(time * 1.5), uv.y * 4.0 - time * 2.5));
    float blobs = pow((blob1 + blob2) * 0.5, 1.5);

    // === COMBINE BASE INTENSITY ===
    float plasma = swirl1 * 0.25 + swirl2 * 0.2 + swirl3 * 0.15;
    float intensity = plasma * 0.4 + waves * 0.25 + core * 0.35;
    intensity += tendrils * 0.4 + blobs * 0.2;
    intensity += sparks * 0.8;

    // Global pulse
    float globalPulse = 0.85 + 0.15 * sin(time * 3.0);
    intensity *= globalPulse;

    half3 finalColor;

    if (temp < 0.3h) {
        // === FROZEN PLASMA / ICE ENERGY ===
        float coldFactor = 1.0 - (temp / 0.3);

        // Frozen crystal fractures
        float fracture1 = abs(sin(uv.x * 30.0 + uv.y * 25.0));
        float fracture2 = abs(sin(uv.x * 20.0 - uv.y * 35.0 + 1.0));
        float fractures = pow(min(fracture1, fracture2), 0.3);

        // Ice colors - electric blue
        half3 iceCore = half3(1.0h, 1.0h, 1.0h);
        half3 iceBright = half3(0.7h, 0.9h, 1.0h);
        half3 iceMid = half3(0.3h, 0.7h, 1.0h);
        half3 iceDeep = half3(0.1h, 0.4h, 0.9h);
        half3 iceDark = half3(0.05h, 0.2h, 0.6h);

        // Aurora shimmer
        float aurora = sin(uv.y * 15.0 - time * 2.0) * sin(uv.x * 8.0 + time) * 0.5 + 0.5;
        aurora = pow(aurora, 2.0);

        // Frozen sparks
        float frozenSpark = pow(noise(uv * 80.0 + time * 2.0), 20.0) * coldFactor * 5.0;

        float iceIntensity = intensity * (0.7 + fractures * 0.3);
        iceIntensity += aurora * 0.2 * coldFactor;
        iceIntensity = clamp(iceIntensity, 0.0, 1.5);

        if (iceIntensity > 1.0) {
            finalColor = iceCore;
        } else if (iceIntensity > 0.7) {
            finalColor = mix(iceBright, iceCore, (iceIntensity - 0.7h) * 3.33h);
        } else if (iceIntensity > 0.4) {
            finalColor = mix(iceMid, iceBright, (iceIntensity - 0.4h) * 3.33h);
        } else if (iceIntensity > 0.2) {
            finalColor = mix(iceDeep, iceMid, (iceIntensity - 0.2h) * 5.0h);
        } else {
            finalColor = mix(iceDark, iceDeep, iceIntensity * 5.0h);
        }

        // Add cyan/purple aurora tint
        half3 auroraTint = mix(half3(0.2h, 0.8h, 1.0h), half3(0.6h, 0.3h, 1.0h), half(aurora));
        finalColor += auroraTint * half(aurora * coldFactor * 0.3);

        // Frozen sparkles
        finalColor += half3(frozenSpark);

    } else if (temp < 0.45h) {
        // === TRANSITION - Purple/Magenta Energy ===
        float blend = (temp - 0.3h) / 0.15h;

        half3 coolPlasma = half3(0.4h, 0.6h, 1.0h);
        half3 warmPlasma = half3(1.0h, 0.4h, 0.8h);
        half3 hotPlasma = half3(1.0h, 0.6h, 0.3h);

        half3 baseColor = mix(coolPlasma, warmPlasma, half(blend));
        finalColor = baseColor * half(intensity);

        // Add white-hot center
        if (intensity > 0.8) {
            finalColor = mix(finalColor, half3(1.0h), half((intensity - 0.8) * 2.0));
        }

        // Purple lightning
        float lightning = pow(tendrils, 0.5) * 0.5;
        finalColor += half3(0.8h, 0.3h, 1.0h) * half(lightning);

    } else {
        // === FIRE PLASMA / SOLAR ENERGY ===
        float hotFactor = (temp - 0.45h) / 0.55h;

        // Fire plasma colors
        half3 fireCore = half3(1.0h, 1.0h, 0.95h);      // White hot
        half3 fireBright = half3(1.0h, 0.95h, 0.6h);    // Yellow
        half3 fireHot = half3(1.0h, 0.7h, 0.2h);        // Orange-yellow
        half3 fireMid = half3(1.0h, 0.45h, 0.1h);       // Orange
        half3 fireDeep = half3(0.9h, 0.2h, 0.05h);      // Red-orange
        half3 fireDark = half3(0.5h, 0.1h, 0.02h);      // Dark red

        // Intensify effects when hotter
        float fireIntensity = intensity * (1.0 + hotFactor * 0.5);

        // Solar flares
        float flare1 = pow(smoothNoise(float2(uv.x * 6.0 + time * 3.0, uv.y * 4.0 - time * 5.0)), 4.0);
        float flare2 = pow(smoothNoise(float2(uv.x * 8.0 - time * 2.0, uv.y * 6.0 - time * 4.0)), 3.0);
        float flares = (flare1 + flare2) * hotFactor;
        fireIntensity += flares * 0.4;

        // Eruption bursts
        float burst = pow(noise(float2(time * 15.0, uv.y * 3.0)), 10.0) * core;
        fireIntensity += burst * hotFactor * 0.6;

        fireIntensity = clamp(fireIntensity, 0.0, 1.8);

        if (fireIntensity > 1.2) {
            finalColor = fireCore;
        } else if (fireIntensity > 0.9) {
            finalColor = mix(fireBright, fireCore, (fireIntensity - 0.9h) * 3.33h);
        } else if (fireIntensity > 0.65) {
            finalColor = mix(fireHot, fireBright, (fireIntensity - 0.65h) * 4.0h);
        } else if (fireIntensity > 0.4) {
            finalColor = mix(fireMid, fireHot, (fireIntensity - 0.4h) * 4.0h);
        } else if (fireIntensity > 0.2) {
            finalColor = mix(fireDeep, fireMid, (fireIntensity - 0.2h) * 5.0h);
        } else {
            finalColor = mix(fireDark, fireDeep, fireIntensity * 5.0h);
        }

        // Fire sparks and embers
        float ember = sparks * hotFactor;
        finalColor += half3(1.0h, 0.8h, 0.3h) * half(ember);

        // Plasma tendrils glow
        float tendrilGlow = tendrils * hotFactor * 0.6;
        finalColor += half3(1.0h, 0.9h, 0.5h) * half(tendrilGlow);
    }

    return half4(finalColor, original.a);
}

// MARK: - Plasma Distortion

[[stitchable]] float2 plasmaDistortion(
    float2 position,
    float2 size,
    float time,
    float intensity,
    float temperature
) {
    float2 uv = position / size;

    // Scale effect by temperature - more chaotic when hot, crystalline when cold
    float tempScale = 0.5 + temperature * 0.8;
    float adjustedIntensity = intensity * tempScale;

    // Chaotic plasma waves
    float wave1 = sin(uv.y * 15.0 - time * 5.0 + sin(uv.x * 8.0 + time * 3.0) * 2.0);
    float wave2 = cos(uv.y * 20.0 - time * 6.0 - cos(uv.x * 10.0 - time * 4.0) * 1.5);
    float wave3 = sin(uv.x * 12.0 + uv.y * 8.0 - time * 4.0);

    // Electric jitter
    float jitter1 = noise(uv * 30.0 + time * 8.0) - 0.5;
    float jitter2 = noise(uv * 25.0 - time * 6.0 + 50.0) - 0.5;

    // Contain movement toward center
    float centerDist = abs(uv.x - 0.5) * 2.0;
    float containment = 1.0 - pow(centerDist, 1.3);
    containment = max(0.0, containment);

    // Rising turbulence
    float rise = sin(uv.y * 10.0 - time * 7.0) + cos(uv.y * 6.0 - time * 5.0) * 0.5;

    // Combine waves
    float2 offset;

    if (temperature < 0.35) {
        // Cold - more crystalline, sharp movements
        float crystal = sin(uv.x * 25.0 + uv.y * 30.0) * sin(uv.y * 20.0 - time * 2.0);
        offset = float2(
            (wave1 * 0.4 + crystal * 0.3 + jitter1 * 0.15) * adjustedIntensity * containment * 5.0,
            (rise * 0.3 + jitter2 * 0.1) * adjustedIntensity * containment * 3.0
        );
    } else {
        // Hot - chaotic plasma motion
        offset = float2(
            (wave1 * 0.5 + wave2 * 0.3 + wave3 * 0.2 + jitter1 * 0.25) * adjustedIntensity * containment * 8.0,
            (rise * 0.6 + jitter2 * 0.2) * adjustedIntensity * containment * 6.0
        );
    }

    return position + offset;
}

// MARK: - Dynamic Background (unchanged)

[[stitchable]] half4 dynamicBackground(
    float2 position,
    half4 color,
    float2 size,
    float temperature,
    float time
) {
    float2 uv = position / size;
    half temp = half(temperature);

    half3 bgColor;

    if (temp < 0.35h) {
        float coldness = 1.0 - (temp / 0.35);

        half3 coldDark = half3(0.01h, 0.03h, 0.1h);
        half3 coldMid = half3(0.03h, 0.08h, 0.2h);

        float wave = sin(uv.x * 3.0 + time * 0.3) * sin(uv.y * 2.0 - time * 0.2) * 0.5 + 0.5;
        bgColor = mix(coldDark, coldMid, half(wave * coldness * 0.4));

        float sparkle = pow(noise(uv * 60.0 + time * 0.3), 12.0) * coldness;
        bgColor += half3(sparkle * 0.3h, sparkle * 0.5h, sparkle * 0.8h);

    } else if (temp < 0.5h) {
        float blend = (temp - 0.35h) / 0.15h;
        half3 coolBg = half3(0.03h, 0.05h, 0.12h);
        half3 warmBg = half3(0.12h, 0.03h, 0.01h);
        bgColor = mix(coolBg, warmBg, half(blend));

    } else {
        float hotness = (temp - 0.5h) / 0.5h;

        half3 hotDark = half3(0.08h, 0.01h, 0.0h);
        half3 hotMid = half3(0.2h, 0.04h, 0.0h);

        float wave = sin(uv.y * 6.0 - time * 1.5) * 0.5 + 0.5;
        wave *= sin(uv.x * 4.0 + time) * 0.3 + 0.7;

        bgColor = mix(hotDark, hotMid, half(wave * hotness * 0.6));

        float glow = (1.0 - uv.y) * hotness * 0.1;
        bgColor += half3(glow, glow * 0.2h, 0.0h);
    }

    return half4(bgColor, 1.0h);
}

// MARK: - Floating Particles (unchanged)

[[stitchable]] half4 floatingParticles(
    float2 position,
    half4 color,
    float2 size,
    float temperature,
    float time
) {
    float2 uv = position / size;
    half temp = half(temperature);
    half4 result = color;

    bool isHot = temp > 0.5h;

    for (int layer = 0; layer < 3; layer++) {
        float layerOffset = float(layer) * 1.5;
        float layerSpeed = isHot ? (0.8 + float(layer) * 0.4) : (0.2 + float(layer) * 0.15);
        float layerSize = 0.012 - float(layer) * 0.002;

        float2 grid = float2(10.0 + float(layer) * 5.0, 15.0 + float(layer) * 4.0);
        float direction = isHot ? -1.0 : 1.0;

        float2 cellUV = fract(uv * grid + float2(sin(time * 0.3 + layerOffset) * 0.1, direction * time * layerSpeed + layerOffset));
        float2 cellID = floor(uv * grid + float2(0.0, direction * time * layerSpeed + layerOffset));

        float randX = hash(cellID) * 0.5;
        float randY = hash(cellID + 100.0) * 0.5;

        float2 particlePos = float2(0.5 + randX - 0.25, 0.5 + randY - 0.25);
        particlePos.x += sin(time * 1.5 + hash(cellID) * 6.28) * 0.08;

        float dist = length(cellUV - particlePos);
        float particle = smoothstep(layerSize, 0.0, dist);
        particle *= hash(cellID + 200.0);

        half3 particleColor;
        if (isHot) {
            float heat = hash(cellID + 300.0);
            particleColor = mix(half3(1.0h, 0.2h, 0.0h), half3(1.0h, 0.7h, 0.2h), half(heat));
        } else {
            particleColor = half3(0.7h, 0.85h, 1.0h);
            float sparkle = pow(sin(time * 8.0 + hash(cellID) * 50.0) * 0.5 + 0.5, 3.0);
            particleColor += half3(sparkle * 0.2h);
        }

        float visibility = isHot ? (temp - 0.5h) * 2.0 : (0.5h - temp) * 2.0;
        visibility = clamp(visibility, 0.0, 1.0);

        result.rgb += particleColor * half(particle * visibility * 0.5);
    }

    return result;
}

// MARK: - Temperature Text Effect (UNCHANGED - user loves this!)

[[stitchable]] half4 temperatureText(
    float2 position,
    SwiftUI::Layer layer,
    float2 size,
    float temperature,
    float time
) {
    half temp = half(temperature);

    // Subtle shimmer
    float shimmerX = sin(position.y * 0.05 + time * 5.0) * (temp > 0.5 ? 2.0 : 1.0);
    float shimmerY = cos(position.x * 0.08 + time * 4.0) * (temp > 0.5 ? 1.5 : 0.8);

    half4 original = layer.sample(position + float2(shimmerX, shimmerY));

    // Glow
    half4 glow = half4(0.0h);
    float glowRadius = 12.0;
    float samples = 0.0;

    for (float x = -glowRadius; x <= glowRadius; x += 2.5) {
        for (float y = -glowRadius; y <= glowRadius; y += 2.5) {
            float dist = length(float2(x, y));
            if (dist <= glowRadius) {
                half4 s = layer.sample(position + float2(x + shimmerX * 0.5, y + shimmerY * 0.5));
                float weight = 1.0 - (dist / glowRadius);
                weight = pow(weight, 1.8);
                glow += s * half(weight);
                samples += weight;
            }
        }
    }
    glow /= half(samples);

    half3 textColor;
    half3 glowColor;

    if (temp < 0.35h) {
        textColor = half3(0.9h, 0.95h, 1.0h);
        glowColor = half3(0.3h, 0.6h, 1.0h);
    } else if (temp < 0.5h) {
        float blend = (temp - 0.35h) / 0.15h;
        textColor = mix(half3(0.9h, 0.95h, 1.0h), half3(1.0h, 0.9h, 0.8h), half(blend));
        glowColor = mix(half3(0.3h, 0.6h, 1.0h), half3(1.0h, 0.5h, 0.2h), half(blend));
    } else {
        float hotness = (temp - 0.5h) / 0.5h;
        textColor = mix(half3(1.0h, 0.85h, 0.6h), half3(1.0h, 0.95h, 0.9h), half(hotness * 0.5));
        glowColor = half3(1.0h, 0.4h + hotness * 0.2h, 0.1h);

        // Flicker
        float flicker = 0.92 + 0.08 * sin(time * 15.0 + position.x * 0.03);
        textColor *= half(flicker);
    }

    float pulse = 0.9 + 0.1 * sin(time * 2.5);

    half3 finalColor = original.rgb;
    if (original.a > 0.1h) {
        finalColor = textColor;
    }
    finalColor += glowColor * glow.a * half(pulse * 1.2);

    return half4(finalColor, max(original.a, glow.a * 0.6h));
}

// MARK: - Outer Glow (unchanged)

[[stitchable]] half4 temperatureOuterGlow(
    float2 position,
    half4 color,
    float2 size,
    float2 center,
    float radius,
    float temperature,
    float time
) {
    float dist = length(position - center);
    half temp = half(temperature);

    float glow1 = 1.0 - smoothstep(0.0, radius * 1.8, dist);
    float glow2 = 1.0 - smoothstep(0.0, radius * 3.0, dist);
    float glow3 = 1.0 - smoothstep(0.0, radius * 4.5, dist);

    glow1 = pow(glow1, 2.0);
    glow2 = pow(glow2, 2.8);
    glow3 = pow(glow3, 3.5);

    float pulse = 0.85 + 0.15 * sin(time * 2.5);

    half3 glowColor;

    if (temp < 0.35h) {
        half3 iceGlow = half3(0.3h, 0.6h, 1.0h);
        glowColor = iceGlow * half((glow1 + glow2 * 0.5 + glow3 * 0.3) * pulse);
    } else if (temp < 0.5h) {
        float blend = (temp - 0.35h) / 0.15h;
        half3 mixed = mix(half3(0.3h, 0.5h, 0.9h), half3(0.9h, 0.4h, 0.15h), half(blend));
        glowColor = mixed * half((glow1 + glow2 + glow3) * pulse * 0.4);
    } else {
        half3 fireInner = half3(1.0h, 0.6h, 0.2h);
        half3 fireOuter = half3(0.7h, 0.2h, 0.0h);
        glowColor = fireInner * half(glow1 * pulse) + fireOuter * half((glow2 + glow3) * pulse * 0.5);
    }

    return half4(color.rgb + glowColor, color.a);
}
