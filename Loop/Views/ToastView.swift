import Combine
import SwiftUI

@MainActor
final class ToastStore: ObservableObject {
    static let shared = ToastStore()

    @Published private(set) var message: String?
    @Published private(set) var isVisible = false

    private var dismissTask: Task<Void, Never>?

    func show(_ message: String) {
        print("[Loop] Toast: \(message)")
        dismissTask?.cancel()
        self.message = message
        withAnimation(.easeOut(duration: 0.3)) {
            isVisible = true
        }
        dismissTask = Task { @MainActor in
            try? await Task.sleep(for: .seconds(4))
            guard !Task.isCancelled else { return }
            dismiss()
        }
    }

    func dismiss() {
        dismissTask?.cancel()
        withAnimation(.easeIn(duration: 0.25)) {
            isVisible = false
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.25) { [weak self] in
            self?.message = nil
        }
    }
}

struct ToastView: View {
    let message: String
    let onDismiss: () -> Void

    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: "exclamationmark.triangle.fill")
                .font(.title3)
                .foregroundColor(Color.orange)

            Text(message)
                .font(SpotifyDesign.captionFont())
                .foregroundColor(.white)
                .multilineTextAlignment(.leading)
                .lineLimit(3)

            Spacer(minLength: 8)

            Button {
                onDismiss()
            } label: {
                Image(systemName: "xmark")
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundColor(SpotifyDesign.muted)
                    .frame(width: 28, height: 28)
            }
        }
        .padding(.horizontal, 18)
        .padding(.vertical, 14)
        .background(
            RoundedRectangle(cornerRadius: SpotifyDesign.overlayCornerRadius, style: .continuous)
                .fill(SpotifyDesign.glassMaterialElevated)
                .overlay(
                    RoundedRectangle(cornerRadius: SpotifyDesign.overlayCornerRadius, style: .continuous)
                        .stroke(Color.white.opacity(0.15), lineWidth: 1)
                )
                .shadow(color: .black.opacity(0.4), radius: 16, y: 6)
        )
        .padding(.horizontal, 20)
    }
}

struct ToastOverlay: View {
    @ObservedObject var toastStore: ToastStore

    var body: some View {
        VStack {
            if toastStore.isVisible, let message = toastStore.message {
                ToastView(message: message) {
                    toastStore.dismiss()
                }
                .transition(.asymmetric(
                    insertion: .move(edge: .top).combined(with: .opacity),
                    removal: .move(edge: .top).combined(with: .opacity)
                ))
                .padding(.top, 8)
                .zIndex(100)
            }
            Spacer()
        }
        .allowsHitTesting(toastStore.isVisible)
    }
}
