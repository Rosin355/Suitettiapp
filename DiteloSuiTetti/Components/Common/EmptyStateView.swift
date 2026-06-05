import SwiftUI

/// Illustrated empty / error state used across all list screens.
///
/// Shows a branded icon badge, a title, a subtitle, and up to two
/// action buttons. All parameters except `icon`, `title`, `subtitle`
/// are optional so the simplest call sites stay concise.
struct EmptyStateView: View {
    let icon: String
    let title: String
    let subtitle: String
    var iconTint: Color = .brandRed
    var primaryLabel: String = ""
    var primaryAction: (() -> Void)? = nil
    var secondaryLabel: String = ""
    var secondaryAction: (() -> Void)? = nil

    var body: some View {
        VStack(spacing: 20) {
            iconBadge
            labels
            if primaryAction != nil || secondaryAction != nil {
                actions
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .padding(.vertical, 64)
        .padding(.horizontal, 40)
    }

    private var iconBadge: some View {
        ZStack {
            Circle()
                .fill(iconTint.opacity(0.10))
                .frame(width: 88, height: 88)
            Image(systemName: icon)
                .font(.system(size: 34, weight: .medium))
                .foregroundStyle(iconTint.opacity(0.75))
        }
        .accessibilityHidden(true)
    }

    private var labels: some View {
        VStack(spacing: 6) {
            Text(title)
                .font(.system(size: 17, weight: .semibold))
                .foregroundStyle(.brandBlack)
                .multilineTextAlignment(.center)
            Text(subtitle)
                .font(.system(size: 15))
                .foregroundStyle(.brandGray)
                .multilineTextAlignment(.center)
                .lineSpacing(3)
        }
    }

    private var actions: some View {
        VStack(spacing: 10) {
            if let primary = primaryAction, !primaryLabel.isEmpty {
                Button(primaryLabel, action: primary)
                    .buttonStyle(.borderedProminent)
                    .tint(.brandRed)
                    .accessibilityLabel(primaryLabel)
            }
            if let secondary = secondaryAction, !secondaryLabel.isEmpty {
                Button(secondaryLabel, action: secondary)
                    .font(.system(size: 14, weight: .medium))
                    .foregroundStyle(.brandRed)
                    .accessibilityLabel(secondaryLabel)
            }
        }
        .padding(.top, 4)
    }
}

// MARK: - Previews

#Preview("Empty Documents") {
    ZStack {
        Color.brandCream.ignoresSafeArea()
        EmptyStateView(
            icon: "doc.on.doc",
            title: "Nessun documento",
            subtitle: "Non sono presenti documenti al momento."
        )
    }
}

#Preview("Empty Events") {
    ZStack {
        Color.brandCream.ignoresSafeArea()
        EmptyStateView(
            icon: "calendar",
            title: "Nessun evento",
            subtitle: "Non ci sono eventi in programma.",
            secondaryLabel: "Consulta gli eventi passati",
            secondaryAction: {}
        )
    }
}

#Preview("Error state") {
    ZStack {
        Color.brandCream.ignoresSafeArea()
        EmptyStateView(
            icon: "wifi.slash",
            title: "Connessione non disponibile",
            subtitle: "Controlla la connessione e riprova.",
            iconTint: .brandGray,
            primaryLabel: "Riprova",
            primaryAction: {}
        )
    }
}
