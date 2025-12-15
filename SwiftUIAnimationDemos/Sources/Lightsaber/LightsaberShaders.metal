//
//  LightsaberShaders.metal
//  DemoView
//
//  Metal shaders for lightsaber visual effects
//

#include <metal_stdlib>
#include <SwiftUI/SwiftUI_Metal.h>
using namespace metal;

// MARK: - Lightsaber Core Glow Shader
// Creates the intense plasma core of a lightsaber blade

[[stitchable]] half4 lightsaberCore(
    float2 position,
    SwiftUI::Layer layer,
    float2 size,
    half4 coreColor,
    half4 glowColor,
    float bladeWidth,
    float glowIntensity,
    float time
) {
    half4 original = layer.sample(position);
    if (original.a == 0.0h) return original;

    // Normalize coordinates
    half2 uv = half2(position / size);

    // Calculate distance from center line (vertical blade)
    half centerX = 0.5h;
    half distFromCenter = abs(uv.x - centerX);

    // Blade core (bright white/color center)
    half coreWidth = half(bladeWidth) * 0.3h;
    half coreFalloff = smoothstep(coreWidth, 0.0h, distFromCenter);

    // Inner glow
    half innerGlowWidth = half(bladeWidth) * 0.6h;
    half innerGlow = smoothstep(innerGlowWidth, coreWidth, distFromCenter);

    // Outer glow (softer, wider)
    half outerGlowWidth = half(bladeWidth);
    half outerGlow = smoothstep(outerGlowWidth, innerGlowWidth, distFromCenter);

    // Add subtle plasma flickering
    half flicker = 0.95h + 0.05h * half(sin(time * 30.0 + position.y * 0.1));

    // Add energy waves traveling up the blade
    half energyWave = 0.5h + 0.5h * half(sin(time * 10.0 - position.y * 0.05));

    // Combine effects
    half3 finalColor = half3(0.0h);

    // Outer glow (colored)
    finalColor += glowColor.rgb * outerGlow * half(glowIntensity) * 0.4h;

    // Inner glow (saturated color)
    finalColor += mix(glowColor.rgb, coreColor.rgb, 0.5h) * innerGlow * half(glowIntensity) * 0.7h;

    // Core (bright, almost white)
    half3 brightCore = mix(coreColor.rgb, half3(1.0h), 0.8h);
    finalColor += brightCore * coreFalloff * flicker;

    // Energy wave highlight
    finalColor += coreColor.rgb * coreFalloff * energyWave * 0.2h;

    // Apply to original
    half alpha = max(original.a, max(coreFalloff, max(innerGlow * 0.8h, outerGlow * 0.5h)));

    return half4(finalColor, alpha);
}

// MARK: - Lightsaber Blade Distortion
// Creates heat shimmer/energy distortion around the blade

[[stitchable]] float2 lightsaberDistortion(
    float2 position,
    float2 size,
    float time,
    float bladeWidth,
    float intensity
) {
    float2 uv = position / size;

    // Distance from blade center
    float centerX = 0.5;
    float distFromCenter = abs(uv.x - centerX);

    // Only distort near the blade
    float distortionZone = bladeWidth * 2.0;
    if (distFromCenter > distortionZone) {
        return position;
    }

    // Heat shimmer effect
    float shimmerStrength = (1.0 - distFromCenter / distortionZone) * intensity;

    float2 offset = float2(
        sin(position.y * 0.03 + time * 5.0) * shimmerStrength * 2.0,
        cos(position.x * 0.05 + time * 3.0) * shimmerStrength * 1.0
    );

    return position + offset;
}

// MARK: - Lightsaber Ambient Glow
// Creates the atmospheric light cast by the saber

[[stitchable]] half4 lightsaberAmbient(
    float2 position,
    half4 color,
    float2 size,
    float2 bladeCenter,
    half4 glowColor,
    float radius,
    float intensity,
    float time
) {
    // Distance from blade center
    float2 delta = position - bladeCenter;
    float dist = length(delta);

    // Radial falloff
    float falloff = 1.0 - smoothstep(0.0, radius, dist);
    falloff = pow(falloff, 2.0);

    // Pulsing effect
    float pulse = 0.9 + 0.1 * sin(time * 4.0);

    // Apply glow
    half3 glow = glowColor.rgb * half(falloff * intensity * pulse);

    return half4(color.rgb + glow, color.a);
}

// MARK: - Plasma Energy Effect
// Simulates the unstable plasma energy within the blade

[[stitchable]] half4 plasmaEnergy(
    float2 position,
    SwiftUI::Layer layer,
    float2 size,
    half4 primaryColor,
    half4 secondaryColor,
    float time,
    float turbulence
) {
    half4 original = layer.sample(position);
    if (original.a == 0.0h) return original;

    float2 uv = position / size;

    // Create flowing plasma noise
    float noise1 = sin(uv.x * 20.0 + time * 3.0) * cos(uv.y * 15.0 - time * 2.0);
    float noise2 = sin(uv.x * 30.0 - time * 4.0) * cos(uv.y * 25.0 + time * 3.0);
    float noise3 = sin(uv.y * 40.0 + time * 5.0);

    float combinedNoise = (noise1 + noise2 + noise3) / 3.0;
    combinedNoise = combinedNoise * 0.5 + 0.5; // Normalize to 0-1

    // Mix between primary and secondary colors based on noise
    half3 plasmaColor = mix(
        primaryColor.rgb,
        secondaryColor.rgb,
        half(combinedNoise * turbulence)
    );

    // Brighten based on original luminance
    half luminance = dot(original.rgb, half3(0.299h, 0.587h, 0.114h));
    plasmaColor = mix(plasmaColor, half3(1.0h), luminance * 0.5h);

    return half4(plasmaColor * original.a, original.a);
}

// MARK: - Ignition Flash Effect
// Creates the initial ignition burst

[[stitchable]] half4 ignitionFlash(
    float2 position,
    half4 color,
    float2 size,
    float2 origin,
    float progress,
    half4 flashColor,
    float maxRadius
) {
    // Distance from ignition point
    float dist = length(position - origin);

    // Expanding ring
    float currentRadius = progress * maxRadius;
    float ringWidth = maxRadius * 0.1;

    float ringDist = abs(dist - currentRadius);
    float ring = smoothstep(ringWidth, 0.0, ringDist);

    // Flash intensity (fades as it expands)
    float flashIntensity = (1.0 - progress) * ring;

    // Inner flash (bright burst)
    float innerFlash = (1.0 - progress * progress) * smoothstep(currentRadius * 0.5, 0.0, dist);

    half3 flash = flashColor.rgb * half(flashIntensity + innerFlash);

    return half4(color.rgb + flash, color.a);
}

// MARK: - Blade Extension Mask
// Used for the blade extending/retracting animation

[[stitchable]] half4 bladeExtension(
    float2 position,
    SwiftUI::Layer layer,
    float2 size,
    float2 hiltPosition,
    float extensionProgress,
    float bladeLength
) {
    half4 original = layer.sample(position);

    // Calculate distance from hilt along blade direction (assuming vertical blade, tip up)
    float distanceFromHilt = hiltPosition.y - position.y;

    // Current blade length based on extension progress
    float currentLength = extensionProgress * bladeLength;

    // Fade out beyond current extension
    if (distanceFromHilt > currentLength) {
        // Soft edge at the tip
        float tipFade = smoothstep(currentLength + 20.0, currentLength, distanceFromHilt);
        return original * half(tipFade);
    }

    return original;
}

// MARK: - Clash Spark Effect
// For when sabers clash

[[stitchable]] half4 clashSparks(
    float2 position,
    half4 color,
    float2 size,
    float2 clashPoint,
    float time,
    float intensity,
    half4 sparkColor
) {
    // Distance from clash point
    float2 delta = position - clashPoint;
    float dist = length(delta);

    // Angle for spark direction
    float angle = atan2(delta.y, delta.x);

    // Create multiple spark rays
    float sparkPattern = 0.0;
    for (int i = 0; i < 8; i++) {
        float sparkAngle = float(i) * M_PI_F / 4.0 + time * 2.0;
        float angleDiff = abs(fmod(angle - sparkAngle + M_PI_F, 2.0 * M_PI_F) - M_PI_F);
        float spark = smoothstep(0.3, 0.0, angleDiff) * smoothstep(100.0 * intensity, 0.0, dist);
        sparkPattern += spark;
    }

    // Add central flash
    float flash = smoothstep(50.0 * intensity, 0.0, dist) * (1.0 - time);

    half3 sparks = sparkColor.rgb * half((sparkPattern + flash) * intensity);

    return half4(color.rgb + sparks, color.a);
}

// MARK: - Humming Vibration Effect
// Subtle vibration that makes the blade feel alive

[[stitchable]] float2 hummingVibration(
    float2 position,
    float2 size,
    float time,
    float amplitude
) {
    // Very subtle, high-frequency vibration
    float vibration = sin(time * 120.0) * amplitude;

    // Add some variation based on position
    vibration += sin(time * 80.0 + position.y * 0.01) * amplitude * 0.5;

    return position + float2(vibration, 0.0);
}
