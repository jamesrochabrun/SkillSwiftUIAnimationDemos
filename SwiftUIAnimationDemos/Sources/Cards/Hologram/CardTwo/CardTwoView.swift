//
//  CardTwoView.swift
//  SwiftUIAnimationDemos
//
//  Butterfly holographic card with intense shader effects
//

import SwiftUI

struct CardTwoView: View {
    @State private var motionManager = MotionManager()
    @State private var startTime = Date.now
    @State private var dragOffset: CGSize = .zero

    var body: some View {
        TimelineView(.animation) { timeline in
            let elapsedTime = startTime.distance(to: timeline.date)

            // Combine motion + drag for tilt
            let combinedTilt = CGPoint(
                x: motionManager.tilt.x + dragOffset.width / 150,
                y: motionManager.tilt.y + dragOffset.height / 150
            )

            cardContent
                .drawingGroup()
                .visualEffect { content, proxy in
                    content.layerEffect(
                        ShaderLibrary.cardTwoHolographic(
                            .float2(proxy.size),
                            .float2(combinedTilt),
                            .float(Float(elapsedTime))
                        ),
                        maxSampleOffset: .zero
                    )
                }
                .rotation3DEffect(
                    .degrees(combinedTilt.x * 15),
                    axis: (x: 0, y: 1, z: 0)
                )
                .rotation3DEffect(
                    .degrees(-combinedTilt.y * 15),
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
        .onAppear {
            motionManager.start()
        }
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

            // Butterfly artwork - full bleed background
            Image("butterfly")
                .resizable()
                .aspectRatio(contentMode: .fill)
                .frame(width: 280, height: 400)
                .clipped()
                .blendMode(.screen)

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

#Preview {
    ZStack {
        Color.black.ignoresSafeArea()
        CardTwoView()
    }
}
