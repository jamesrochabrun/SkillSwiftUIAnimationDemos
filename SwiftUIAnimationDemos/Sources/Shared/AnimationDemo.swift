//
//  AnimationDemo.swift
//  SwiftUIAnimationDemos
//

import SwiftUI

enum AnimationDemo: String, CaseIterable, Identifiable {
    case hologram = "Hologram"
    case lightsaber = "Lightsaber"
    case bubble = "Bubble"
    case magnifyingGlass = "Magnifying Glass"
    case thermostat = "Thermostat"
    case aurora = "Aurora"

    var id: String { rawValue }

    var title: String { rawValue }

    var subtitle: String {
        switch self {
        case .hologram:
            return "Pokemon-style holographic card with motion-reactive Metal shaders"
        case .lightsaber:
            return "Interactive lightsaber with plasma core and ignition effects"
        case .bubble:
            return "Glassy bubble button with iridescent shimmer"
        case .magnifyingGlass:
            return "Refractive glass magnifying effect with chromatic aberration"
        case .thermostat:
            return "Interactive thermometer with plasma energy shaders"
        case .aurora:
            return "Data-driven aurora animation with waves and floating orbs"
        }
    }

    var icon: String {
        switch self {
        case .hologram: return "sparkles.rectangle.stack"
        case .lightsaber: return "wand.and.rays"
        case .bubble: return "drop.circle"
        case .magnifyingGlass: return "magnifyingglass"
        case .thermostat: return "thermometer.medium"
        case .aurora: return "sparkles"
        }
    }

    @ViewBuilder
    var destination: some View {
        switch self {
        case .hologram:
            HologramDemoView()
        case .lightsaber:
            LightsaberView()
        case .bubble:
            BubbleDemoView()
        case .magnifyingGlass:
            MagnifyingGlassDemoView()
        case .thermostat:
            TemperatureAnimationView()
        case .aurora:
            AuroraDemoView()
        }
    }
}
