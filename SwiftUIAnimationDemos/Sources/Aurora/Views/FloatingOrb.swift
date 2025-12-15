import SwiftUI

struct FloatingOrb: View {
    let color: Color
    let size: CGFloat
    let blur: CGFloat
    let opacity: Double
    let pulseScale: CGFloat
    let pulseDuration: Double
    let driftDuration: Double
    let containerSize: CGSize

    @State private var position: CGPoint = .zero
    @State private var scale: CGFloat = 1.0
    @State private var isInitialized = false

    var body: some View {
        Circle()
            .fill(
                RadialGradient(
                    colors: [color, color.opacity(0.5), color.opacity(0)],
                    center: .center,
                    startRadius: 0,
                    endRadius: size / 2
                )
            )
            .frame(width: size, height: size)
            .blur(radius: blur)
            .scaleEffect(scale)
            .opacity(opacity)
            .position(position)
            .onAppear {
                guard !isInitialized else { return }
                isInitialized = true
                position = randomPosition()
                startAnimations()
            }
    }

    private func randomPosition() -> CGPoint {
        CGPoint(
            x: CGFloat.random(in: size...(containerSize.width - size)),
            y: CGFloat.random(in: size...(containerSize.height - size))
        )
    }

    private func startAnimations() {
        // Pulse animation
        withAnimation(
            .easeInOut(duration: pulseDuration)
            .repeatForever(autoreverses: true)
        ) {
            scale = pulseScale
        }

        // Start drift animation
        driftToNewPosition()
    }

    private func driftToNewPosition() {
        withAnimation(.easeInOut(duration: driftDuration)) {
            position = randomPosition()
        }

        // Schedule next drift
        DispatchQueue.main.asyncAfter(deadline: .now() + driftDuration) {
            driftToNewPosition()
        }
    }
}

struct OrbField: View {
    let spec: OrbsSpec
    let colors: [Color]
    let containerSize: CGSize

    var body: some View {
        ZStack {
            ForEach(0..<spec.count, id: \.self) { index in
                FloatingOrb(
                    color: colors[index % colors.count],
                    size: spec.sizeRange.random(),
                    blur: spec.blur,
                    opacity: spec.opacityRange.random(),
                    pulseScale: spec.animation.pulseScale,
                    pulseDuration: spec.animation.pulseDuration + Double.random(in: -0.5...0.5),
                    driftDuration: spec.animation.driftSpeed.random(),
                    containerSize: containerSize
                )
            }
        }
    }
}
