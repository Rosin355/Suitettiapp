import SwiftUI

struct DetailTitleCard<Metadata: View>: View {
    let label: String?
    let labelColor: Color
    var labelBackground: Color? = nil
    let title: String
    let metadata: Metadata

    init(
        label: String?,
        labelColor: Color,
        labelBackground: Color? = nil,
        title: String,
        @ViewBuilder metadata: () -> Metadata
    ) {
        self.label = label
        self.labelColor = labelColor
        self.labelBackground = labelBackground
        self.title = title
        self.metadata = metadata()
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            if let label, !label.isEmpty {
                CategoryChip(
                    text: label,
                    color: labelColor,
                    background: labelBackground ?? labelColor.opacity(0.10)
                )
            }
            Text(title)
                .font(.system(size: 28, weight: .bold, design: .rounded))
                .foregroundStyle(.brandBlack)
                .multilineTextAlignment(.leading)
                .fixedSize(horizontal: false, vertical: true)
                .frame(maxWidth: .infinity, alignment: .leading)
            metadata
        }
        .padding(.vertical, 22)
        .padding(.horizontal, 22)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(.white)
        .clipShape(.rect(cornerRadius: 28, style: .continuous))
        .shadow(color: .black.opacity(0.08), radius: 16, x: 0, y: -4)
        .padding(.horizontal, 20)
        .padding(.top, -32)
    }
}

extension DetailTitleCard where Metadata == EmptyView {
    init(
        label: String?,
        labelColor: Color,
        labelBackground: Color? = nil,
        title: String
    ) {
        self.init(
            label: label,
            labelColor: labelColor,
            labelBackground: labelBackground,
            title: title
        ) { EmptyView() }
    }
}

#Preview("Short title") {
    ZStack {
        Color.brandCream.ignoresSafeArea()
        VStack(spacing: 0) {
            Color.gray.frame(height: 340)
            DetailTitleCard(
                label: "Bene Comune",
                labelColor: .brandRed,
                title: "Sussidiarietà"
            )
        }
    }
}

#Preview("Long title (real)") {
    ZStack {
        Color.brandCream.ignoresSafeArea()
        VStack(spacing: 0) {
            Color.gray.frame(height: 340)
            DetailTitleCard(
                label: "Non autosufficienza",
                labelColor: .brandRed,
                title: "Non autosufficienza, Napolitano (Sui Tetti): con i 3 miliardi per i più fragili dal vice ministro Bellucci iniziativa strategica"
            )
        }
    }
}

#Preview("With metadata") {
    ZStack {
        Color.brandCream.ignoresSafeArea()
        VStack(spacing: 0) {
            Color.gray.frame(height: 340)
            DetailTitleCard(
                label: "Referendum",
                labelColor: .brandRed,
                title: "Referendum sulla riforma della giustizia: le ragioni del sì"
            ) {
                HStack(spacing: 6) {
                    Image(systemName: "calendar").font(.system(size: 11))
                    Text("20 mag 2026")
                    Circle().frame(width: 3, height: 3)
                    Image(systemName: "clock").font(.system(size: 11))
                    Text("5 min di lettura")
                }
                .font(.system(size: 13))
                .foregroundStyle(.brandGray)
            }
        }
    }
}
