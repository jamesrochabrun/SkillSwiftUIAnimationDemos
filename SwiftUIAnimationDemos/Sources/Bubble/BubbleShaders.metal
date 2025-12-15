//
//  BubbleShaders.metal
//  DemoView
//

#include <metal_stdlib>
#include <SwiftUI/SwiftUI_Metal.h>
using namespace metal;

// MARK: - Iridescent Shimmer (Animated rainbow surface)
[[stitchable]] half4 iridescentShimmer(
    float2 position,
    half4 color,
    float2 size,
    float time
) {
    // Skip transparent pixels
    if (color.a < 0.01) {
        return color;
    }

    float2 uv = position / size;

    // Create flowing iridescent pattern
    float angle = atan2(uv.y - 0.5, uv.x - 0.5);
    float dist = length(uv - float2(0.5, 0.5));

    // Animated wave pattern
    float wave = sin(angle * 3.0 + time * 2.0 + dist * 10.0) * 0.5 + 0.5;
    float wave2 = sin(angle * 5.0 - time * 1.5 + dist * 8.0) * 0.5 + 0.5;

    // Rainbow color based on angle and time
    float hue = fract(angle / 6.28318 + time * 0.1 + wave * 0.2);

    // HSV to RGB conversion
    float3 rgb;
    float h = hue * 6.0;
    float c = 0.6;
    float x = c * (1.0 - abs(fmod(h, 2.0) - 1.0));

    if (h < 1.0) rgb = float3(c, x, 0.0);
    else if (h < 2.0) rgb = float3(x, c, 0.0);
    else if (h < 3.0) rgb = float3(0.0, c, x);
    else if (h < 4.0) rgb = float3(0.0, x, c);
    else if (h < 5.0) rgb = float3(x, 0.0, c);
    else rgb = float3(c, 0.0, x);

    rgb += 0.4;

    // Mix iridescence with original color, stronger at edges
    float edgeFactor = smoothstep(0.2, 0.5, dist);
    float shimmerStrength = (wave * wave2) * edgeFactor * 0.35;

    half3 iridescent = half3(rgb.r, rgb.g, rgb.b);
    half3 result = mix(color.rgb, iridescent, half(shimmerStrength));

    return half4(result, color.a);
}

// MARK: - Liquid Distortion (Wobbly bubble effect)
[[stitchable]] float2 liquidDistortion(
    float2 position,
    float2 size,
    float time,
    float intensity
) {
    float2 uv = position / size;
    float2 center = float2(0.5, 0.5);
    float2 dir = uv - center;
    float dist = length(dir);

    // Only distort within the circle area
    if (dist > 0.48) {
        return position;
    }

    // Multiple wave frequencies for organic feel
    float wave1 = sin(dist * 20.0 - time * 3.0) * intensity;
    float wave2 = sin(dist * 15.0 + time * 2.0 + atan2(dir.y, dir.x) * 3.0) * intensity * 0.5;
    float wave3 = cos(dist * 25.0 - time * 4.0 + atan2(dir.y, dir.x) * 2.0) * intensity * 0.3;

    float totalWave = wave1 + wave2 + wave3;

    // Apply distortion radially, stronger toward center, fade at edges
    float edgeFade = smoothstep(0.48, 0.3, dist);
    float2 offset = dir * totalWave * edgeFade * 15.0;

    return position + offset;
}

// MARK: - Bubble Highlight (Animated specular)
[[stitchable]] half4 bubbleHighlight(
    float2 position,
    half4 color,
    float2 size,
    float time
) {
    // Skip transparent pixels
    if (color.a < 0.01) {
        return color;
    }

    float2 uv = position / size;

    // Animated light position
    float2 lightPos = float2(
        0.3 + sin(time * 0.5) * 0.08,
        0.3 + cos(time * 0.7) * 0.08
    );

    float lightDist = length(uv - lightPos);

    // Sharp specular highlight
    float specular = smoothstep(0.12, 0.0, lightDist);
    specular = pow(specular, 2.0);

    // Secondary softer highlight
    float2 lightPos2 = float2(0.65, 0.7);
    float lightDist2 = length(uv - lightPos2);
    float specular2 = smoothstep(0.25, 0.08, lightDist2) * 0.25;

    half totalSpecular = half(specular + specular2) * color.a;

    return half4(color.rgb + totalSpecular, color.a);
}
