//
//  HolographicCardContainer.swift
//  SwiftUIAnimationDemos
//
//  Reusable container for holographic cards with drag/tilt/rotation behavior
//

import SwiftUI

struct HolographicCardContainer<Content: View>: View {
    let width: CGFloat
    let height: CGFloat
    let cornerRadius: CGFloat
    let shadowColor: Color
    let rotationMultiplier: Double
    @ViewBuilder let content: (_ tilt: CGPoint, _ elapsedTime: TimeInterval) -> Content

    @State private var motionManager = MotionManager()
    @State private var startTime = Date.now
    @State private var dragOffset: CGSize = .zero

    init(
        width: CGFloat,
        height: CGFloat,
        cornerRadius: CGFloat = 16,
        shadowColor: Color = .black,
        rotationMultiplier: Double = 15,
        @ViewBuilder content: @escaping (_ tilt: CGPoint, _ elapsedTime: TimeInterval) -> Content
    ) {
        self.width = width
        self.height = height
        self.cornerRadius = cornerRadius
        self.shadowColor = shadowColor
        self.rotationMultiplier = rotationMultiplier
        self.content = content
    }

    var body: some View {
        TimelineView(.animation) { timeline in
            let elapsedTime = startTime.distance(to: timeline.date)
            let effectiveTilt = CGPoint(
                x: motionManager.tilt.x + dragOffset.width / 100,
                y: motionManager.tilt.y + dragOffset.height / 100
            )

            content(effectiveTilt, elapsedTime)
                .frame(width: width, height: height)
                .clipShape(RoundedRectangle(cornerRadius: cornerRadius))
                .rotation3DEffect(
                    .degrees(effectiveTilt.x * rotationMultiplier),
                    axis: (x: 0, y: 1, z: 0),
                    perspective: 0.5
                )
                .rotation3DEffect(
                    .degrees(-effectiveTilt.y * rotationMultiplier),
                    axis: (x: 1, y: 0, z: 0),
                    perspective: 0.5
                )
                .shadow(
                    color: shadowColor.opacity(0.5),
                    radius: 20,
                    x: CGFloat(effectiveTilt.x * 10),
                    y: CGFloat(effectiveTilt.y * 10)
                )
                .gesture(
                    DragGesture()
                        .onChanged { value in
                            withAnimation(.interactiveSpring) {
                                dragOffset = value.translation
                            }
                        }
                        .onEnded { _ in
                            withAnimation(.spring(response: 0.5, dampingFraction: 0.6)) {
                                dragOffset = .zero
                            }
                        }
                )
        }
        .onAppear { motionManager.start() }
        .onDisappear { motionManager.stop() }
    }
}
