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

/// Premium card for a linked PDF document.
/// When `url` is provided, tapping navigates to `PDFReaderView` (requires a NavigationStack ancestor).
/// When `url` is nil, the card shows a disabled "PDF non disponibile" state.
struct LinkedDocumentCard: View {
    let document: RelatedDocument

    /// "PDF" pill text — defaults to PDF, but surfaces a distinct backend type if present.
    private var pillText: String {
        let trimmed = document.type.trimmingCharacters(in: .whitespaces)
        return (trimmed.isEmpty || trimmed.lowercased() == "pdf") ? "PDF" : trimmed.uppercased()
    }

    var body: some View {
        if let url = document.url {
            NavigationLink(destination: PDFReaderView(remoteURL: url, title: document.title)) {
                cardBody(hasURL: true)
            }
            .buttonStyle(PressableCardStyle())
            .accessibilityElement(children: .ignore)
            .accessibilityLabel("Apri documento PDF, \(document.title)")
            .accessibilityHint("Apre il lettore PDF")
            .accessibilityAddTraits(.isButton)
        } else {
            cardBody(hasURL: false)
                .accessibilityElement(children: .ignore)
                .accessibilityLabel("Documento PDF non disponibile, \(document.title)")
        }
    }

    private func cardBody(hasURL: Bool) -> some View {
        VStack(spacing: 0) {
            // MARK: Main content row
            HStack(alignment: .top, spacing: 14) {
                // Stronger PDF icon in a tinted rounded tile
                ZStack {
                    RoundedRectangle(cornerRadius: 14)
                        .fill(hasURL ? Color.brandRed.opacity(0.12) : Color.black.opacity(0.06))
                    Image(systemName: hasURL ? "doc.richtext.fill" : "doc.slash.fill")
                        .font(.system(size: 24, weight: .semibold))
                        .foregroundStyle(hasURL ? Color.brandRed : Color.brandGrayLight)
                }
                .frame(width: 52, height: 52)
                .accessibilityHidden(true)

                VStack(alignment: .leading, spacing: 6) {
                    // Clear "PDF" pill
                    Text(pillText)
                        .font(.system(size: 11, weight: .bold))
                        .kerning(0.5)
                        .foregroundStyle(hasURL ? Color.brandRed : Color.brandGrayLight)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 3)
                        .background(
                            (hasURL ? Color.brandRed : Color.brandGray).opacity(0.12),
                            in: Capsule()
                        )

                    Text(document.title)
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundStyle(hasURL ? Color.brandBlack : Color.brandGray)
                        .lineLimit(3)
                        .multilineTextAlignment(.leading)
                        .fixedSize(horizontal: false, vertical: true)

                    // Optional metadata row (only fields the backend actually provides)
                    if !document.description.isEmpty {
                        Text(document.description)
                            .font(.system(size: 13))
                            .foregroundStyle(Color.brandGray)
                            .lineLimit(2)
                            .fixedSize(horizontal: false, vertical: true)
                    }
                }

                Spacer(minLength: 0)

                // Right-side open/download affordance
                Image(systemName: hasURL ? "arrow.down.circle.fill" : "xmark.circle")
                    .font(.system(size: 24))
                    .foregroundStyle(hasURL ? Color.brandRed : Color.brandGrayLight)
                    .accessibilityHidden(true)
            }
            .padding(16)

            // MARK: Soft red action strip (≥ 44pt tap target via the whole card)
            if hasURL {
                HStack(spacing: 6) {
                    Image(systemName: "arrow.up.right.square.fill")
                        .font(.system(size: 13, weight: .semibold))
                    Text("Apri PDF")
                        .font(.system(size: 14, weight: .semibold))
                    Spacer(minLength: 0)
                    Image(systemName: "chevron.right")
                        .font(.system(size: 12, weight: .bold))
                }
                .foregroundStyle(Color.brandRed)
                .padding(.horizontal, 16)
                .frame(minHeight: 46)
                .frame(maxWidth: .infinity)
                .background(Color.brandRed.opacity(0.08))
            } else {
                HStack(spacing: 6) {
                    Image(systemName: "exclamationmark.triangle")
                        .font(.system(size: 12, weight: .semibold))
                    Text("PDF non disponibile")
                        .font(.system(size: 13, weight: .medium))
                    Spacer(minLength: 0)
                }
                .foregroundStyle(Color.brandGrayLight)
                .padding(.horizontal, 16)
                .frame(minHeight: 42)
                .frame(maxWidth: .infinity)
                .background(Color.black.opacity(0.04))
            }
        }
        .background(.white)
        .clipShape(.rect(cornerRadius: DT.cornerRadius))
        .overlay {
            RoundedRectangle(cornerRadius: DT.cornerRadius)
                .strokeBorder(.black.opacity(0.06), lineWidth: 0.5)
        }
        .shadow(color: .black.opacity(0.07), radius: 10, x: 0, y: 3)
        .opacity(hasURL ? 1.0 : 0.7)
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
