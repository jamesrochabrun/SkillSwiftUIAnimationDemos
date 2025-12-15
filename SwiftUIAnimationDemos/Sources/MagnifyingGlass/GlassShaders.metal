//
//  GlassShaders.metal
//  DemoView
//
//  Refractive glass effect based on physical light simulation
//

#include <metal_stdlib>
#include <SwiftUI/SwiftUI_Metal.h>
using namespace metal;

// Helper: Signed distance function for a capsule/pill shape
float sdCapsule(float2 p, float2 size) {
    float radius = size.y * 0.5;
    float halfWidth = size.x * 0.5 - radius;
    p.x = abs(p.x) - halfWidth;
    p.x = max(p.x, 0.0);
    return length(p) - radius;
}

// MARK: - Circular Magnifying Glass Effect
// Based on physical glass simulation: refraction, shadows, edge lighting, chromatic aberration

[[stitchable]] half4 magnifyingGlass(
    float2 position,
    SwiftUI::Layer layer,
    float2 size,
    float2 glassCenter,       // Normalized (0-1) position of glass center
    float glassRadius,        // Normalized radius (0-1)
    float refractionStrength, // How much the glass bends light
    float shadowOffset,       // Shadow offset for depth
    float shadowBlur,         // Shadow blur radius
    float edgeThickness,      // Rim light thickness
    float chromaticAmount     // Chromatic aberration intensity
) {
    // Work in normalized UV space (0-1) with aspect ratio correction
    float2 uv = position / size;
    float2 toCenter = uv - glassCenter;

    // Correct for aspect ratio so circle doesn't become oval
    float aspectRatio = size.x / size.y;
    float2 toCenterCorrected = float2(toCenter.x * aspectRatio, toCenter.y);
    float dist = length(toCenterCorrected);
    float normalizedDist = dist / glassRadius;

    // Default: sample original background
    half4 originalColor = layer.sample(position);

    // --- SHADOW & OCCLUSION ---
    float2 shadowCenter = glassCenter + float2(shadowOffset, shadowOffset);
    float2 toShadowCenter = uv - shadowCenter;
    float2 toShadowCorrected = float2(toShadowCenter.x * aspectRatio, toShadowCenter.y);
    float shadowDist = length(toShadowCorrected);
    float shadowRadiusNorm = glassRadius + shadowBlur;

    bool insideGlass = (normalizedDist <= 1.0);
    bool insideShadow = (shadowDist < shadowRadiusNorm && shadowDist > glassRadius);

    // Apply shadow outside glass but within shadow radius
    if (!insideGlass && insideShadow) {
        float shadowFalloff = (shadowDist - glassRadius) / shadowBlur;
        float shadowStrength = smoothstep(1.0, 0.0, shadowFalloff);
        originalColor.rgb = mix(originalColor.rgb, half3(0.0), shadowStrength * 0.2);
    }

    // Outside the glass: return (potentially shadowed) original
    if (!insideGlass) {
        return originalColor;
    }

    // --- REFRACTION ---
    // Parabolic falloff: 1 - r² gives strongest distortion at center
    float distortion = 1.0 - normalizedDist * normalizedDist;

    // Convert glass center and current position to find direction vector
    float2 centerPx = glassCenter * size;
    float2 toCenterPx = centerPx - position;  // Points TOWARD center
    float distPx = length(toCenterPx);
    float radiusPx = glassRadius * min(size.x, size.y);

    // Scale the offset - positive values pull toward center (magnify)
    float offsetStrength = distortion * refractionStrength * radiusPx;
    float2 offset = normalize(toCenterPx + 0.001) * offsetStrength;

    // --- CHROMATIC ABERRATION ---
    float chromaticStrength = normalizedDist * chromaticAmount;

    // Sample positions - ADD offset to pull samples toward center
    float2 redSamplePos = position + offset * (1.0 + chromaticStrength);
    float2 greenSamplePos = position + offset;
    float2 blueSamplePos = position + offset * (1.0 - chromaticStrength);

    half4 redSample = layer.sample(redSamplePos);
    half4 greenSample = layer.sample(greenSamplePos);
    half4 blueSample = layer.sample(blueSamplePos);

    half4 refractedColor;
    refractedColor.r = redSample.r;
    refractedColor.g = greenSample.g;
    refractedColor.b = blueSample.b;
    refractedColor.a = 1.0;

    // --- EDGE LIGHTING / RIM HIGHLIGHT ---
    float edgeDistance = abs(normalizedDist - 1.0) * glassRadius;
    float edgeFade = smoothstep(edgeThickness, 0.0, edgeDistance);

    // Directional light from upper-left (use corrected vector for proper circle highlight)
    float2 lightDir = normalize(float2(-0.5, -0.8));
    float rimBias = dot(normalize(toCenterCorrected), lightDir);
    rimBias = clamp(rimBias, 0.0, 1.0);

    // Cool-toned highlight for glass feel
    half3 highlightColor = half3(1.1, 1.15, 1.25);
    refractedColor.rgb += edgeFade * rimBias * highlightColor * 0.8;

    // Secondary subtle rim on opposite side
    float rimBias2 = dot(normalize(toCenterCorrected), -lightDir);
    rimBias2 = clamp(rimBias2, 0.0, 1.0);
    refractedColor.rgb += edgeFade * rimBias2 * half3(0.7, 0.75, 0.85) * 0.25;

    // --- SUBTLE GLASS TINT ---
    half3 glassTint = half3(0.98, 0.99, 1.02);
    refractedColor.rgb *= glassTint;

    // Center brightness boost (lens effect)
    float centerBrightness = (1.0 - normalizedDist) * 0.02;
    refractedColor.rgb += centerBrightness;

    return refractedColor;
}

// MARK: - Visualization Shader (for debugging distortion)
[[stitchable]] half4 refractionVisual(
    float2 position,
    SwiftUI::Layer layer,
    float2 size,
    float2 glassCenter,
    float glassRadius,
    float refraction
) {
    float2 uv = position / size;
    float2 toCenter = uv - glassCenter;
    float dist = length(toCenter);
    float normalizedDist = dist / glassRadius;

    // Default to background layer
    half4 originalColor = layer.sample(position);

    // Outside the glass: return original
    if (normalizedDist > 1.0) {
        return originalColor;
    }

    // Compute distortion strength - parabolic falloff
    float distortion = 1.0 - normalizedDist * normalizedDist * refraction;

    // Visualize it: brighter = more distortion
    return half4(distortion, distortion, distortion, 1.0);
}

// MARK: - Animated Liquid Glass Effect
[[stitchable]] half4 liquidGlass(
    float2 position,
    SwiftUI::Layer layer,
    float2 size,
    float2 glassCenter,
    float glassRadius,
    float time,
    float refractionStrength
) {
    // Work in normalized UV space with aspect ratio correction
    float2 uv = position / size;
    float2 toCenter = uv - glassCenter;

    // Correct for aspect ratio
    float aspectRatio = size.x / size.y;
    float2 toCenterCorrected = float2(toCenter.x * aspectRatio, toCenter.y);
    float dist = length(toCenterCorrected);
    float normalizedDist = dist / glassRadius;

    half4 originalColor = layer.sample(position);

    // Shadow with animated offset
    float shadowWobble = sin(time * 1.5) * 0.005;
    float2 shadowCenter = glassCenter + float2(0.02 + shadowWobble, 0.03 + shadowWobble);
    float2 toShadowCorrected = float2((uv.x - shadowCenter.x) * aspectRatio, uv.y - shadowCenter.y);
    float shadowDist = length(toShadowCorrected);
    float shadowRadiusNorm = glassRadius + 0.05;

    if (normalizedDist > 1.0) {
        if (shadowDist < shadowRadiusNorm && shadowDist > glassRadius) {
            float shadowFalloff = (shadowDist - glassRadius) / 0.05;
            float shadowStrength = smoothstep(1.0, 0.0, shadowFalloff);
            originalColor.rgb = mix(originalColor.rgb, half3(0.0), shadowStrength * 0.15);
        }
        return originalColor;
    }

    // Animated distortion with liquid wobble
    float wobble = sin(time * 2.0 + normalizedDist * 6.28) * 0.15;
    float distortion = 1.0 - pow(normalizedDist, 2.0 + wobble);

    // Simple offset in UV space
    float2 offset = toCenter * distortion * refractionStrength;

    // Animated chromatic aberration
    float chromaticStrength = normalizedDist * (0.08 + sin(time) * 0.02);

    float2 redOffset = offset * (1.0 + chromaticStrength);
    float2 greenOffset = offset;
    float2 blueOffset = offset * (1.0 - chromaticStrength);

    // Sample with offsets converted to pixel space
    half4 refractedColor;
    refractedColor.r = layer.sample(position + redOffset * size).r;
    refractedColor.g = layer.sample(position + greenOffset * size).g;
    refractedColor.b = layer.sample(position + blueOffset * size).b;
    refractedColor.a = 1.0;

    // Animated rim lighting
    float edgeFade = smoothstep(0.015, 0.0, abs(normalizedDist - 1.0) * glassRadius);
    float lightAngle = time * 0.5;
    float2 lightDir = normalize(float2(-0.5 + sin(lightAngle) * 0.3, -0.8 + cos(lightAngle) * 0.2));
    float rimBias = clamp(dot(normalize(toCenterCorrected), lightDir), 0.0, 1.0);

    half3 rimColor = half3(1.2, 1.25, 1.4);
    refractedColor.rgb += edgeFade * rimBias * rimColor * 0.7;

    // Secondary rim
    float rimBias2 = clamp(dot(normalize(toCenterCorrected), -lightDir), 0.0, 1.0);
    refractedColor.rgb += edgeFade * rimBias2 * half3(0.7, 0.75, 0.85) * 0.2;

    // Glass tint
    refractedColor.rgb *= half3(0.97, 0.98, 1.02);
    refractedColor.rgb += (1.0 - normalizedDist) * 0.02;

    return refractedColor;
}

// MARK: - Refractive Glass Capsule Effect
[[stitchable]] half4 glassRefraction(
    float2 position,
    SwiftUI::Layer layer,
    float2 size,
    float refractionStrength,
    float edgeThickness,
    float shadowOffset,
    float shadowBlur
) {
    float2 uv = position / size;
    float2 center = float2(0.5, 0.5);
    float2 toCenter = uv - center;

    // Capsule SDF in UV space
    float2 capsuleSize = float2(1.0, 1.0); // normalized
    float dist = sdCapsule(toCenter, capsuleSize);

    // Normalize distance (0 at center, 1 at edge)
    float glassRadius = 0.0; // edge of capsule
    float innerRadius = -0.4; // deep inside
    float normalizedDist = smoothstep(innerRadius, glassRadius, dist);

    // Sample original
    half4 originalColor = layer.sample(position);

    // Outside the glass shape
    if (dist > 0.0) {
        // Shadow region
        float2 shadowCenter = center + float2(shadowOffset, shadowOffset);
        float shadowDist = sdCapsule(uv - shadowCenter, capsuleSize);

        if (shadowDist < shadowBlur && shadowDist > 0.0) {
            float shadowFalloff = shadowDist / shadowBlur;
            float shadowStrength = smoothstep(1.0, 0.0, shadowFalloff);
            originalColor.rgb = mix(originalColor.rgb, half3(0.0), shadowStrength * 0.3);
        }
        return originalColor;
    }

    // Inside the glass - apply refraction
    // Parabolic falloff: stronger at center, weaker at edges
    float distortion = 1.0 - normalizedDist * normalizedDist;
    float2 offset = toCenter * distortion * refractionStrength;

    // Chromatic aberration - increases toward edges
    float chromaticStrength = normalizedDist * 0.015;
    float2 redOffset = offset * (1.0 + chromaticStrength);
    float2 greenOffset = offset;
    float2 blueOffset = offset * (1.0 - chromaticStrength);

    // Sample each channel with different offsets
    half4 redSample = layer.sample(position + redOffset * size);
    half4 greenSample = layer.sample(position + greenOffset * size);
    half4 blueSample = layer.sample(position + blueOffset * size);

    half4 refractedColor;
    refractedColor.r = redSample.r;
    refractedColor.g = greenSample.g;
    refractedColor.b = blueSample.b;
    refractedColor.a = 1.0;

    // Edge lighting / rim highlight
    float edgeDist = abs(dist);
    float edgeFade = smoothstep(edgeThickness, 0.0, edgeDist);

    // Directional light from upper-left
    float2 lightDir = normalize(float2(-0.5, -0.8));
    float rimBias = dot(normalize(toCenter), lightDir);
    rimBias = clamp(rimBias, 0.0, 1.0);

    // Cool-toned highlight
    half3 highlightColor = half3(1.2, 1.25, 1.35);
    refractedColor.rgb += edgeFade * rimBias * highlightColor * 0.8;

    // Subtle inner glow/tint
    half3 glassTint = half3(0.95, 0.97, 1.0); // slight cool tint
    refractedColor.rgb *= glassTint;

    // Add subtle brightness in center (lens effect)
    float centerBrightness = (1.0 - normalizedDist) * 0.05;
    refractedColor.rgb += centerBrightness;

    return refractedColor;
}

// MARK: - Glass Capsule with Background Blur Simulation
[[stitchable]] half4 glassButton(
    float2 position,
    SwiftUI::Layer layer,
    float2 size,
    float time
) {
    float2 uv = position / size;
    float2 center = float2(0.5, 0.5);
    float2 toCenter = uv - center;

    // Capsule shape
    float2 capsuleSize = float2(1.0, 1.0);
    float dist = sdCapsule(toCenter, capsuleSize);

    half4 originalColor = layer.sample(position);

    // Outside glass
    if (dist > 0.0) {
        // Soft shadow
        float shadowDist = sdCapsule(toCenter - float2(0.02, 0.03), capsuleSize);
        if (shadowDist < 0.08 && shadowDist > 0.0) {
            float shadowStrength = smoothstep(0.08, 0.0, shadowDist);
            originalColor.rgb = mix(originalColor.rgb, half3(0.0), shadowStrength * 0.25);
        }
        return originalColor;
    }

    // Normalized distance inside capsule
    float innerRadius = -0.35;
    float normalizedDist = smoothstep(innerRadius, 0.0, dist);

    // Refraction with parabolic falloff
    float distortion = 1.0 - normalizedDist * normalizedDist;
    float refractionStrength = 0.06;
    float2 offset = toCenter * distortion * refractionStrength;

    // Chromatic aberration
    float chromaticStrength = normalizedDist * 0.02;

    half4 redSample = layer.sample(position + offset * size * (1.0 + chromaticStrength));
    half4 greenSample = layer.sample(position + offset * size);
    half4 blueSample = layer.sample(position + offset * size * (1.0 - chromaticStrength));

    half4 result;
    result.r = redSample.r;
    result.g = greenSample.g;
    result.b = blueSample.b;
    result.a = 1.0;

    // Rim/edge lighting
    float edgeFade = smoothstep(0.02, 0.0, abs(dist));

    // Animated light direction
    float lightAngle = time * 0.3;
    float2 lightDir = normalize(float2(-0.5 + sin(lightAngle) * 0.2, -0.8 + cos(lightAngle) * 0.1));
    float rimBias = dot(normalize(toCenter), lightDir);
    rimBias = clamp(rimBias * 1.5, 0.0, 1.0);

    half3 rimColor = half3(1.3, 1.35, 1.5);
    result.rgb += edgeFade * rimBias * rimColor * 0.6;

    // Secondary rim on opposite side (subtle)
    float rimBias2 = dot(normalize(toCenter), -lightDir);
    rimBias2 = clamp(rimBias2, 0.0, 1.0);
    result.rgb += edgeFade * rimBias2 * half3(0.8, 0.85, 1.0) * 0.2;

    // Glass tint and inner glow
    result.rgb *= half3(0.97, 0.98, 1.02);
    result.rgb += (1.0 - normalizedDist) * 0.03;

    // Specular highlight (top-left)
    float2 specPos = float2(-0.25, -0.3);
    float specDist = length(toCenter - specPos);
    float specular = smoothstep(0.15, 0.0, specDist);
    result.rgb += specular * half3(1.0, 1.0, 1.0) * 0.15;

    return result;
}
