//
//  Bubble.swift
//  DemoView
//

import SwiftUI
import Combine

struct BubbleButton: View {
  let action: () -> Void
  
  @State private var isPressed = false
  @State private var ripples: [Ripple] = []
  @State private var animationTime: Float = 0
  
  private let size: CGFloat = 120
  private let timer = Timer.publish(every: 1/60, on: .main, in: .common).autoconnect()
  
  var body: some View {
    ZStack {
      // Ripple effects
      ForEach(ripples) { ripple in
        Circle()
          .stroke(
            LinearGradient(
              colors: [
                .white.opacity(0.6),
                .cyan.opacity(0.3),
                .clear
              ],
              startPoint: .topLeading,
              endPoint: .bottomTrailing
            ),
            lineWidth: 2
          )
          .frame(width: ripple.size, height: ripple.size)
          .opacity(ripple.opacity)
      }
      
      // Main bubble - composited as single layer
      Canvas { context, canvasSize in
        let rect = CGRect(origin: .zero, size: canvasSize)
        let center = CGPoint(x: rect.midX, y: rect.midY)
        let radius = min(rect.width, rect.height) / 2 - 10
        
        // Base bubble fill
        let bubblePath = Path(ellipseIn: CGRect(
          x: center.x - radius,
          y: center.y - radius,
          width: radius * 2,
          height: radius * 2
        ))
        
        // Radial gradient fill
        context.fill(
          bubblePath,
          with: .radialGradient(
            Gradient(colors: [
              .white.opacity(0.3),
              .cyan.opacity(0.2),
              .blue.opacity(0.15),
              .purple.opacity(0.1)
            ]),
            center: CGPoint(x: center.x - radius * 0.3, y: center.y - radius * 0.3),
            startRadius: 0,
            endRadius: radius * 1.5
          )
        )
        
        // Glass rim
        context.stroke(
          bubblePath,
          with: .linearGradient(
            Gradient(colors: [
              .white.opacity(0.9),
              .white.opacity(0.3),
              .white.opacity(0.2),
              .white.opacity(0.6)
            ]),
            startPoint: CGPoint(x: center.x - radius, y: center.y - radius),
            endPoint: CGPoint(x: center.x + radius, y: center.y + radius)
          ),
          lineWidth: 2.5
        )
        
        // Top highlight
        let highlightPath = Path(ellipseIn: CGRect(
          x: center.x - radius * 0.35,
          y: center.y - radius * 0.85,
          width: radius * 0.7,
          height: radius * 0.35
        ))
        context.fill(
          highlightPath,
          with: .linearGradient(
            Gradient(colors: [
              .white.opacity(0.9),
              .white.opacity(0.3),
              .clear
            ]),
            startPoint: CGPoint(x: center.x, y: center.y - radius * 0.85),
            endPoint: CGPoint(x: center.x, y: center.y - radius * 0.5)
          )
        )
        
        // Small specular
        let specularPath = Path(ellipseIn: CGRect(
          x: center.x - radius * 0.55,
          y: center.y - radius * 0.75,
          width: radius * 0.2,
          height: radius * 0.1
        ))
        context.fill(specularPath, with: .color(.white.opacity(0.7)))
        
        // Bottom reflection
        let bottomPath = Path(ellipseIn: CGRect(
          x: center.x - radius * 0.3,
          y: center.y + radius * 0.5,
          width: radius * 0.6,
          height: radius * 0.25
        ))
        context.fill(
          bottomPath,
          with: .linearGradient(
            Gradient(colors: [
              .clear,
              .white.opacity(0.15),
              .white.opacity(0.25)
            ]),
            startPoint: CGPoint(x: center.x, y: center.y + radius * 0.5),
            endPoint: CGPoint(x: center.x, y: center.y + radius * 0.75)
          )
        )
      }
      .frame(width: size + 20, height: size + 20)
      // Apply shaders to the composited canvas
      .colorEffect(
        ShaderLibrary.iridescentShimmer(
          .float2(size + 20, size + 20),
          .float(animationTime)
        )
      )
      .colorEffect(
        ShaderLibrary.bubbleHighlight(
          .float2(size + 20, size + 20),
          .float(animationTime)
        )
      )
      .distortionEffect(
        ShaderLibrary.liquidDistortion(
          .float2(size + 20, size + 20),
          .float(animationTime),
          .float(isPressed ? 0.012 : 0.004)
        ),
        maxSampleOffset: CGSize(width: 15, height: 15)
      )
      .shadow(color: .cyan.opacity(0.4), radius: 25, x: 0, y: 10)
      .shadow(color: .purple.opacity(0.3), radius: 35, x: 0, y: 15)
      .scaleEffect(isPressed ? 0.92 : 1.0)
    }
    .frame(width: size * 2, height: size * 2)
    .contentShape(Circle())
    .onTapGesture {
      triggerRipple()
      action()
    }
    .onLongPressGesture(minimumDuration: .infinity, pressing: { pressing in
      withAnimation(.spring(response: 0.3, dampingFraction: 0.6)) {
        isPressed = pressing
      }
      if pressing {
        triggerRipple()
      }
    }, perform: {})
    .onReceive(timer) { _ in
      animationTime += 1/60
    }
  }
  
  private func triggerRipple() {
    let ripple = Ripple()
    ripples.append(ripple)
    
    withAnimation(.easeOut(duration: 0.8)) {
      if let index = ripples.firstIndex(where: { $0.id == ripple.id }) {
        ripples[index].size = size * 2.5
        ripples[index].opacity = 0
      }
    }
    
    DispatchQueue.main.asyncAfter(deadline: .now() + 0.8) {
      ripples.removeAll { $0.id == ripple.id }
    }
  }
}

struct Ripple: Identifiable {
  let id = UUID()
  var size: CGFloat = 120
  var opacity: Double = 0.8
}

// MARK: - Glass Capsule Button (Refractive)

struct GlassCapsuleButton: View {
  let title: String
  let action: () -> Void

  @State private var isPressed = false
  @State private var animationTime: Float = 0

  private let height: CGFloat = 54
  private let horizontalPadding: CGFloat = 48
  private let timer = Timer.publish(every: 1/60, on: .main, in: .common).autoconnect()

  var body: some View {
    // The text sits on a clear background that gets the glass effect
    Text(title)
      .font(.system(size: 17, weight: .semibold, design: .rounded))
      .foregroundStyle(.white)
      .padding(.horizontal, horizontalPadding)
      .padding(.vertical, 16)
      .background {
        // Capsule shape that will receive the glass shader
        Capsule()
          .fill(.clear)
          .overlay {
            // We need visible content for the shader to work on
            Capsule()
              .fill(
                LinearGradient(
                  colors: [
                    .white.opacity(0.15),
                    .white.opacity(0.05)
                  ],
                  startPoint: .topLeading,
                  endPoint: .bottomTrailing
                )
              )
          }
          .overlay {
            // Rim stroke
            Capsule()
              .strokeBorder(
                LinearGradient(
                  colors: [
                    .white.opacity(0.6),
                    .white.opacity(0.2),
                    .white.opacity(0.1),
                    .white.opacity(0.4)
                  ],
                  startPoint: .topLeading,
                  endPoint: .bottomTrailing
                ),
                lineWidth: 1.5
              )
          }
          .overlay {
            // Top highlight
            Capsule()
              .fill(
                LinearGradient(
                  colors: [
                    .white.opacity(0.4),
                    .white.opacity(0.1),
                    .clear,
                    .clear
                  ],
                  startPoint: .top,
                  endPoint: .bottom
                )
              )
              .padding(3)
              .mask {
                VStack {
                  Rectangle().frame(height: 20)
                  Spacer()
                }
              }
          }
          .overlay {
            // Specular dot
            Circle()
              .fill(.white.opacity(0.5))
              .frame(width: 8, height: 4)
              .scaleEffect(x: 1.5, y: 1)
              .blur(radius: 1)
              .offset(x: -30, y: -12)
          }
      }
      .shadow(color: .black.opacity(0.4), radius: 15, x: 0, y: 8)
      .shadow(color: .cyan.opacity(0.15), radius: 20, x: 0, y: 5)
      .scaleEffect(isPressed ? 0.96 : 1.0)
      .contentShape(Capsule())
      .onTapGesture {
        action()
      }
      .onLongPressGesture(minimumDuration: .infinity, pressing: { pressing in
        withAnimation(.spring(response: 0.25, dampingFraction: 0.7)) {
          isPressed = pressing
        }
      }, perform: {})
      .onReceive(timer) { _ in
        animationTime += 1/60
      }
  }
}

// Glass modifier that applies refractive effect to content behind it
struct GlassButtonModifier: ViewModifier {
  let size: CGSize
  let time: Float

  func body(content: Content) -> some View {
    content
      .layerEffect(
        ShaderLibrary.glassButton(
          .float2(size.width, size.height),
          .float(time)
        ),
        maxSampleOffset: CGSize(width: 50, height: 50)
      )
  }
}

// MARK: - Bubble Demo View

struct BubbleDemoView: View {
  var body: some View {
    ZStack {
      // Gradient background with some visual interest for refraction
      LinearGradient(
        colors: [
          Color(red: 0.08, green: 0.06, blue: 0.15),
          Color(red: 0.05, green: 0.08, blue: 0.18),
          Color(red: 0.1, green: 0.05, blue: 0.12)
        ],
        startPoint: .topLeading,
        endPoint: .bottomTrailing
      )
      .ignoresSafeArea()

      // Some background elements to show refraction
      VStack(spacing: 100) {
        Circle()
          .fill(
            RadialGradient(
              colors: [.purple.opacity(0.3), .clear],
              center: .center,
              startRadius: 0,
              endRadius: 150
            )
          )
          .frame(width: 300, height: 300)
          .blur(radius: 40)
          .offset(x: -80, y: -50)

        Circle()
          .fill(
            RadialGradient(
              colors: [.cyan.opacity(0.25), .clear],
              center: .center,
              startRadius: 0,
              endRadius: 120
            )
          )
          .frame(width: 250, height: 250)
          .blur(radius: 30)
          .offset(x: 60, y: 0)
      }

      VStack(spacing: 24) {
        Spacer()

        BubbleButton {
          print("Bubble tapped!")
        }

        Spacer()

        VStack(spacing: 14) {
          GlassCapsuleButton(title: "Reserve") {
            print("Reserve tapped!")
          }

          GlassCapsuleButton(title: "Get Started") {
            print("Get Started tapped!")
          }

          GlassCapsuleButton(title: "Continue") {
            print("Continue tapped!")
          }
        }

        Spacer()
      }
    }
  }
}

// MARK: - Preview

#Preview {
  BubbleDemoView()
}
