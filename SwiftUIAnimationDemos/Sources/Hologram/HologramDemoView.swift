//
//  Hologram.swift
//  DemoView
//
//  Pokemon-style holographic card with motion-reactive Metal shaders
//

import SwiftUI
import CoreMotion

// MARK: - Motion Manager

@Observable
final class MotionManager {
    var pitch: Double = 0
    var roll: Double = 0

    private let motionManager = CMMotionManager()
    private let queue = OperationQueue()

    init() {
        startMotionUpdates()
    }

    private func startMotionUpdates() {
        guard motionManager.isDeviceMotionAvailable else { return }

        motionManager.deviceMotionUpdateInterval = 1.0 / 60.0
        motionManager.startDeviceMotionUpdates(to: queue) { [weak self] motion, _ in
            guard let motion = motion else { return }

            DispatchQueue.main.async {
                // Normalize pitch and roll to roughly -1 to 1 range
                self?.pitch = motion.attitude.pitch / .pi * 2
                self?.roll = motion.attitude.roll / .pi * 2
            }
        }
    }

    func stop() {
        motionManager.stopDeviceMotionUpdates()
    }
}

// MARK: - Holographic Card View

struct HolographicCardView: View {
    @State private var motionManager = MotionManager()
    @State private var startTime = Date.now
    @State private var dragOffset: CGSize = .zero

    var body: some View {
        TimelineView(.animation) { timeline in
            let elapsedTime = startTime.distance(to: timeline.date)

            // Combine motion + drag for tilt
            let combinedPitch = motionManager.pitch + Double(dragOffset.height) / 150
            let combinedRoll = motionManager.roll + Double(dragOffset.width) / 150

            cardContent
                .drawingGroup()
                .visualEffect { content, proxy in
                    content.layerEffect(
                        ShaderLibrary.holographicCard(
                            .float2(proxy.size),
                            .float2(
                                Float(combinedPitch),
                                Float(combinedRoll)
                            ),
                            .float(Float(elapsedTime)),
                            .float(0.8)  // intensity
                        ),
                        maxSampleOffset: .zero
                    )
                }
                .rotation3DEffect(
                    .degrees(combinedRoll * 12),
                    axis: (x: 0, y: 1, z: 0)
                )
                .rotation3DEffect(
                    .degrees(-combinedPitch * 12),
                    axis: (x: 1, y: 0, z: 0)
                )
        }
        .gesture(
            DragGesture()
                .onChanged { value in
                    // Limit the drag range
                    let maxOffset: CGFloat = 60
                    dragOffset = CGSize(
                        width: max(-maxOffset, min(maxOffset, value.translation.width)),
                        height: max(-maxOffset, min(maxOffset, value.translation.height))
                    )
                }
                .onEnded { _ in
                    // Spring back to center
                    withAnimation(.spring(response: 0.4, dampingFraction: 0.6)) {
                        dragOffset = .zero
                    }
                }
        )
        .onDisappear {
            motionManager.stop()
        }
    }

    private var cardContent: some View {
        ZStack {
            // Card background - golden/yellow Pokemon card style
            RoundedRectangle(cornerRadius: 16)
                .fill(
                    LinearGradient(
                        colors: [
                            Color(red: 0.95, green: 0.85, blue: 0.5),
                            Color(red: 0.9, green: 0.75, blue: 0.4),
                            Color(red: 0.85, green: 0.7, blue: 0.35)
                        ],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )

            VStack(spacing: 0) {
                // Header: Name + HP
                HStack(alignment: .top) {
                    HStack(spacing: 4) {
                        Text("STAGE 2")
                            .font(.system(size: 9, weight: .bold))
                            .padding(.horizontal, 5)
                            .padding(.vertical, 2)
                            .background(.black.opacity(0.7))
                            .foregroundStyle(.white)
                            .clipShape(RoundedRectangle(cornerRadius: 3))

                        Text("Charizard")
                            .font(.system(size: 18, weight: .bold))
                            .foregroundStyle(.black)
                    }

                    Spacer()

                    HStack(spacing: 2) {
                        Text("HP")
                            .font(.system(size: 12, weight: .medium))
                        Text("180")
                            .font(.system(size: 20, weight: .bold))
                        Image(systemName: "flame.fill")
                            .font(.system(size: 14))
                            .foregroundStyle(.orange)
                    }
                    .foregroundStyle(.red)
                }
                .padding(.horizontal, 12)
                .padding(.top, 10)

                // Artwork frame
                ZStack {
                    RoundedRectangle(cornerRadius: 8)
                        .fill(Color.white.opacity(0.3))
                        .frame(height: 160)

                    // Charizard artwork
                    Image("charizard")
                        .resizable()
                        .aspectRatio(contentMode: .fit)
                        .frame(height: 140)
                }
                .padding(.horizontal, 10)
                .padding(.top, 6)

                // Pokemon info line
                Text("NO.006  Charizard  HT: 5'7\"  WT: 200 lbs")
                    .font(.system(size: 8))
                    .foregroundStyle(.black.opacity(0.5))
                    .padding(.top, 4)

                Spacer()

                // Ability section
                VStack(alignment: .leading, spacing: 4) {
                    HStack {
                        Text("Ability")
                            .font(.system(size: 10, weight: .bold))
                            .foregroundStyle(.white)
                            .padding(.horizontal, 8)
                            .padding(.vertical, 3)
                            .background(.red)
                            .clipShape(RoundedRectangle(cornerRadius: 4))

                        Text("Blazing Aura")
                            .font(.system(size: 14, weight: .bold))
                            .foregroundStyle(.black)
                    }
                    Text("Once during your turn, you may attach a Fire Energy from your discard pile to this Pokemon.")
                        .font(.system(size: 9))
                        .foregroundStyle(.black.opacity(0.8))
                        .lineLimit(2)
                }
                .padding(.horizontal, 12)

                // Attack section
                HStack {
                    HStack(spacing: 2) {
                        Image(systemName: "flame.fill")
                            .font(.system(size: 12))
                            .foregroundStyle(.orange)
                        Image(systemName: "flame.fill")
                            .font(.system(size: 12))
                            .foregroundStyle(.orange)
                        Image(systemName: "circle.fill")
                            .font(.system(size: 12))
                            .foregroundStyle(.gray.opacity(0.5))
                    }

                    Text("Fire Blast")
                        .font(.system(size: 14, weight: .bold))
                        .foregroundStyle(.black)
                        .padding(.leading, 8)

                    Spacer()

                    Text("150")
                        .font(.system(size: 22, weight: .bold))
                        .foregroundStyle(.black)
                }
                .padding(.horizontal, 12)
                .padding(.top, 8)

                Divider()
                    .padding(.horizontal, 12)
                    .padding(.top, 8)

                // Footer: Weakness, Resistance, Retreat
                HStack {
                    HStack(spacing: 4) {
                        Text("weakness")
                            .font(.system(size: 8))
                        Image(systemName: "drop.fill")
                            .font(.system(size: 10))
                            .foregroundStyle(.blue)
                        Text("x2")
                            .font(.system(size: 10, weight: .bold))
                    }

                    Spacer()

                    HStack(spacing: 4) {
                        Text("resistance")
                            .font(.system(size: 8))
                        Image(systemName: "leaf.fill")
                            .font(.system(size: 10))
                            .foregroundStyle(.green)
                        Text("-30")
                            .font(.system(size: 10, weight: .bold))
                    }

                    Spacer()

                    HStack(spacing: 4) {
                        Text("retreat")
                            .font(.system(size: 8))
                        Image(systemName: "circle.fill")
                            .font(.system(size: 8))
                            .foregroundStyle(.gray.opacity(0.5))
                        Image(systemName: "circle.fill")
                            .font(.system(size: 8))
                            .foregroundStyle(.gray.opacity(0.5))
                    }
                }
                .foregroundStyle(.black.opacity(0.7))
                .padding(.horizontal, 12)
                .padding(.top, 6)

                // Flavor text
                Text("It spits fire that is hot enough to melt boulders. It may cause forest fires by blowing flames.")
                    .font(.system(size: 8).italic())
                    .foregroundStyle(.black.opacity(0.6))
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 20)
                    .padding(.vertical, 8)
            }

            // Card border
            RoundedRectangle(cornerRadius: 16)
                .strokeBorder(
                    LinearGradient(
                        colors: [
                            .yellow.opacity(0.8),
                            .orange.opacity(0.6),
                            .yellow.opacity(0.8)
                        ],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    ),
                    lineWidth: 4
                )
        }
        .frame(width: 260, height: 380)
        .clipShape(RoundedRectangle(cornerRadius: 16))
        .shadow(color: .black.opacity(0.3), radius: 15, y: 8)
    }
}

// MARK: - Intense Holographic Card (More Bling)

struct IntenseHolographicCardView: View {
    @State private var motionManager = MotionManager()
    @State private var startTime = Date.now
    @State private var dragOffset: CGSize = .zero

    var body: some View {
        TimelineView(.animation) { timeline in
            let elapsedTime = startTime.distance(to: timeline.date)

            // Combine motion + drag for tilt
            let combinedPitch = motionManager.pitch + Double(dragOffset.height) / 150
            let combinedRoll = motionManager.roll + Double(dragOffset.width) / 150

            cardContent
                .drawingGroup()
                .visualEffect { content, proxy in
                    content.layerEffect(
                        ShaderLibrary.holographicIntense(
                            .float2(proxy.size),
                            .float2(
                                Float(combinedPitch),
                                Float(combinedRoll)
                            ),
                            .float(Float(elapsedTime))
                        ),
                        maxSampleOffset: .zero
                    )
                }
                .rotation3DEffect(
                    .degrees(combinedRoll * 15),
                    axis: (x: 0, y: 1, z: 0)
                )
                .rotation3DEffect(
                    .degrees(-combinedPitch * 15),
                    axis: (x: 1, y: 0, z: 0)
                )
        }
        .gesture(
            DragGesture()
                .onChanged { value in
                    let maxOffset: CGFloat = 60
                    dragOffset = CGSize(
                        width: max(-maxOffset, min(maxOffset, value.translation.width)),
                        height: max(-maxOffset, min(maxOffset, value.translation.height))
                    )
                }
                .onEnded { _ in
                    withAnimation(.spring(response: 0.4, dampingFraction: 0.6)) {
                        dragOffset = .zero
                    }
                }
        )
        .onDisappear {
            motionManager.stop()
        }
    }

    private var cardContent: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 20)
                .fill(
                    LinearGradient(
                        colors: [
                            Color(red: 0.2, green: 0.1, blue: 0.3),
                            Color(red: 0.1, green: 0.1, blue: 0.2),
                            Color(red: 0.15, green: 0.1, blue: 0.25)
                        ],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )

            VStack(spacing: 12) {
                HStack {
                    Text("Ultra Rare")
                        .font(.headline)
                        .fontWeight(.heavy)
                        .foregroundStyle(.white)
                    Spacer()
                    Text("HP 200")
                        .font(.subheadline)
                        .fontWeight(.bold)
                        .foregroundStyle(.orange)
                }
                .padding(.horizontal, 20)
                .padding(.top, 16)

                Spacer()

                Image(systemName: "flame.fill")
                    .font(.system(size: 100))
                    .foregroundStyle(
                        LinearGradient(
                            colors: [.red, .orange, .yellow],
                            startPoint: .bottom,
                            endPoint: .top
                        )
                    )
                    .shadow(color: .orange.opacity(0.8), radius: 20)

                Spacer()

                VStack(spacing: 8) {
                    HStack {
                        Image(systemName: "flame.circle.fill")
                            .foregroundStyle(.red)
                        Text("Inferno Strike")
                            .font(.subheadline)
                            .fontWeight(.semibold)
                            .foregroundStyle(.white)
                        Spacer()
                        Text("150")
                            .font(.title3)
                            .fontWeight(.black)
                            .foregroundStyle(.orange)
                    }

                    Text("Secret Rare Holographic")
                        .font(.caption2)
                        .foregroundStyle(.yellow.opacity(0.8))
                }
                .padding(.horizontal, 20)
                .padding(.bottom, 16)
            }

            RoundedRectangle(cornerRadius: 20)
                .strokeBorder(
                    LinearGradient(
                        colors: [.orange, .yellow, .red],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    ),
                    lineWidth: 3
                )
        }
        .frame(width: 280, height: 400)
        .shadow(color: .orange.opacity(0.5), radius: 25, y: 12)
    }
}

// MARK: - Demo View with Card Selection

struct HologramDemoView: View {
    @State private var selectedCard = 0

    var body: some View {
        ZStack {
          
            // Background
            LinearGradient(
                colors: [
                    Color(red: 0.05, green: 0.05, blue: 0.1),
                    Color(red: 0.1, green: 0.08, blue: 0.15)
                ],
                startPoint: .top,
                endPoint: .bottom
            )
            .ignoresSafeArea()

            VStack(spacing: 40) {
                Text("Collection")
                    .font(.title)
                    .fontWeight(.bold)
                    .foregroundStyle(.white)

                // Card display
                TabView(selection: $selectedCard) {
                    HolographicCardView()
                        .tag(0)

                    IntenseHolographicCardView()
                        .tag(1)
                }
                .tabViewStyle(.page(indexDisplayMode: .always))
                .frame(height: 500)

                Text("Tilt your device to see the effect")
                    .font(.caption)
                    .foregroundStyle(.white.opacity(0.6))
            }
            .padding()
        }
    }
}

#Preview {
  HologramDemoView()
}
