//
//  ContentView.swift
//  SwiftUIAnimationDemos
//

import SwiftUI

struct ContentView: View {
    var body: some View {
        NavigationStack {
            List(AnimationDemo.allCases) { demo in
                NavigationLink(value: demo) {
                    HStack(spacing: 16) {
                        Image(systemName: demo.icon)
                            .font(.title2)
                            .foregroundStyle(.blue)
                            .frame(width: 40)

                        VStack(alignment: .leading, spacing: 4) {
                            Text(demo.title)
                                .font(.headline)
                            Text(demo.subtitle)
                                .font(.caption)
                                .foregroundStyle(.secondary)
                                .lineLimit(2)
                        }
                    }
                    .padding(.vertical, 8)
                }
            }
            .navigationTitle("Animation Demos")
            .navigationDestination(for: AnimationDemo.self) { demo in
                demo.destination
                    .navigationTitle(demo.title)
                    .navigationBarTitleDisplayMode(.inline)
            }
        }
    }
}

#Preview {
    ContentView()
}
