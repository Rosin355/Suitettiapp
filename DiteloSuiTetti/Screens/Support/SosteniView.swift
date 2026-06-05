import SwiftUI
import UserNotifications

struct SosteniView: View {
    @State private var showDiagnostics = false

    private let ways: [(icon: String, title: String, detail: String)] = [
        (icon: "🤝", title: "Diventa associazione aderente",
         detail: "La tua associazione può entrare nella rete e contribuire alla voce comune."),
        (icon: "📣", title: "Condividi sui social",
         detail: "Amplifica il messaggio: condividi i nostri contenuti e usa #DitelosuiTetti."),
        (icon: "📰", title: "Scrivi e pubblica",
         detail: "Contribuisci con articoli e riflessioni sul bene comune, la famiglia e l'educazione."),
        (icon: "📅", title: "Organizza un evento",
         detail: "Organizza un presidio, un incontro o un'assemblea nella tua città."),
    ]

    var body: some View {
        ScrollView {
            VStack(spacing: 0) {
                SupportHeroSection()
                SupportActionsSection(ways: ways)
                NotificationStatusSection()
            }
        }
        .scrollIndicators(.hidden)
        .background(.brandCream)
        .navigationBarTitleDisplayMode(.large)
        .toolbarBackground(.brandCream, for: .navigationBar)
        .toolbarColorScheme(.light, for: .navigationBar)
        .onTapGesture(count: 5) { showDiagnostics = true }
        .sheet(isPresented: $showDiagnostics) { SyncDiagnosticsView() }
    }
}

// MARK: - Notification status row

private struct NotificationStatusSection: View {
    @State private var status: UNAuthorizationStatus = .notDetermined

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            Text("Impostazioni")
                .font(.system(size: 12, weight: .medium))
                .foregroundStyle(.brandGray)
                .kerning(1.5)
                .textCase(.uppercase)
                .padding(.horizontal, 20)
                .padding(.bottom, 10)

            HStack(spacing: 14) {
                RoundedRectangle(cornerRadius: 13)
                    .fill(iconColor.opacity(0.1))
                    .frame(width: 44, height: 44)
                    .overlay {
                        Image(systemName: iconName)
                            .font(.system(size: 18, weight: .semibold))
                            .foregroundStyle(iconColor)
                    }
                    .accessibilityHidden(true)

                VStack(alignment: .leading, spacing: 3) {
                    Text("Notifiche")
                        .font(.system(size: 16, weight: .bold))
                        .foregroundStyle(.brandBlack)
                        .kerning(-0.3)
                    Text(statusLabel)
                        .font(.system(size: 13))
                        .foregroundStyle(.brandGray)
                        .lineSpacing(3)
                }

                Spacer()

                if status == .denied {
                    Button("Apri") {
                        if let url = URL(string: UIApplication.openSettingsURLString) {
                            UIApplication.shared.open(url)
                        }
                    }
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundStyle(.brandRed)
                    .accessibilityLabel("Apri Impostazioni per abilitare le notifiche")
                }
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 14)
            .background {
                RoundedRectangle(cornerRadius: 18)
                    .fill(.white.opacity(0.78))
                    .overlay {
                        RoundedRectangle(cornerRadius: 18)
                            .strokeBorder(.white.opacity(0.75), lineWidth: 0.5)
                    }
                    .shadow(color: .black.opacity(0.05), radius: 5, x: 0, y: 2)
            }
            .padding(.horizontal, 20)
        }
        .padding(.top, 28)
        .padding(.bottom, 32)
        .task { await updateStatus() }
    }

    private var iconName: String {
        switch status {
        case .authorized, .ephemeral, .provisional: return "bell.fill"
        default: return "bell.slash.fill"
        }
    }

    private var iconColor: Color {
        switch status {
        case .authorized, .ephemeral, .provisional: return .brandRed
        default: return .brandGray
        }
    }

    private var statusLabel: String {
        switch status {
        case .authorized, .ephemeral, .provisional: return "Abilitate"
        case .denied:         return "Non abilitate — tocca Apri per gestire"
        default:              return "Non ancora richieste"
        }
    }

    private func updateStatus() async {
        status = await UNUserNotificationCenter.current().notificationSettings().authorizationStatus
    }
}

// MARK: - Preview

#Preview {
    NavigationStack {
        SosteniView()
            .navigationTitle("Sostieni")
    }
}
