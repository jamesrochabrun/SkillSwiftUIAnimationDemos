//
//  MotionManager.swift
//  SwiftUIAnimationDemos
//
//  Shared motion manager for gyroscope-based tilt effects
//

import SwiftUI
import CoreMotion

@Observable
final class MotionManager {
    var tilt: CGPoint = .zero

    private let motionManager = CMMotionManager()
    private let queue = OperationQueue()

    var isAvailable: Bool {
        motionManager.isDeviceMotionAvailable
    }

    func start() {
        guard motionManager.isDeviceMotionAvailable else { return }

        motionManager.deviceMotionUpdateInterval = 1.0 / 60.0
        motionManager.startDeviceMotionUpdates(to: queue) { [weak self] motion, _ in
            guard let motion = motion else { return }

            DispatchQueue.main.async {
                // Use attitude for smooth tilt values
                let pitch = motion.attitude.pitch // Forward/backward tilt
                let roll = motion.attitude.roll   // Left/right tilt

                // Normalize to -1 to 1 range, clamped
                self?.tilt = CGPoint(
                    x: max(-1, min(1, roll / .pi * 2)),
                    y: max(-1, min(1, pitch / .pi * 2))
                )
            }
        }
    }

    func stop() {
        motionManager.stopDeviceMotionUpdates()
    }
}
