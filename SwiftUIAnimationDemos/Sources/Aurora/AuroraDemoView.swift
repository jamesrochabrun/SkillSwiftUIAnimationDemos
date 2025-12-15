import SwiftUI

// MARK: - Aurora Demo View
struct AuroraDemoView: View {
    @State private var animationSpec: AnimationSpec?
    @State private var loadError: String?

    var body: some View {
        Group {
            if let spec = animationSpec {
                AuroraAnimationView(spec: spec)
                    .ignoresSafeArea()
            } else if let error = loadError {
                errorView(error: error)
            } else {
                loadingView
            }
        }
        .onAppear {
            loadAnimationSpec()
        }
    }

    private var loadingView: some View {
        ZStack {
            Color(hex: "#0A0A1A")
                .ignoresSafeArea()
            ProgressView()
                .progressViewStyle(CircularProgressViewStyle(tint: .white))
                .scaleEffect(1.5)
        }
    }

    private func errorView(error: String) -> some View {
        ZStack {
            Color(hex: "#0A0A1A")
                .ignoresSafeArea()
            VStack(spacing: 16) {
                Image(systemName: "exclamationmark.triangle.fill")
                    .font(.system(size: 50))
                    .foregroundColor(.orange)
                Text("Failed to load animation")
                    .font(.headline)
                    .foregroundColor(.white)
                Text(error)
                    .font(.caption)
                    .foregroundColor(.gray)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal)
            }
        }
    }

    private func loadAnimationSpec() {
        guard let url = Bundle.main.url(
            forResource: "animation-spec",
            withExtension: "json"
        ) else {
            loadError = "Could not find animation-spec.json in bundle"
            return
        }

        do {
            let data = try Data(contentsOf: url)
            let decoder = JSONDecoder()
            animationSpec = try decoder.decode(AnimationSpec.self, from: data)
        } catch {
            loadError = error.localizedDescription
        }
    }
}

// MARK: - Preview
#Preview {
    AuroraDemoView()
}
