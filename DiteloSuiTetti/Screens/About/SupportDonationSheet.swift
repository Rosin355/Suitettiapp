import SwiftUI

struct SupportDonationSheet: View {
    @Environment(\.dismiss) private var dismiss

    @State private var ibanCopied = false
    @State private var allDetailsCopied = false
    @State private var ibanResetTask: Task<Void, Never>?
    @State private var allDetailsResetTask: Task<Void, Never>?

    private let intestatario = "Pubblica Agenda Sussidiaria e Condivisa – Ditelo sui tetti"
    private let indirizzo    = "via Cavour 285, 00184 Roma"
    private let iban         = "IT43C0306909606100000186533"
    private let bic          = "BCTTTTMM"
    private let banca        = "Banca Intesa Sanpaolo"

    private var allBankDetails: String {
        """
        \(intestatario)
        \(indirizzo)
        IBAN: \(iban)
        BIC: \(bic)
        \(banca)
        """
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 0) {
                    introSection
                    bankSection
                    copyButtonsSection
                }
            }
            .background(.brandCream)
            .scrollIndicators(.hidden)
            .navigationTitle("Sostieni Ditelo sui Tetti")
            .navigationBarTitleDisplayMode(.large)
            .toolbarBackground(.ultraThinMaterial, for: .navigationBar)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Chiudi") { dismiss() }
                        .foregroundStyle(.brandRed)
                        .fontWeight(.medium)
                }
            }
        }
        .presentationDetents([.large])
        .presentationDragIndicator(.visible)
        .presentationBackground(.brandCream)
    }

    // MARK: - Sections

    private var introSection: some View {
        Text("Il tuo sostegno conta: ogni giorno lavoriamo per dar vita al cambiamento, ma non possiamo farlo da soli. Per riuscirci dobbiamo essere in tanti. Per riuscirci abbiamo bisogno di te!")
            .font(.system(size: 16))
            .foregroundStyle(.brandBlack.opacity(0.82))
            .lineSpacing(5)
            .fixedSize(horizontal: false, vertical: true)
            .padding(.horizontal, 20)
            .padding(.top, 8)
            .padding(.bottom, 28)
    }

    private var bankSection: some View {
        VStack(alignment: .leading, spacing: 0) {
            Text("Puoi donare con bonifico bancario")
                .font(.system(size: 19, weight: .bold))
                .foregroundStyle(.brandBlack)
                .padding(.horizontal, 20)
                .padding(.bottom, 12)

            VStack(alignment: .leading, spacing: 0) {
                BankDetailRow(label: "Intestatario", value: intestatario)
                Divider().padding(.leading, 16)
                BankDetailRow(label: "Indirizzo", value: indirizzo)
                Divider().padding(.leading, 16)
                BankDetailRow(label: "IBAN", value: iban, isMonospaced: true)
                Divider().padding(.leading, 16)
                BankDetailRow(label: "BIC", value: bic, isMonospaced: true)
                Divider().padding(.leading, 16)
                BankDetailRow(label: "Banca", value: banca)
            }
            .background(.white.opacity(0.82))
            .clipShape(.rect(cornerRadius: DT.cornerRadius))
            .overlay {
                RoundedRectangle(cornerRadius: DT.cornerRadius)
                    .strokeBorder(.white.opacity(0.75), lineWidth: 0.5)
            }
            .cardShadow()
            .padding(.horizontal, 20)
            .padding(.bottom, 24)
        }
    }

    private var copyButtonsSection: some View {
        VStack(spacing: 10) {
            DonationCopyButton(
                label: ibanCopied ? "Copiato ✓" : "Copia IBAN",
                icon: ibanCopied ? "checkmark" : "doc.on.doc",
                accessibilityLabel: "Copia IBAN negli appunti",
                isCopied: ibanCopied,
                isPrimary: true
            ) {
                UIPasteboard.general.string = iban
                withAnimation(.easeInOut(duration: 0.2)) { ibanCopied = true }
                ibanResetTask?.cancel()
                ibanResetTask = Task {
                    try? await Task.sleep(for: .seconds(2))
                    guard !Task.isCancelled else { return }
                    withAnimation(.easeInOut(duration: 0.2)) { ibanCopied = false }
                }
            }

            DonationCopyButton(
                label: allDetailsCopied ? "Copiato ✓" : "Copia coordinate",
                icon: allDetailsCopied ? "checkmark" : "doc.on.doc.fill",
                accessibilityLabel: "Copia tutte le coordinate bancarie negli appunti",
                isCopied: allDetailsCopied,
                isPrimary: false
            ) {
                UIPasteboard.general.string = allBankDetails
                withAnimation(.easeInOut(duration: 0.2)) { allDetailsCopied = true }
                allDetailsResetTask?.cancel()
                allDetailsResetTask = Task {
                    try? await Task.sleep(for: .seconds(2))
                    guard !Task.isCancelled else { return }
                    withAnimation(.easeInOut(duration: 0.2)) { allDetailsCopied = false }
                }
            }
        }
        .padding(.horizontal, 20)
        .padding(.bottom, 48)
    }
}

// MARK: - BankDetailRow

private struct BankDetailRow: View {
    let label: String
    let value: String
    var isMonospaced: Bool = false

    var body: some View {
        VStack(alignment: .leading, spacing: 3) {
            Text(label.uppercased())
                .font(.system(size: 11, weight: .semibold))
                .foregroundStyle(.brandGrayLight)
                .kerning(0.6)
            Text(value)
                .font(isMonospaced
                      ? .system(size: 15, design: .monospaced)
                      : .system(size: 15))
                .foregroundStyle(.brandBlack)
                .textSelection(.enabled)
                .fixedSize(horizontal: false, vertical: true)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 13)
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}

// MARK: - DonationCopyButton

private struct DonationCopyButton: View {
    let label: String
    let icon: String
    let accessibilityLabel: String
    let isCopied: Bool
    let isPrimary: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: 8) {
                Image(systemName: icon)
                    .font(.system(size: 14, weight: .semibold))
                Text(label)
                    .font(.system(size: 16, weight: .semibold))
            }
            .foregroundStyle(isPrimary ? Color.white : Color.brandRed)
            .frame(maxWidth: .infinity)
            .frame(height: 50)
            .background(isPrimary ? Color.brandRed : Color.brandRed.opacity(0.08))
            .clipShape(.rect(cornerRadius: DT.smallCorner))
            .overlay {
                if !isPrimary {
                    RoundedRectangle(cornerRadius: DT.smallCorner)
                        .strokeBorder(Color.brandRed.opacity(0.3), lineWidth: 1)
                }
            }
        }
        .buttonStyle(.plain)
        .accessibilityLabel(accessibilityLabel)
        .sensoryFeedback(.success, trigger: isCopied) { _, new in new }
    }
}

// MARK: - Preview

#Preview {
    SupportDonationSheet()
}
