//
//  MaxiFyGlass.swift
//  DemoView
//
//  Refractive glass magnifying effect with SwiftUI + Metal shaders
//

import SwiftUI
import Combine

// MARK: - Magnifying Glass View

/// A view that applies a draggable refractive glass effect using .visualEffect
struct MagnifyingGlassOverlay: View {
    @Binding var position: CGPoint
    var diameter: CGFloat = 180
    var refractionStrength: Float = 0.08
    var shadowOffset: Float = 0.02
    var shadowBlur: Float = 0.06
    var edgeThickness: Float = 0.015
    var chromaticAmount: Float = 0.1
    var animated: Bool = false

    @State private var animationTime: Float = 0
    @GestureState private var dragOffset: CGSize = .zero

    private let timer = Timer.publish(every: 1/60, on: .main, in: .common).autoconnect()

    var body: some View {
        let currentPosition = CGPoint(
            x: position.x + dragOffset.width,
            y: position.y + dragOffset.height
        )

        Color.clear
            .contentShape(Rectangle())
            .gesture(
                DragGesture()
                    .updating($dragOffset) { value, state, _ in
                        state = value.translation
                    }
                    .onEnded { value in
                        position.x += value.translation.width
                        position.y += value.translation.height
                    }
            )
            .onReceive(timer) { _ in
                if animated {
                    animationTime += 1/60
                }
            }
            .allowsHitTesting(true)
    }
}

extension View {
    /// Adds a magnifying glass effect to the view
    /// IMPORTANT: The glass effect samples from a flattened layer, so .drawingGroup() is applied
    func magnifyingGlass(
        at position: CGPoint,
        diameter: CGFloat = 180,
        refractionStrength: Float = 0.08,
        shadowOffset: Float = 0.02,
        shadowBlur: Float = 0.06,
        edgeThickness: Float = 0.015,
        chromaticAmount: Float = 0.1
    ) -> some View {
        self
            .drawingGroup() // CRITICAL: Flatten to bitmap for layer sampling
            .visualEffect { content, proxy in
                let size = proxy.size
                let normalizedCenter = CGPoint(
                    x: position.x / size.width,
                    y: position.y / size.height
                )
                let normalizedRadius = Float(diameter / 2 / min(size.width, size.height))

                return content.layerEffect(
                    ShaderLibrary.magnifyingGlass(
                        .float2(Float(size.width), Float(size.height)),
                        .float2(Float(normalizedCenter.x), Float(normalizedCenter.y)),
                        .float(normalizedRadius),
                        .float(refractionStrength),
                        .float(shadowOffset),
                        .float(shadowBlur),
                        .float(edgeThickness),
                        .float(chromaticAmount)
                    ),
                    maxSampleOffset: CGSize(width: 150, height: 150)
                )
            }
    }

    /// Adds an animated liquid glass effect
    func liquidGlass(
        at position: CGPoint,
        diameter: CGFloat = 180,
        refractionStrength: Float = 0.08,
        time: Float
    ) -> some View {
        self
            .drawingGroup()
            .visualEffect { content, proxy in
                let size = proxy.size
                let normalizedCenter = CGPoint(
                    x: position.x / size.width,
                    y: position.y / size.height
                )
                let normalizedRadius = Float(diameter / 2 / min(size.width, size.height))

                return content.layerEffect(
                    ShaderLibrary.liquidGlass(
                        .float2(Float(size.width), Float(size.height)),
                        .float2(Float(normalizedCenter.x), Float(normalizedCenter.y)),
                        .float(normalizedRadius),
                        .float(time),
                        .float(refractionStrength)
                    ),
                    maxSampleOffset: CGSize(width: 150, height: 150)
                )
            }
    }
}

// MARK: - Demo View with Controls

/// Interactive demo view for testing different glass parameters
struct MagnifyingGlassDemoView: View {
    @State private var refractionStrength: Float = 0.08
    @State private var shadowOffset: Float = 0.02
    @State private var shadowBlur: Float = 0.06
    @State private var edgeThickness: Float = 0.015
    @State private var chromaticAmount: Float = 0.1
    @State private var diameter: CGFloat = 180
    @State private var animated: Bool = false
    @State private var showControls: Bool = true
    @State private var glassPosition: CGPoint = CGPoint(x: 200, y: 400)
    @State private var animationTime: Float = 0
    @GestureState private var dragOffset: CGSize = .zero

    private let timer = Timer.publish(every: 1/60, on: .main, in: .common).autoconnect()

    var body: some View {
        let currentPosition = CGPoint(
            x: glassPosition.x + dragOffset.width,
            y: glassPosition.y + dragOffset.height
        )

        ZStack {
            // Background content with glass effect
            if animated {
                backgroundContent
                    .liquidGlass(
                        at: currentPosition,
                        diameter: diameter,
                        refractionStrength: refractionStrength,
                        time: animationTime
                    )
            } else {
                backgroundContent
                    .magnifyingGlass(
                        at: currentPosition,
                        diameter: diameter,
                        refractionStrength: refractionStrength,
                        shadowOffset: shadowOffset,
                        shadowBlur: shadowBlur,
                        edgeThickness: edgeThickness,
                        chromaticAmount: chromaticAmount
                    )
            }

            // Drag gesture overlay
            Color.clear
                .contentShape(Rectangle())
                .gesture(
                    DragGesture()
                        .updating($dragOffset) { value, state, _ in
                            state = value.translation
                        }
                        .onEnded { value in
                            glassPosition.x += value.translation.width
                            glassPosition.y += value.translation.height
                        }
                )

            // Controls overlay (not affected by glass)
            if showControls {
                controlsPanel
            }
        }
        .ignoresSafeArea()
        .onTapGesture(count: 2) {
            withAnimation(.spring(response: 0.3)) {
                showControls.toggle()
            }
        }
        .onReceive(timer) { _ in
            if animated {
                animationTime += 1/60
            }
        }
    }

    private var backgroundContent: some View {
        ZStack {
            // Base gradient
            LinearGradient(
                colors: [
                    Color(red: 0.1, green: 0.08, blue: 0.2),
                    Color(red: 0.05, green: 0.1, blue: 0.25),
                    Color(red: 0.15, green: 0.05, blue: 0.15)
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )

            // Decorative elements
            VStack(spacing: 60) {
                // Colorful orbs
                HStack(spacing: 80) {
                    Circle()
                        .fill(
                            RadialGradient(
                                colors: [.purple.opacity(0.8), .purple.opacity(0.2), .clear],
                                center: .center,
                                startRadius: 0,
                                endRadius: 80
                            )
                        )
                        .frame(width: 160, height: 160)

                    Circle()
                        .fill(
                            RadialGradient(
                                colors: [.cyan.opacity(0.7), .blue.opacity(0.3), .clear],
                                center: .center,
                                startRadius: 0,
                                endRadius: 70
                            )
                        )
                        .frame(width: 140, height: 140)
                }

                // White text to show chromatic aberration
                VStack(spacing: 16) {
                    Text("GLASS")
                        .font(.system(size: 72, weight: .black, design: .rounded))
                        .foregroundStyle(.white)

                    Text("Refractive Material")
                        .font(.system(size: 24, weight: .medium, design: .rounded))
                        .foregroundStyle(.white.opacity(0.8))
                }

                // More colorful elements
                HStack(spacing: 60) {
                    Circle()
                        .fill(
                            RadialGradient(
                                colors: [.orange.opacity(0.6), .red.opacity(0.3), .clear],
                                center: .center,
                                startRadius: 0,
                                endRadius: 60
                            )
                        )
                        .frame(width: 120, height: 120)

                    Circle()
                        .fill(
                            RadialGradient(
                                colors: [.green.opacity(0.5), .teal.opacity(0.2), .clear],
                                center: .center,
                                startRadius: 0,
                                endRadius: 50
                            )
                        )
                        .frame(width: 100, height: 100)

                    Circle()
                        .fill(
                            RadialGradient(
                                colors: [.pink.opacity(0.6), .purple.opacity(0.2), .clear],
                                center: .center,
                                startRadius: 0,
                                endRadius: 55
                            )
                        )
                        .frame(width: 110, height: 110)
                }

                // Grid pattern
                gridPattern
            }
        }
    }

    private var gridPattern: some View {
        Canvas { context, size in
            let spacing: CGFloat = 30
            let lineWidth: CGFloat = 1

            // Vertical lines
            for x in stride(from: 0, through: size.width, by: spacing) {
                var path = Path()
                path.move(to: CGPoint(x: x, y: 0))
                path.addLine(to: CGPoint(x: x, y: size.height))
                context.stroke(path, with: .color(.white.opacity(0.1)), lineWidth: lineWidth)
            }

            // Horizontal lines
            for y in stride(from: 0, through: size.height, by: spacing) {
                var path = Path()
                path.move(to: CGPoint(x: 0, y: y))
                path.addLine(to: CGPoint(x: size.width, y: y))
                context.stroke(path, with: .color(.white.opacity(0.1)), lineWidth: lineWidth)
            }
        }
        .frame(width: 300, height: 200)
    }

    private var controlsPanel: some View {
        VStack {
            Spacer()

            VStack(spacing: 12) {
                HStack {
                    Text("Glass Controls")
                        .font(.headline)
                        .foregroundStyle(.white)
                    Spacer()
                    Toggle("Animated", isOn: $animated)
                        .toggleStyle(.switch)
                        .labelsHidden()
                    Text("Liquid")
                        .font(.caption)
                        .foregroundStyle(.white.opacity(0.7))
                }

                Divider().background(.white.opacity(0.3))

                controlRow(label: "Refraction", value: $refractionStrength, range: 0...0.2)
                controlRow(label: "Shadow Offset", value: $shadowOffset, range: 0...0.05)
                controlRow(label: "Shadow Blur", value: $shadowBlur, range: 0...0.15)
                controlRow(label: "Edge Light", value: $edgeThickness, range: 0...0.05)
                controlRow(label: "Chromatic", value: $chromaticAmount, range: 0...0.3)

                HStack {
                    Text("Diameter: \(Int(diameter))")
                        .font(.caption)
                        .foregroundStyle(.white.opacity(0.7))
                    Slider(value: $diameter, in: 80...300)
                }

                Text("Double-tap to hide controls")
                    .font(.caption2)
                    .foregroundStyle(.white.opacity(0.5))
            }
            .padding()
            .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 16))
            .padding()
        }
    }

    private func controlRow(label: String, value: Binding<Float>, range: ClosedRange<Float>) -> some View {
        HStack {
            Text(label)
                .font(.caption)
                .foregroundStyle(.white.opacity(0.7))
                .frame(width: 90, alignment: .leading)
            Slider(value: value, in: range)
            Text(String(format: "%.3f", value.wrappedValue))
                .font(.caption.monospaced())
                .foregroundStyle(.white.opacity(0.5))
                .frame(width: 50)
        }
    }
}

// MARK: - Preview

#Preview("Magnifying Glass Demo") {
    MagnifyingGlassDemoView()
}

#Preview("Simple Glass") {
    ZStack {
        LinearGradient(
            colors: [.indigo, .purple, .pink],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
        .overlay {
            VStack(spacing: 30) {
                Text("Hello World")
                    .font(.largeTitle.bold())
                    .foregroundStyle(.white)

                Text("Glass Effect")
                    .font(.headline)
                    .foregroundStyle(.white.opacity(0.8))
            }
        }
        .magnifyingGlass(at: CGPoint(x: 200, y: 400), diameter: 200)
    }
    .ignoresSafeArea()
}

#Preview("Liquid Glass") {
    LiquidGlassPreview()
}

struct LiquidGlassPreview: View {
    @State private var time: Float = 0
    private let timer = Timer.publish(every: 1/60, on: .main, in: .common).autoconnect()

    var body: some View {
        ZStack {
            LinearGradient(
                colors: [
                    Color(red: 0.05, green: 0.1, blue: 0.2),
                    Color(red: 0.1, green: 0.05, blue: 0.15)
                ],
                startPoint: .top,
                endPoint: .bottom
            )
            .overlay {
                VStack {
                    Text("LIQUID")
                        .font(.system(size: 60, weight: .black))
                        .foregroundStyle(.white)
                    Text("GLASS")
                        .font(.system(size: 60, weight: .black))
                        .foregroundStyle(.cyan)
                }
            }
            .liquidGlass(
                at: CGPoint(x: 200, y: 400),
                diameter: 200,
                refractionStrength: 0.08,
                time: time
            )
        }
        .ignoresSafeArea()
        .onReceive(timer) { _ in
            time += 1/60
        }
    }
}
