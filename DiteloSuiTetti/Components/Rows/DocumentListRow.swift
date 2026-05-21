import SwiftUI

struct DocumentListRow: View {
    let document: Document
    var isLast: Bool = false

    var body: some View {
        VStack(spacing: 0) {
            HStack(alignment: .top, spacing: 14) {
                ZStack {
                    RoundedRectangle(cornerRadius: 12)
                        .fill(Color.brandRed.opacity(0.12))
                        .frame(width: 48, height: 48)
                    Image(systemName: "doc.fill")
                        .font(.system(size: 20))
                        .foregroundStyle(.brandRed)
                }
                .accessibilityHidden(true)

                VStack(alignment: .leading, spacing: 5) {
                    Text(document.title)
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundStyle(.brandBlack)
                        .lineLimit(2)
                        .kerning(-0.25)

                    HStack(spacing: 5) {
                        if !document.type.isEmpty {
                            Text(document.type)
                                .font(.system(size: 12, weight: .medium))
                                .foregroundStyle(.brandRed)
                            Circle().frame(width: 2.5, height: 2.5).foregroundStyle(.brandGrayLight)
                        }
                        Text(document.uploadedAt)
                    }
                    .font(.system(size: 12))
                    .foregroundStyle(.brandGrayLight)
                }

                Spacer(minLength: 0)

                Image(systemName: "chevron.right")
                    .font(.system(size: 11, weight: .semibold))
                    .foregroundStyle(.secondary)
                    .accessibilityHidden(true)
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 13)

            if !isLast {
                Divider().padding(.leading, 78)
            }
        }
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(document.title), \(document.type), \(document.uploadedAt)")
        .accessibilityHint("Mostra dettagli documento")
    }
}
