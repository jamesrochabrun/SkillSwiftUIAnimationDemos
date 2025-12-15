import SwiftUI

// MARK: - Root Specification
struct AnimationSpec: Codable {
    let metadata: Metadata
    let canvas: CanvasSpec
    let colorPalettes: [String: ColorPalette]
    let waves: [WaveSpec]
    let orbs: OrbsSpec
    let glowEffect: GlowEffectSpec
    let globalAnimation: GlobalAnimationSpec
    let interaction: InteractionSpec
}

// MARK: - Metadata
struct Metadata: Codable {
    let name: String
    let version: String
    let author: String
}

// MARK: - Canvas
struct CanvasSpec: Codable {
    let backgroundColor: String
    let cornerRadius: CGFloat

    var swiftUIBackgroundColor: Color {
        Color(hex: backgroundColor)
    }
}

// MARK: - Color Palette
struct ColorPalette: Codable {
    let colors: [String]
    let transitionDuration: Double
    let transitionStyle: String

    var swiftUIColors: [Color] {
        colors.map { Color(hex: $0) }
    }

    var animation: Animation {
        switch transitionStyle {
        case "easeIn": return .easeIn(duration: transitionDuration)
        case "easeOut": return .easeOut(duration: transitionDuration)
        case "linear": return .linear(duration: transitionDuration)
        default: return .easeInOut(duration: transitionDuration)
        }
    }
}

// MARK: - Wave Specification
struct WaveSpec: Codable, Identifiable {
    let id: String
    let enabled: Bool
    let palette: String
    let opacity: Double
    let blendMode: String
    let amplitude: CGFloat
    let frequency: CGFloat
    let phase: CGFloat
    let speed: CGFloat
    let verticalOffset: CGFloat
    let blur: CGFloat
    let animation: WaveAnimationSpec

    var swiftUIBlendMode: BlendMode {
        switch blendMode {
        case "plusLighter": return .plusLighter
        case "screen": return .screen
        case "overlay": return .overlay
        case "softLight": return .softLight
        case "hardLight": return .hardLight
        case "colorDodge": return .colorDodge
        case "multiply": return .multiply
        default: return .normal
        }
    }
}

struct WaveAnimationSpec: Codable {
    let phaseSpeed: Double
    let amplitudeVariation: CGFloat
    let amplitudeSpeed: Double
}

// MARK: - Orbs Specification
struct OrbsSpec: Codable {
    let enabled: Bool
    let count: Int
    let sizeRange: RangeSpec
    let opacityRange: RangeSpec
    let blur: CGFloat
    let palette: String
    let animation: OrbAnimationSpec
}

struct RangeSpec: Codable {
    let min: CGFloat
    let max: CGFloat

    func random() -> CGFloat {
        CGFloat.random(in: min...max)
    }
}

struct OrbAnimationSpec: Codable {
    let driftSpeed: RangeSpec
    let pulseScale: CGFloat
    let pulseDuration: Double
}

// MARK: - Glow Effect
struct GlowEffectSpec: Codable {
    let enabled: Bool
    let color: String
    let opacity: Double
    let radius: CGFloat
    let pulseMin: CGFloat
    let pulseMax: CGFloat
    let pulseDuration: Double

    var swiftUIColor: Color {
        Color(hex: color)
    }
}

// MARK: - Global Animation
struct GlobalAnimationSpec: Codable {
    let autoStart: Bool
    let looping: Bool
    let masterSpeed: Double
    let colorCycleEnabled: Bool
    let colorCycleDuration: Double
}

// MARK: - Interaction
struct InteractionSpec: Codable {
    let tapToPause: Bool
    let dragToDistort: Bool
    let hapticFeedback: Bool
}
