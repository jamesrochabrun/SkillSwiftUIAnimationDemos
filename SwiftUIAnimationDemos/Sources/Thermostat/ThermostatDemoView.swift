//
//  TemperatureAnimation.swift
//  DemoView
//
//  Interactive thermometer with plasma energy shader effects
//  Swirling plasma with electric tendrils when hot, frozen aurora when cold
//  Uses Metal shaders for GPU-accelerated visual effects
//

import SwiftUI

// MARK: - Main View

struct TemperatureAnimationView: View {

    @State private var temperature: Double = 90
    @State private var startTime = Date.now
    @State private var isDragging = false

    private let minTempC: Double = -30
    private let maxTempC: Double = 50
    private let minTempF: Double = -20
    private let maxTempF: Double = 120

    private var normalizedTemperature: Double {
        (temperature - minTempF) / (maxTempF - minTempF)
    }

    var body: some View {
        GeometryReader { geometry in
            let size = geometry.size

            TimelineView(.animation) { timeline in
                let elapsedTime = startTime.distance(to: timeline.date)

                ZStack {
                    // Dynamic background
                    DynamicBackgroundView(
                        size: size,
                        normalizedTemperature: normalizedTemperature,
                        elapsedTime: elapsedTime
                    )

                    VStack(spacing: 0) {
                        Spacer()

                        // Scale headers
                        HStack {
                            Text("°C")
                                .font(.system(size: 22, weight: .medium))
                                .foregroundStyle(.white.opacity(0.7))

                            Spacer()

                            Text("°F")
                                .font(.system(size: 22, weight: .medium))
                                .foregroundStyle(.white.opacity(0.7))
                        }
                        .frame(width: 200)
                        .padding(.bottom, 8)

                        // Thermometer with molten liquid
                        MoltenThermometerView(
                            temperature: $temperature,
                            isDragging: $isDragging,
                            minTempC: minTempC,
                            maxTempC: maxTempC,
                            minTempF: minTempF,
                            maxTempF: maxTempF,
                            normalizedTemperature: normalizedTemperature,
                            elapsedTime: elapsedTime
                        )
                        .frame(width: 240, height: min(size.height * 0.58, 480))

                        Spacer().frame(height: 35)

                        // Temperature display (UNCHANGED - keeping the effects you love!)
                        DynamicTemperatureDisplay(
                            temperature: temperature,
                            normalizedTemperature: normalizedTemperature,
                            elapsedTime: elapsedTime
                        )

                        Spacer()
                    }
                    .padding()
                }
            }
        }
        .ignoresSafeArea()
    }
}

// MARK: - Dynamic Background

struct DynamicBackgroundView: View {
    let size: CGSize
    let normalizedTemperature: Double
    let elapsedTime: TimeInterval

    var body: some View {
        Rectangle()
            .fill(Color.black)
            .colorEffect(
                ShaderLibrary.dynamicBackground(
                    .float2(size),
                    .float(normalizedTemperature),
                    .float(elapsedTime)
                )
            )
            .colorEffect(
                ShaderLibrary.floatingParticles(
                    .float2(size),
                    .float(normalizedTemperature),
                    .float(elapsedTime)
                )
            )
    }
}

// MARK: - Molten Thermometer

struct MoltenThermometerView: View {
    @Binding var temperature: Double
    @Binding var isDragging: Bool
    let minTempC: Double
    let maxTempC: Double
    let minTempF: Double
    let maxTempF: Double
    let normalizedTemperature: Double
    let elapsedTime: TimeInterval

    private let tubeWidth: CGFloat = 65
    private let bulbRadius: CGFloat = 50

    var body: some View {
        GeometryReader { geometry in
            let size = geometry.size
            let tubeHeight = size.height - bulbRadius * 2 - 35
            let tubeRect = CGRect(
                x: (size.width - tubeWidth) / 2,
                y: 25,
                width: tubeWidth,
                height: tubeHeight
            )
            let bulbCenter = CGPoint(
                x: size.width / 2,
                y: tubeRect.maxY + bulbRadius - 8
            )

            ZStack {
                // Outer glow
                Rectangle()
                    .fill(Color.clear)
                    .colorEffect(
                        ShaderLibrary.temperatureOuterGlow(
                            .float2(size),
                            .float2(CGPoint(x: size.width / 2, y: size.height / 2)),
                            .float(tubeWidth),
                            .float(normalizedTemperature),
                            .float(elapsedTime)
                        )
                    )

                // Glass thermometer outline
                ThermometerShape(
                    tubeRect: tubeRect,
                    bulbCenter: bulbCenter,
                    bulbRadius: bulbRadius
                )
                .fill(Color.white.opacity(0.05))
                .overlay(
                    ThermometerShape(
                        tubeRect: tubeRect,
                        bulbCenter: bulbCenter,
                        bulbRadius: bulbRadius
                    )
                    .stroke(Color.white.opacity(0.15), lineWidth: 2)
                )

                // Plasma energy fill - clipped to thermometer shape
                PlasmaEnergyFillView(
                    tubeRect: tubeRect,
                    bulbCenter: bulbCenter,
                    bulbRadius: bulbRadius,
                    fillLevel: normalizedTemperature,
                    elapsedTime: elapsedTime
                )
                .clipShape(
                    ThermometerFillShape(
                        tubeRect: tubeRect,
                        bulbCenter: bulbCenter,
                        bulbRadius: bulbRadius,
                        fillLevel: normalizedTemperature
                    )
                )

                // Scales
                TemperatureScale(
                    tubeRect: tubeRect,
                    minTemp: minTempC,
                    maxTemp: maxTempC,
                    isLeftSide: true
                )

                TemperatureScale(
                    tubeRect: tubeRect,
                    minTemp: minTempF,
                    maxTemp: maxTempF,
                    isLeftSide: false
                )
            }
            .contentShape(Rectangle())
            .gesture(
                DragGesture(minimumDistance: 0)
                    .onChanged { value in
                        isDragging = true
                        updateTemperature(from: value.location, in: tubeRect)
                    }
                    .onEnded { _ in
                        isDragging = false
                    }
            )
        }
    }

    private func updateTemperature(from location: CGPoint, in tubeRect: CGRect) {
        let clampedY = min(max(location.y, tubeRect.minY), tubeRect.maxY)
        let normalized = 1 - (clampedY - tubeRect.minY) / tubeRect.height
        let newTemp = minTempF + (maxTempF - minTempF) * normalized
        withAnimation(.interactiveSpring(response: 0.1, dampingFraction: 0.7)) {
            temperature = min(max(newTemp, minTempF), maxTempF)
        }
    }
}

// MARK: - Plasma Energy Fill

struct PlasmaEnergyFillView: View {
    let tubeRect: CGRect
    let bulbCenter: CGPoint
    let bulbRadius: CGFloat
    let fillLevel: Double
    let elapsedTime: TimeInterval

    var body: some View {
        Canvas { context, size in
            let innerPadding: CGFloat = 4

            // Bulb
            let bulbPath = Path(ellipseIn: CGRect(
                x: bulbCenter.x - bulbRadius + innerPadding,
                y: bulbCenter.y - bulbRadius + innerPadding,
                width: (bulbRadius - innerPadding) * 2,
                height: (bulbRadius - innerPadding) * 2
            ))

            // Full tube
            let tubePath = Path(
                roundedRect: CGRect(
                    x: tubeRect.minX + innerPadding,
                    y: tubeRect.minY,
                    width: tubeRect.width - innerPadding * 2,
                    height: tubeRect.height + innerPadding
                ),
                cornerRadius: (tubeRect.width - innerPadding * 2) / 2
            )

            // Connection
            let connectionPath = Path { p in
                let connWidth = tubeRect.width - innerPadding * 2
                p.addRect(CGRect(
                    x: tubeRect.minX + innerPadding,
                    y: tubeRect.maxY - connWidth / 2,
                    width: connWidth,
                    height: bulbCenter.y - tubeRect.maxY + connWidth
                ))
            }

            // Fill with white - shader will colorize
            context.fill(bulbPath, with: .color(.white))
            context.fill(connectionPath, with: .color(.white))
            context.fill(tubePath, with: .color(.white))
        }
        .drawingGroup()
        .visualEffect { content, proxy in
            content
                // Chaotic plasma distortion
                .distortionEffect(
                    ShaderLibrary.plasmaDistortion(
                        .float2(proxy.size),
                        .float(elapsedTime),
                        .float(1.0),
                        .float(fillLevel)
                    ),
                    maxSampleOffset: CGSize(width: 12, height: 10)
                )
                // Thermostat plasma coloring effect
                .layerEffect(
                    ShaderLibrary.thermostatPlasma(
                        .float2(proxy.size),
                        .float(fillLevel),
                        .float(elapsedTime)
                    ),
                    maxSampleOffset: .zero
                )
        }
        .shadow(color: glowColor.opacity(0.6), radius: 20)
        .shadow(color: glowColor.opacity(0.4), radius: 45)
        .shadow(color: glowColor.opacity(0.25), radius: 80)
    }

    private var glowColor: Color {
        if fillLevel < 0.3 {
            // Ice blue with cyan tint
            return Color(red: 0.2, green: 0.6, blue: 1.0)
        } else if fillLevel < 0.45 {
            // Purple/magenta transition
            return Color(red: 0.7, green: 0.3, blue: 0.9)
        } else {
            // Fire orange-yellow
            return Color(red: 1.0, green: 0.55, blue: 0.1)
        }
    }
}

// MARK: - Thermometer Shape

struct ThermometerShape: Shape {
    let tubeRect: CGRect
    let bulbCenter: CGPoint
    let bulbRadius: CGFloat

    func path(in rect: CGRect) -> Path {
        var path = Path()

        let tubeCornerRadius = tubeRect.width / 2
        path.addRoundedRect(
            in: tubeRect,
            cornerSize: CGSize(width: tubeCornerRadius, height: tubeCornerRadius)
        )

        path.addEllipse(in: CGRect(
            x: bulbCenter.x - bulbRadius,
            y: bulbCenter.y - bulbRadius,
            width: bulbRadius * 2,
            height: bulbRadius * 2
        ))

        return path
    }
}

// MARK: - Thermometer Fill Shape

struct ThermometerFillShape: Shape {
    let tubeRect: CGRect
    let bulbCenter: CGPoint
    let bulbRadius: CGFloat
    let fillLevel: Double

    var animatableData: Double {
        get { fillLevel }
        set { }
    }

    func path(in rect: CGRect) -> Path {
        var path = Path()
        let innerPadding: CGFloat = 4

        // Bulb always filled
        path.addEllipse(in: CGRect(
            x: bulbCenter.x - bulbRadius + innerPadding,
            y: bulbCenter.y - bulbRadius + innerPadding,
            width: (bulbRadius - innerPadding) * 2,
            height: (bulbRadius - innerPadding) * 2
        ))

        // Connection
        let connWidth = tubeRect.width - innerPadding * 2
        path.addRect(CGRect(
            x: tubeRect.minX + innerPadding,
            y: tubeRect.maxY - connWidth / 2,
            width: connWidth,
            height: bulbCenter.y - tubeRect.maxY + connWidth
        ))

        // Tube fill
        let fillHeight = tubeRect.height * fillLevel
        if fillHeight > 0 {
            path.addRoundedRect(
                in: CGRect(
                    x: tubeRect.minX + innerPadding,
                    y: tubeRect.maxY - fillHeight,
                    width: tubeRect.width - innerPadding * 2,
                    height: fillHeight + innerPadding
                ),
                cornerSize: CGSize(
                    width: (tubeRect.width - innerPadding * 2) / 2,
                    height: (tubeRect.width - innerPadding * 2) / 2
                )
            )
        }

        return path
    }
}

// MARK: - Temperature Scale

struct TemperatureScale: View {
    let tubeRect: CGRect
    let minTemp: Double
    let maxTemp: Double
    let isLeftSide: Bool

    var body: some View {
        let step = 10.0
        let range = Array(stride(from: Int(minTemp), through: Int(maxTemp), by: Int(step)))

        ForEach(range, id: \.self) { temp in
            let normalized = Double(temp - Int(minTemp)) / (maxTemp - minTemp)
            let y = tubeRect.maxY - tubeRect.height * normalized

            HStack(spacing: 3) {
                if isLeftSide {
                    Text("\(temp)")
                        .font(.system(size: 11, weight: .medium, design: .monospaced))
                        .foregroundStyle(.white.opacity(0.7))

                    Rectangle()
                        .fill(Color.white.opacity(0.45))
                        .frame(width: temp % 20 == 0 ? 12 : 6, height: 1)
                } else {
                    Rectangle()
                        .fill(Color.white.opacity(0.45))
                        .frame(width: temp % 20 == 0 ? 12 : 6, height: 1)

                    Text("\(temp)")
                        .font(.system(size: 11, weight: .medium, design: .monospaced))
                        .foregroundStyle(.white.opacity(0.7))
                }
            }
            .position(
                x: isLeftSide ? tubeRect.minX - 32 : tubeRect.maxX + 32,
                y: y
            )
        }
    }
}

// MARK: - Dynamic Temperature Display (UNCHANGED - keeping the effects you love!)

struct DynamicTemperatureDisplay: View {
    let temperature: Double
    let normalizedTemperature: Double
    let elapsedTime: TimeInterval

    var body: some View {
        HStack(alignment: .firstTextBaseline, spacing: 2) {
            Text("\(Int(temperature))")
                .font(.system(size: 80, weight: .bold, design: .rounded))
                .monospacedDigit()
                .contentTransition(.numericText(value: temperature))

            Text("°F")
                .font(.system(size: 28, weight: .medium, design: .rounded))
                .offset(y: -12)
        }
        .foregroundStyle(.white)
        .drawingGroup()
        .visualEffect { content, proxy in
            content
                .layerEffect(
                    ShaderLibrary.temperatureText(
                        .float2(proxy.size),
                        .float(normalizedTemperature),
                        .float(elapsedTime)
                    ),
                    maxSampleOffset: CGSize(width: 15, height: 15)
                )
        }
        .shadow(color: textGlowColor.opacity(0.5), radius: 15)
        .shadow(color: textGlowColor.opacity(0.3), radius: 35)
        .animation(.spring(response: 0.2, dampingFraction: 0.7), value: temperature)
    }

    private var textGlowColor: Color {
        if normalizedTemperature < 0.35 {
            return Color(red: 0.3, green: 0.6, blue: 1.0)
        } else if normalizedTemperature < 0.5 {
            return Color(red: 0.6, green: 0.45, blue: 0.7)
        } else {
            return Color(red: 1.0, green: 0.45, blue: 0.15)
        }
    }
}

#Preview {
    TemperatureAnimationView()
        .preferredColorScheme(.dark)
}
