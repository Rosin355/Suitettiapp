import SwiftUI

struct DocumentDetailView: View {
    let document: Document

    private var plainDescription: String {
        HTMLTextFormatter.plainText(from: document.description)
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 0) {
                headerSection
                    .padding(.horizontal, 24)
                    .padding(.top, 24)

                Rectangle()
                    .fill(.brandSep)
                    .frame(height: 1)
                    .padding(.horizontal, 24)
                    .padding(.top, 20)

                metadataCard
                    .padding(.horizontal, 24)
                    .padding(.top, 20)

                if !plainDescription.isEmpty {
                    Text(plainDescription)
                        .font(.system(size: 17))
                        .foregroundStyle(.brandBlack)
                        .lineSpacing(7)
                        .padding(.horizontal, 24)
                        .padding(.top, 20)
                }

                actionButtons
                    .padding(.horizontal, 24)
                    .padding(.top, 28)
                    .padding(.bottom, 100)
            }
            .frame(maxWidth: DT.readableMaxWidth)
        .frame(maxWidth: .infinity)
        }
        .background(.brandCream)
        .navigationTitle("Documento")
        .navigationBarTitleDisplayMode(.inline)
        .scrollIndicators(.hidden)
    }

    // MARK: - Header

    private var headerSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(spacing: 8) {
                if !document.type.isEmpty {
                    CategoryChip(text: document.type, color: .brandRed, background: .brandRed.opacity(0.12))
                }
                if !document.category.isEmpty {
                    CategoryChip(text: document.category, color: .brandGray, background: Color.black.opacity(0.07))
                }
            }
            Text(document.title)
                .font(.system(size: 22, weight: .black))
                .foregroundStyle(.brandBlack)
                .kerning(-0.4)
                .lineSpacing(2)
                .fixedSize(horizontal: false, vertical: true)
        }
    }

    // MARK: - Metadata

    private var metadataCard: some View {
        VStack(spacing: 0) {
            metadataRow(icon: "calendar", label: "Caricato il", value: document.uploadedAt)
            Divider().padding(.horizontal, 16)
            metadataRow(icon: "folder", label: "Categoria", value: document.category.isEmpty ? "—" : document.category)
            Divider().padding(.horizontal, 16)
            metadataRow(icon: "doc.text", label: "Tipo", value: document.type.isEmpty ? "—" : document.type)
        }
        .background(.white.opacity(0.82))
        .clipShape(.rect(cornerRadius: DT.cornerRadius))
        .overlay {
            RoundedRectangle(cornerRadius: DT.cornerRadius)
                .strokeBorder(.white.opacity(0.75), lineWidth: 0.5)
        }
        .shadow(color: .black.opacity(0.05), radius: 6, x: 0, y: 2)
    }

    private func metadataRow(icon: String, label: String, value: String) -> some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .font(.system(size: 13))
                .foregroundStyle(.brandGray)
                .frame(width: 20)
            Text(label)
                .font(.system(size: 14))
                .foregroundStyle(.brandGray)
            Spacer()
            Text(value)
                .font(.system(size: 14, weight: .medium))
                .foregroundStyle(.brandBlack)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 14)
    }

    // MARK: - Actions

    @ViewBuilder
    private var actionButtons: some View {
        if let pdfURL = document.url {
            VStack(spacing: 12) {
                NavigationLink(destination: PDFReaderView(remoteURL: pdfURL, title: document.title)) {
                    Label("Leggi PDF", systemImage: "doc.fill")
                        .font(.system(size: 16, weight: .semibold))
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 4)
                }
                .buttonStyle(.borderedProminent)
                .tint(.brandRed)
                .controlSize(.large)
                .accessibilityLabel("Leggi PDF: \(document.title)")

                HStack(spacing: 12) {
                    Link(destination: pdfURL) {
                        Label("Apri esternamente", systemImage: "arrow.up.right.square")
                            .font(.system(size: 15, weight: .medium))
                            .frame(maxWidth: .infinity)
                    }
                    .buttonStyle(.bordered)
                    .tint(.brandGray)
                    .controlSize(.large)
                    .accessibilityLabel("Apri PDF nel browser")

                    ShareLink(item: pdfURL) {
                        Image(systemName: "square.and.arrow.up")
                            .font(.system(size: 16, weight: .medium))
                            .frame(width: 44, height: 44)
                    }
                    .buttonStyle(.bordered)
                    .tint(.brandGray)
                    .accessibilityLabel("Condividi documento")
                }
            }
        } else {
            HStack(spacing: 12) {
                Image(systemName: "doc.slash")
                    .font(.system(size: 22))
                    .foregroundStyle(.brandGrayLight)
                Text("PDF non disponibile")
                    .font(.system(size: 15))
                    .foregroundStyle(.brandGrayLight)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 24)
        }
    }
}

#Preview {
    NavigationStack {
        DocumentDetailView(document: Document.all[0])
    }
}
