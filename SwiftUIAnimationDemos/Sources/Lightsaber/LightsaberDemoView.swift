//
//  AnimationDemos.swift
//  DemoView
//
//  Created by James Rochabrun on 12/10/25.
//

import SwiftUI

// MARK: - Lightsaber Animation Demo

/// An interactive lightsaber view with Metal shader-powered effects.
/// Features ignition animation, plasma core glow, ambient lighting, and touch interaction.
struct LightsaberView: View {
  // MARK: - Configuration
  
  enum SaberColor: CaseIterable {
    case blue, green, red, purple, yellow, white
    
    var core: Color {
      switch self {
      case .blue: return Color(red: 0.7, green: 0.85, blue: 1.0)
      case .green: return Color(red: 0.7, green: 1.0, blue: 0.7)
      case .red: return Color(red: 1.0, green: 0.7, blue: 0.7)
      case .purple: return Color(red: 0.9, green: 0.7, blue: 1.0)
      case .yellow: return Color(red: 1.0, green: 1.0, blue: 0.7)
      case .white: return Color(red: 1.0, green: 1.0, blue: 1.0)
      }
    }
    
    var glow: Color {
      switch self {
      case .blue: return Color(red: 0.2, green: 0.5, blue: 1.0)
      case .green: return Color(red: 0.2, green: 1.0, blue: 0.3)
      case .red: return Color(red: 1.0, green: 0.1, blue: 0.1)
      case .purple: return Color(red: 0.7, green: 0.2, blue: 1.0)
      case .yellow: return Color(red: 1.0, green: 0.9, blue: 0.2)
      case .white: return Color(red: 0.9, green: 0.95, blue: 1.0)
      }
    }
    
    var name: String {
      switch self {
      case .blue: return "Jedi Blue"
      case .green: return "Guardian Green"
      case .red: return "Sith Red"
      case .purple: return "Mace Purple"
      case .yellow: return "Temple Guard"
      case .white: return "Purified"
      }
    }
  }
  
  // MARK: - State
  
  @State private var isIgnited = false
  @State private var extensionProgress: CGFloat = 0
  @State private var selectedColor: SaberColor = .blue
  @State private var startTime = Date.now
  @State private var showFlash = false
  @State private var flashProgress: CGFloat = 0
  @State private var hiltPosition: CGPoint = .zero
  @State private var bladeLength: CGFloat = 400
  
  // MARK: - Body
  
  var body: some View {
    GeometryReader { geometry in
      ZStack {
        // Background with ambient glow
        backgroundLayer(size: geometry.size)
        
        // Lightsaber
        VStack(spacing: 0) {
          // Blade
          bladeView(size: geometry.size)
          
          // Hilt
          hiltView
        }
        .position(x: geometry.size.width / 2, y: geometry.size.height / 2 + 50)
        
        // Ignition flash overlay
        if showFlash {
          ignitionFlashOverlay(size: geometry.size)
        }
        
        // Color selector
        colorSelector
          .position(x: geometry.size.width / 2, y: geometry.size.height - 100)
        
        // Power button hint
        if !isIgnited {
          Text("Tap the hilt to ignite")
            .font(.caption)
            .foregroundStyle(.white.opacity(0.6))
            .position(x: geometry.size.width / 2, y: geometry.size.height - 160)
        }
      }
    }
    .background(Color.black)
    .ignoresSafeArea()
  }
  
  // MARK: - Background Layer

  @ViewBuilder
  private func backgroundLayer(size: CGSize) -> some View {
    TimelineView(.animation) { timeline in
      let time = startTime.distance(to: timeline.date)

      // GPU-powered ambient glow using Metal shader
      Rectangle()
        .fill(Color.black)
        .frame(width: size.width, height: size.height)
        .visualEffect { content, proxy in
          content
            .colorEffect(
              ShaderLibrary.lightsaberAmbient(
                .float2(proxy.size),
                .float2(CGPoint(
                  x: proxy.size.width / 2,
                  y: proxy.size.height / 2 - bladeLength * extensionProgress / 2 + 50
                )),
                .color(selectedColor.glow),
                .float(350 * extensionProgress), // radius
                .float(isIgnited ? 0.25 * extensionProgress : 0), // intensity
                .float(time)
              ),
              isEnabled: isIgnited && extensionProgress > 0.1
            )
        }
    }
  }
  
  // MARK: - Blade View

  @ViewBuilder
  private func bladeView(size: CGSize) -> some View {
    TimelineView(.animation) { timeline in
      let time = startTime.distance(to: timeline.date)

      // The blade is rendered as a rectangle that the Metal shader processes
      // The shader creates all the glow layers, core, and energy effects on the GPU
      BladeShape()
        .fill(.white) // Base fill - shader will override colors
        .frame(width: 80, height: bladeLength) // Wider to allow for glow
        .drawingGroup()
        .visualEffect { content, proxy in
          content
            // Primary lightsaber core effect - creates the plasma blade with glow
            .layerEffect(
              ShaderLibrary.lightsaberCore(
                .float2(proxy.size),
                .color(selectedColor.core),
                .color(selectedColor.glow),
                .float(0.15), // bladeWidth (relative to view width)
                .float(1.5),  // glowIntensity
                .float(time)
              ),
              maxSampleOffset: .zero,
              isEnabled: isIgnited
            )
            // Plasma energy turbulence overlay
            .layerEffect(
              ShaderLibrary.plasmaEnergy(
                .float2(proxy.size),
                .color(selectedColor.core),
                .color(selectedColor.glow),
                .float(time),
                .float(0.4) // turbulence
              ),
              maxSampleOffset: .zero,
              isEnabled: isIgnited
            )
            // Heat shimmer distortion around the blade
            .distortionEffect(
              ShaderLibrary.lightsaberDistortion(
                .float2(proxy.size),
                .float(time),
                .float(0.2),  // bladeWidth
                .float(isIgnited ? 1.5 : 0) // intensity
              ),
              maxSampleOffset: CGSize(width: 10, height: 10),
              isEnabled: isIgnited
            )
            // Subtle humming vibration
            .distortionEffect(
              ShaderLibrary.hummingVibration(
                .float2(proxy.size),
                .float(time),
                .float(isIgnited ? 0.3 : 0)
              ),
              maxSampleOffset: CGSize(width: 2, height: 2),
              isEnabled: isIgnited
            )
        }
        .scaleEffect(y: extensionProgress, anchor: .bottom)
        .opacity(extensionProgress)
    }
  }
  
  // MARK: - Blade Shape
  
  struct BladeShape: Shape {
    func path(in rect: CGRect) -> Path {
      var path = Path()
      
      let tipRadius = rect.width / 2
      
      // Start at bottom left
      path.move(to: CGPoint(x: rect.midX - rect.width / 2, y: rect.maxY))
      
      // Left side up to tip
      path.addLine(to: CGPoint(x: rect.midX - rect.width / 2, y: rect.minY + tipRadius))
      
      // Rounded tip
      path.addArc(
        center: CGPoint(x: rect.midX, y: rect.minY + tipRadius),
        radius: tipRadius,
        startAngle: .degrees(180),
        endAngle: .degrees(0),
        clockwise: false
      )
      
      // Right side down
      path.addLine(to: CGPoint(x: rect.midX + rect.width / 2, y: rect.maxY))
      
      // Close path
      path.closeSubpath()
      
      return path
    }
  }
  
  // MARK: - Hilt View
  
  private var hiltView: some View {
    ZStack {
      // Main hilt body
      RoundedRectangle(cornerRadius: 4)
        .fill(
          LinearGradient(
            colors: [
              Color(white: 0.4),
              Color(white: 0.25),
              Color(white: 0.3),
              Color(white: 0.2)
            ],
            startPoint: .leading,
            endPoint: .trailing
          )
        )
        .frame(width: 24, height: 120)
      
      // Grip details
      VStack(spacing: 6) {
        ForEach(0..<8, id: \.self) { _ in
          RoundedRectangle(cornerRadius: 1)
            .fill(Color(white: 0.15))
            .frame(width: 20, height: 3)
        }
      }
      .offset(y: 10)
      
      // Emitter (top of hilt)
      VStack(spacing: 0) {
        // Emitter shroud
        Capsule()
          .fill(
            LinearGradient(
              colors: [
                Color(white: 0.5),
                Color(white: 0.3)
              ],
              startPoint: .leading,
              endPoint: .trailing
            )
          )
          .frame(width: 28, height: 12)
        
        // Inner emitter (glows when ignited)
        Circle()
          .fill(isIgnited ? selectedColor.glow : Color(white: 0.1))
          .frame(width: 16, height: 16)
          .shadow(
            color: isIgnited ? selectedColor.glow : .clear,
            radius: isIgnited ? 10 : 0
          )
          .offset(y: -8)
      }
      .offset(y: -60)
      
      // Power button
      Circle()
        .fill(
          RadialGradient(
            colors: [
              isIgnited ? selectedColor.glow : Color.red.opacity(0.8),
              isIgnited ? selectedColor.glow.opacity(0.5) : Color.red.opacity(0.3)
            ],
            center: .center,
            startRadius: 0,
            endRadius: 6
          )
        )
        .frame(width: 12, height: 12)
        .shadow(
          color: isIgnited ? selectedColor.glow : .red,
          radius: 4
        )
        .offset(x: 10, y: -20)
      
      // Pommel (bottom)
      RoundedRectangle(cornerRadius: 3)
        .fill(Color(white: 0.35))
        .frame(width: 20, height: 15)
        .offset(y: 55)
    }
    .shadow(color: .black.opacity(0.5), radius: 5, x: 2, y: 2)
    .onTapGesture {
      toggleIgnition()
    }
  }
  
  // MARK: - Ignition Flash Overlay

  @ViewBuilder
  private func ignitionFlashOverlay(size: CGSize) -> some View {
    // GPU-powered ignition flash using Metal shader
    Rectangle()
      .fill(.clear)
      .frame(width: size.width, height: size.height)
      .visualEffect { content, proxy in
        content
          .colorEffect(
            ShaderLibrary.ignitionFlash(
              .float2(proxy.size),
              .float2(CGPoint(x: proxy.size.width / 2, y: proxy.size.height / 2 + 20)),
              .float(flashProgress),
              .color(selectedColor.core),
              .float(max(proxy.size.width, proxy.size.height) * 0.8)
            )
          )
      }
  }
  
  // MARK: - Color Selector
  
  private var colorSelector: some View {
    HStack(spacing: 16) {
      ForEach(SaberColor.allCases, id: \.name) { color in
        Button {
          withAnimation(.spring(response: 0.3)) {
            selectedColor = color
          }
        } label: {
          Circle()
            .fill(color.glow)
            .frame(width: selectedColor == color ? 40 : 30, height: selectedColor == color ? 40 : 30)
            .shadow(color: color.glow.opacity(0.8), radius: selectedColor == color ? 10 : 5)
            .overlay {
              if selectedColor == color {
                Circle()
                  .stroke(Color.white, lineWidth: 2)
              }
            }
        }
      }
    }
    .padding(.horizontal, 20)
    .padding(.vertical, 12)
    .background(
      RoundedRectangle(cornerRadius: 25)
        .fill(Color.white.opacity(0.1))
        .blur(radius: 1)
    )
  }
  
  // MARK: - Actions
  
  private func toggleIgnition() {
    if isIgnited {
      // Retract blade
      withAnimation(.easeIn(duration: 0.2)) {
        extensionProgress = 0
      }
      DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
        isIgnited = false
      }
    } else {
      // Ignite!
      isIgnited = true
      showFlash = true
      flashProgress = 0
      
      // Flash animation
      withAnimation(.easeOut(duration: 0.4)) {
        flashProgress = 1
      }
      
      // Blade extension
      withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
        extensionProgress = 1
      }
      
      // Hide flash
      DispatchQueue.main.asyncAfter(deadline: .now() + 0.4) {
        showFlash = false
      }
    }
  }
}

// MARK: - Preview

#Preview {
  LightsaberView()
}
