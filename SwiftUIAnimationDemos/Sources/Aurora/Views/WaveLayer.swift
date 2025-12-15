import SwiftUI

struct WaveLayer: View {
    let spec: WaveSpec
    let colors: [Color]
    let masterSpeed: Double

    var body: some View {
        TimelineView(.animation) { timeline in
            Canvas { context, size in
                let time = timeline.date.timeIntervalSinceReferenceDate * masterSpeed

                // Calculate animated values
                let animatedPhase = spec.phase + CGFloat(time) * spec.animation.phaseSpeed
                let amplitudeOffset = sin(CGFloat(time) * spec.animation.amplitudeSpeed) * spec.animation.amplitudeVariation
                let currentAmplitude = spec.amplitude + amplitudeOffset

                // Create the wave path
                let path = createWavePath(
                    in: size,
                    amplitude: currentAmplitude,
                    frequency: spec.frequency,
                    phase: animatedPhase,
                    verticalOffset: spec.verticalOffset
                )

                // Create gradient
                let gradient = Gradient(colors: colors)
                let startPoint = CGPoint(x: 0, y: size.height * spec.verticalOffset)
                let endPoint = CGPoint(x: size.width, y: size.height * spec.verticalOffset)

                // Fill the wave with gradient
                context.fill(
                    path,
                    with: .linearGradient(
                        gradient,
                        startPoint: startPoint,
                        endPoint: endPoint
                    )
                )
            }
        }
        .blur(radius: spec.blur)
        .opacity(spec.opacity)
        .blendMode(spec.swiftUIBlendMode)
    }

    private func createWavePath(
        in size: CGSize,
        amplitude: CGFloat,
        frequency: CGFloat,
        phase: CGFloat,
        verticalOffset: CGFloat
    ) -> Path {
        Path { path in
            let midY = size.height * verticalOffset
            let wavelength = size.width / frequency

            // Start at bottom-left
            path.move(to: CGPoint(x: 0, y: size.height))

            // Line up to the wave start
            let startY = midY + sin(phase) * amplitude
            path.addLine(to: CGPoint(x: 0, y: startY))

            // Draw the wave using small line segments
            let step: CGFloat = 2
            for x in stride(from: 0, through: size.width, by: step) {
                let relativeX = x / wavelength
                let y = midY + sin(relativeX * .pi * 2 + phase) * amplitude
                path.addLine(to: CGPoint(x: x, y: y))
            }

            // Close the path at bottom-right and back to start
            path.addLine(to: CGPoint(x: size.width, y: size.height))
            path.closeSubpath()
        }
    }
}
