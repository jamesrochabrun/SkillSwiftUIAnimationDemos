//
//  HologramShaders.metal
//  DemoView
//
//  Pokemon-style diamond holographic card effect with motion-reactive iridescence
//

#include <metal_stdlib>
#include <SwiftUI/SwiftUI_Metal.h>
using namespace metal;

// MARK: - Helper Functions (prefixed to avoid linker conflicts)

// Convert HSV to RGB for rainbow effects
static half3 holo_hsv2rgb(half3 c) {
    half4 K = half4(1.0h, 2.0h / 3.0h, 1.0h / 3.0h, 3.0h);
    half3 p = abs(fract(c.xxx + K.xyz) * 6.0h - K.www);
    return c.z * mix(K.xxx, clamp(p - K.xxx, 0.0h, 1.0h), c.y);
}

// Pseudo-random noise for sparkles
static float holo_hash(float2 p) {
    return fract(sin(dot(p, float2(127.1, 311.7))) * 43758.5453);
}

// MARK: - Diamond Holo Pattern (Pokemon Style)

[[stitchable]] half4 holographicCard(
    float2 position,
    SwiftUI::Layer layer,
    float2 size,
    float2 tilt,          // Device tilt (pitch, roll) from motion sensors
    float time,           // Animated time for sparkles
    float intensity       // Overall effect intensity (0-1)
) {
    float2 uv = position / size;
    half4 originalColor = layer.sample(position);

    if (originalColor.a < 0.01h) {
        return originalColor;
    }

    // --- DIAMOND GRID PATTERN ---
    // Create the classic Pokemon holo diamond/rhombus pattern
    // Diamonds are vertically elongated (taller than wide)

    float diamondWidth = 24.0;   // Horizontal density
    float diamondHeight = 40.0;  // Vertical density (taller = more elongated)

    // Transform to diamond space - elongated vertically
    float2 diamondUV = float2(
        uv.x * diamondWidth,
        uv.y * diamondHeight
    );

    // Offset every other row to create diamond pattern
    float row = floor(diamondUV.y);
    if (fmod(row, 2.0) == 1.0) {
        diamondUV.x += 0.5;
    }

    // Get diamond cell coordinates
    float2 diamondCell = floor(diamondUV);
    float2 diamondLocal = fract(diamondUV) - 0.5;  // -0.5 to 0.5 within cell

    // Distance to diamond edge (diamond shape with vertical stretch)
    float diamondDist = abs(diamondLocal.x) * 2.0 + abs(diamondLocal.y);

    // Diamond edge highlight
    float diamondEdge = smoothstep(0.5, 0.35, diamondDist);
    float diamondRim = smoothstep(0.5, 0.45, diamondDist) - smoothstep(0.45, 0.35, diamondDist);

    // --- RAINBOW COLOR PER DIAMOND ---
    // Each diamond gets a rainbow color based on position + tilt

    // Tilt shifts which diamonds are which color
    float2 tiltOffset = tilt * 3.0;
    float hueBase = (diamondCell.x + diamondCell.y) * 0.08;
    float hueTilt = (tiltOffset.x + tiltOffset.y) * 0.15;
    float hue = fract(hueBase + hueTilt);

    // Create vibrant rainbow colors
    half3 diamondColor = holo_hsv2rgb(half3(hue, 0.85h, 1.0h));

    // --- LIGHT REFLECTION / HOTSPOT ---
    // Simulate light moving across the card based on tilt

    float2 lightPos = float2(0.5 + tilt.y * 0.8, 0.5 + tilt.x * 0.8);
    float lightDist = length(uv - lightPos);
    float hotspot = smoothstep(0.6, 0.0, lightDist);
    hotspot = pow(hotspot, 1.5);

    // Secondary light
    float2 lightPos2 = float2(0.5 - tilt.y * 0.5, 0.5 - tilt.x * 0.5);
    float hotspot2 = smoothstep(0.4, 0.0, length(uv - lightPos2)) * 0.5;

    // --- SPARKLE ON INDIVIDUAL DIAMONDS ---
    // Random diamonds sparkle based on tilt angle

    float sparkleRand = holo_hash(diamondCell);
    float sparklePhase = sparkleRand * 6.28 + (tilt.x + tilt.y) * 8.0 + time * 2.0;
    float sparkle = pow(max(0.0, sin(sparklePhase)), 8.0);

    // Only some diamonds sparkle
    sparkle *= step(0.7, sparkleRand);

    // Sparkle is brightest in center of diamond
    sparkle *= diamondEdge;

    // --- COMBINE EFFECTS ---

    // Base: blend original with diamond rainbow color
    half holoStrength = half(intensity * diamondEdge * (0.5 + hotspot * 0.5));
    half3 result = mix(originalColor.rgb, diamondColor, holoStrength);

    // Add brightness variation per diamond based on light position
    float diamondBrightness = hotspot * 0.4 + hotspot2 * 0.2;
    result += half(diamondBrightness * diamondEdge) * diamondColor;

    // Add rim highlights on diamond edges
    result += half(diamondRim * 0.3 * (hotspot + 0.2)) * half3(1.0h, 1.0h, 1.0h);

    // Add sparkles
    result += half(sparkle * 1.2) * half3(1.0h, 1.0h, 1.0h);

    // Overall brightness boost in lit areas
    result *= half(1.0 + hotspot * 0.2);

    return half4(result, originalColor.a);
}

// MARK: - Cosmos Holo (Denser Smaller Diamonds)

[[stitchable]] half4 holographicSimple(
    float2 position,
    SwiftUI::Layer layer,
    float2 size,
    float2 tilt,
    float time
) {
    float2 uv = position / size;
    half4 originalColor = layer.sample(position);

    if (originalColor.a < 0.01h) {
        return originalColor;
    }

    // Smaller, denser vertical diamond pattern
    float diamondWidth = 30.0;
    float diamondHeight = 50.0;

    float2 diamondUV = float2(
        uv.x * diamondWidth,
        uv.y * diamondHeight
    );

    float row = floor(diamondUV.y);
    if (fmod(row, 2.0) == 1.0) {
        diamondUV.x += 0.5;
    }

    float2 diamondCell = floor(diamondUV);
    float2 diamondLocal = fract(diamondUV) - 0.5;
    float diamondDist = abs(diamondLocal.x) * 2.0 + abs(diamondLocal.y);
    float diamondEdge = smoothstep(0.5, 0.3, diamondDist);

    // Rainbow per diamond
    float hue = fract((diamondCell.x + diamondCell.y) * 0.05 + (tilt.x + tilt.y) * 0.2);
    half3 diamondColor = holo_hsv2rgb(half3(hue, 0.8h, 1.0h));

    // Light hotspot
    float2 lightPos = float2(0.5 + tilt.y * 0.7, 0.5 + tilt.x * 0.7);
    float hotspot = pow(smoothstep(0.5, 0.0, length(uv - lightPos)), 1.5);

    // Combine
    half3 result = mix(originalColor.rgb, diamondColor, half(diamondEdge * 0.6));
    result += half(hotspot * diamondEdge * 0.4) * diamondColor;
    result *= half(1.0 + hotspot * 0.15);

    return half4(result, originalColor.a);
}

// MARK: - Secret Rare Holo (Maximum Bling with Dense Diamond Pattern)

[[stitchable]] half4 holographicIntense(
    float2 position,
    SwiftUI::Layer layer,
    float2 size,
    float2 tilt,
    float time
) {
    float2 uv = position / size;
    half4 originalColor = layer.sample(position);

    if (originalColor.a < 0.01h) {
        return originalColor;
    }

    // --- DENSE VERTICAL DIAMOND GRID ---
    float diamondWidth = 28.0;
    float diamondHeight = 48.0;

    float2 diamondUV = float2(
        uv.x * diamondWidth,
        uv.y * diamondHeight
    );

    float row = floor(diamondUV.y);
    if (fmod(row, 2.0) == 1.0) {
        diamondUV.x += 0.5;
    }

    float2 diamondCell = floor(diamondUV);
    float2 diamondLocal = fract(diamondUV) - 0.5;
    float diamondDist = abs(diamondLocal.x) * 2.0 + abs(diamondLocal.y);

    float diamondEdge = smoothstep(0.5, 0.25, diamondDist);
    float diamondRim = smoothstep(0.5, 0.4, diamondDist) - smoothstep(0.4, 0.3, diamondDist);

    // --- MULTI-HUE RAINBOW ---
    float2 tiltOffset = tilt * 4.0;
    float hue1 = fract((diamondCell.x + diamondCell.y) * 0.06 + tiltOffset.x * 0.12);
    float hue2 = fract((diamondCell.x - diamondCell.y) * 0.04 + tiltOffset.y * 0.1);
    float hue = fract((hue1 + hue2) * 0.5 + time * 0.01);

    half3 diamondColor = holo_hsv2rgb(half3(hue, 0.9h, 1.0h));

    // Secondary color layer
    float hue3 = fract(hue + 0.33);
    half3 diamondColor2 = holo_hsv2rgb(half3(hue3, 0.7h, 0.9h));

    // --- MULTIPLE LIGHT SOURCES ---
    float2 light1 = float2(0.5 + tilt.y * 0.9, 0.5 + tilt.x * 0.9);
    float2 light2 = float2(0.5 - tilt.y * 0.6, 0.5 - tilt.x * 0.6);
    float2 light3 = float2(0.5 + tilt.x * 0.5, 0.5 - tilt.y * 0.5);

    float hot1 = pow(smoothstep(0.5, 0.0, length(uv - light1)), 1.8);
    float hot2 = pow(smoothstep(0.4, 0.0, length(uv - light2)), 2.0) * 0.6;
    float hot3 = pow(smoothstep(0.35, 0.0, length(uv - light3)), 2.0) * 0.4;
    float totalHot = hot1 + hot2 + hot3;

    // --- INTENSE SPARKLES ---
    float sparkleRand = holo_hash(diamondCell);
    float sparklePhase = sparkleRand * 6.28 + (tilt.x + tilt.y) * 12.0 + time * 3.0;
    float sparkle = pow(max(0.0, sin(sparklePhase)), 6.0);
    sparkle *= step(0.5, sparkleRand);  // More sparkles
    sparkle *= diamondEdge;

    // Extra bright sparkles on some diamonds
    float megaSparkle = pow(max(0.0, sin(sparklePhase * 0.5)), 12.0);
    megaSparkle *= step(0.85, sparkleRand);
    megaSparkle *= diamondEdge;

    // --- COMBINE ALL EFFECTS ---

    // Strong blend with diamond colors
    half holoStrength = half(diamondEdge * (0.7 + totalHot * 0.3));
    half3 result = mix(originalColor.rgb, diamondColor, holoStrength);

    // Add secondary color in lit areas
    result = mix(result, diamondColor2, half(totalHot * diamondEdge * 0.3));

    // Bright diamond highlights
    result += half(totalHot * diamondEdge * 0.5) * diamondColor;

    // Diamond rim glow
    result += half(diamondRim * 0.5 * (totalHot + 0.3)) * half3(1.0h, 1.0h, 1.0h);

    // Sparkles
    result += half(sparkle * 1.5) * half3(1.0h, 1.0h, 1.0h);
    result += half(megaSparkle * 2.5) * half3(1.0h, 0.95h, 0.9h);

    // Overall brightness
    result *= half(1.0 + totalHot * 0.25);

    return half4(result, originalColor.a);
}
