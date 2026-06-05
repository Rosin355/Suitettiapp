import SwiftUI

// MARK: - Model

/// Lightweight representation of a document linked to an article or event.
/// Not yet populated from the backend. Reserved for future backend relationship support —
/// see ROADMAP.md: "Linked documents: backend relation not yet implemented."
struct RelatedDocument: Identifiable, Codable {
    let id: UUID
    let title: String
    let type: String
    let description: String
    let url: URL?

    init(id: UUID = UUID(), title: String, type: String = "", description: String = "", url: URL? = nil) {
        self.id = id
        self.title = title
        self.type = type
        self.description = description
        self.url = url
    }
}

// MARK: - Card view

/// Compact card for a linked document.
/// When `url` is provided, tapping navigates to `PDFReaderView` (requires a NavigationStack ancestor).
/// When `url` is nil, the card shows a disabled "PDF non disponibile" state.
struct LinkedDocumentCard: View {
    let document: RelatedDocument

    var body: some View {
        if let url = document.url {
            NavigationLink(destination: PDFReaderView(remoteURL: url, title: document.title)) {
                cardBody(hasURL: true)
            }
            .buttonStyle(PressableCardStyle())
            .accessibilityLabel("Documento: \(document.title). Tocca per leggere il PDF.")
            .accessibilityHint("Apre il lettore PDF")
        } else {
            cardBody(hasURL: false)
                .accessibilityLabel("Documento: \(document.title). PDF non disponibile.")
        }
    }

    private func cardBody(hasURL: Bool) -> some View {
        HStack(spacing: 14) {
            Image(systemName: hasURL ? "doc.richtext.fill" : "doc.slash")
                .font(.system(size: 22))
                .foregroundStyle(hasURL ? Color.brandRed : Color.brandGrayLight)
                .frame(width: 40, height: 40)
                .accessibilityHidden(true)

            VStack(alignment: .leading, spacing: 4) {
                if !document.type.isEmpty {
                    CategoryChip(
                        text: document.type,
                        color: hasURL ? .brandRed : .brandGrayLight,
                        background: hasURL ? .brandRed.opacity(0.10) : Color.black.opacity(0.06)
                    )
                }
                Text(document.title)
                    .font(.system(size: 15, weight: .semibold))
                    .foregroundStyle(hasURL ? Color.brandBlack : Color.brandGray)
                    .lineLimit(2)
                    .fixedSize(horizontal: false, vertical: true)

                if !document.description.isEmpty {
                    Text(document.description)
                        .font(.system(size: 13))
                        .foregroundStyle(Color.brandGray)
                        .lineLimit(2)
                }
            }

            Spacer(minLength: 0)

            if hasURL {
                Image(systemName: "chevron.right")
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundStyle(Color.brandGray)
                    .accessibilityHidden(true)
            }
        }
        .padding(.horizontal, 16)
        .frame(minHeight: 64)
        .background(.white.opacity(0.82))
        .clipShape(.rect(cornerRadius: DT.cornerRadius))
        .overlay {
            RoundedRectangle(cornerRadius: DT.cornerRadius)
                .strokeBorder(.white.opacity(0.75), lineWidth: 0.5)
        }
        .shadow(color: .black.opacity(0.06), radius: 7, x: 0, y: 2)
        .opacity(hasURL ? 1.0 : 0.6)
    }
}

// MARK: - Previews

#Preview("With URL") {
    NavigationStack {
        ScrollView {
            VStack(spacing: 12) {
                LinkedDocumentCard(document: RelatedDocument(
                    title: "Riforma costituzionale — testo integrale",
                    type: "PDF",
                    description: "Il testo completo della proposta di riforma referendaria",
                    url: URL(string: "https://example.com/riforma.pdf")
                ))
                LinkedDocumentCard(document: RelatedDocument(
                    title: "Scheda di sintesi",
                    type: "Documento"
                ))
            }
            .padding()
        }
        .background(Color.brandCream)
    }
}

#Preview("No URL") {
    ScrollView {
        LinkedDocumentCard(document: RelatedDocument(
            title: "Comunicato stampa — PDF non disponibile",
            type: "Comunicato",
            description: "Il documento non è ancora stato caricato."
        ))
        .padding()
    }
    .background(Color.brandCream)
}
