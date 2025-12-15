import SwiftUI

struct AuroraAnimationView: View {
    let spec: AnimationSpec

    @State private var isPaused = false
    @State private var colorCycleOffset: Int = 0

    var body: some View {
        GeometryReader { geometry in
            ZStack {
                // Background
                spec.canvas.swiftUIBackgroundColor
                    .ignoresSafeArea()

                // Glow effect
                if spec.glowEffect.enabled {
                    GlowView(spec: spec.glowEffect, size: geometry.size)
                }

                // Wave layers
                ForEach(spec.waves.filter { $0.enabled }) { wave in
                    if let palette = spec.colorPalettes[wave.palette] {
                        WaveLayer(
                            spec: wave,
                            colors: cycledColors(palette.swiftUIColors),
                            masterSpeed: isPaused ? 0 : spec.globalAnimation.masterSpeed
                        )
                    }
                }

                // Floating orbs
                if spec.orbs.enabled,
                   let orbPalette = spec.colorPalettes[spec.orbs.palette] {
                    OrbField(
                        spec: spec.orbs,
                        colors: cycledColors(orbPalette.swiftUIColors),
                        containerSize: geometry.size
                    )
                }

                // Pause indicator
                if isPaused {
                    Image(systemName: "pause.circle.fill")
                        .font(.system(size: 60))
                        .foregroundColor(.white.opacity(0.5))
                        .transition(.scale.combined(with: .opacity))
                }
            }
            .clipShape(RoundedRectangle(cornerRadius: spec.canvas.cornerRadius))
            .contentShape(Rectangle())
            .onTapGesture {
                if spec.interaction.tapToPause {
                    withAnimation(.easeInOut(duration: 0.3)) {
                        isPaused.toggle()
                    }
                    if spec.interaction.hapticFeedback {
                        let generator = UIImpactFeedbackGenerator(style: .light)
                        generator.impactOccurred()
                    }
                }
            }
        }
        .onAppear {
            if spec.globalAnimation.colorCycleEnabled {
                startColorCycle()
            }
        }
    }

    private func cycledColors(_ colors: [Color]) -> [Color] {
        guard !colors.isEmpty else { return colors }
        let offset = colorCycleOffset % colors.count
        return Array(colors[offset...]) + Array(colors[..<offset])
    }

    private func startColorCycle() {
        Timer.scheduledTimer(
            withTimeInterval: spec.globalAnimation.colorCycleDuration,
            repeats: true
        ) { _ in
            withAnimation(.easeInOut(duration: 2.0)) {
                colorCycleOffset += 1
            }
        }
    }
}

// MARK: - Glow View
struct GlowView: View {
    let spec: GlowEffectSpec
    let size: CGSize

    @State private var scale: CGFloat = 1.0
    @State private var isInitialized = false

    var body: some View {
        Circle()
            .fill(
                RadialGradient(
                    colors: [
                        spec.swiftUIColor.opacity(spec.opacity),
                        spec.swiftUIColor.opacity(spec.opacity * 0.5),
                        spec.swiftUIColor.opacity(0)
                    ],
                    center: .center,
                    startRadius: 0,
                    endRadius: spec.radius
                )
            )
            .frame(width: spec.radius * 2, height: spec.radius * 2)
            .scaleEffect(scale)
            .position(x: size.width / 2, y: size.height / 2)
            .onAppear {
                guard !isInitialized else { return }
                isInitialized = true
                scale = spec.pulseMin
                withAnimation(
                    .easeInOut(duration: spec.pulseDuration)
                    .repeatForever(autoreverses: true)
                ) {
                    scale = spec.pulseMax
                }
            }
    }
}
