import SwiftUI

/// Native update prompt shown when the backend reports a newer iOS version.
///
/// - `isForced == true`  → blocking: only "Aggiorna ora", no "Più tardi".
///   The presenter must also disable interactive dismissal.
/// - `isForced == false` → soft: "Aggiorna ora" + "Più tardi".
struct AppUpdateSheet: View {
    let config: AppVersionConfig
    let isForced: Bool
    let onUpdate: () -> Void
    var onLater: (() -> Void)? = nil

    @Environment(\.dismiss) private var dismiss

    private var title: String {
        isForced ? "Aggiornamento richiesto" : "Aggiornamento disponibile"
    }

    private var message: String {
        if let m = config.message, !m.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            return m
        }
        return isForced
            ? "Per continuare a usare Ditelo sui Tetti è necessario aggiornare all'ultima versione."
            : "È disponibile una nuova versione di Ditelo sui Tetti."
    }

    var body: some View {
        VStack(spacing: 0) {
            Spacer(minLength: 24)

            Image(systemName: "arrow.up.circle.fill")
                .font(.system(size: 56))
                .foregroundStyle(.brandRed)
                .accessibilityHidden(true)
                .padding(.bottom, 20)

            Text(title)
                .font(.system(size: 22, weight: .bold))
                .foregroundStyle(.brandBlack)
                .multilineTextAlignment(.center)
                .kerning(-0.3)
                .padding(.horizontal, 28)

            Text(message)
                .font(.system(size: 16))
                .foregroundStyle(.brandGray)
                .multilineTextAlignment(.center)
                .lineSpacing(4)
                .fixedSize(horizontal: false, vertical: true)
                .padding(.horizontal, 28)
                .padding(.top, 10)

            if let latest = config.latestVersion {
                Text("Versione \(latest)")
                    .font(.system(size: 13, weight: .medium))
                    .foregroundStyle(.brandGrayLight)
                    .padding(.top, 8)
            }

            Spacer(minLength: 24)

            VStack(spacing: 12) {
                Button(action: onUpdate) {
                    Text("Aggiorna ora")
                        .font(.system(size: 17, weight: .semibold))
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 6)
                }
                .buttonStyle(.borderedProminent)
                .tint(.brandRed)
                .controlSize(.large)
                .accessibilityLabel("Aggiorna ora dall'App Store")

                if !isForced {
                    Button {
                        (onLater ?? {})()
                        dismiss()
                    } label: {
                        Text("Più tardi")
                            .font(.system(size: 16, weight: .medium))
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 4)
                    }
                    .buttonStyle(.plain)
                    .foregroundStyle(.brandGray)
                    .accessibilityLabel("Rimanda l'aggiornamento")
                }
            }
            .padding(.horizontal, 28)
            .padding(.bottom, 28)
        }
        .frame(maxWidth: .infinity)
        .background(.brandCream)
        .presentationDragIndicator(isForced ? .hidden : .visible)
        .interactiveDismissDisabled(isForced)
    }
}

#Preview("Soft update") {
    Color.black.opacity(0.2).ignoresSafeArea()
        .sheet(isPresented: .constant(true)) {
            AppUpdateSheet(
                config: AppVersionConfig(
                    latestVersion: "1.0.4",
                    minimumVersion: "1.0.2",
                    appStoreURL: URL(string: "https://apps.apple.com/app/id000000000"),
                    message: "È disponibile una nuova versione di Ditelo sui Tetti."
                ),
                isForced: false,
                onUpdate: {},
                onLater: {}
            )
            .presentationDetents([.medium])
        }
}

#Preview("Forced update") {
    Color.black.opacity(0.2).ignoresSafeArea()
        .sheet(isPresented: .constant(true)) {
            AppUpdateSheet(
                config: AppVersionConfig(
                    latestVersion: "1.0.4",
                    minimumVersion: "1.0.2",
                    appStoreURL: URL(string: "https://apps.apple.com/app/id000000000"),
                    message: nil
                ),
                isForced: true,
                onUpdate: {}
            )
        }
}
