//
//  HologramDemoView.swift
//  SwiftUIAnimationDemos
//
//  Demo view showcasing holographic card collection
//

import SwiftUI

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
                    CardOneView()
                        .tag(0)

                    CardTwoView()
                        .tag(1)

                    CardThreeView()
                        .tag(2)
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
