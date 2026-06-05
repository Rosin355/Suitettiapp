import SwiftUI

private struct SocialPlatform {
    let name: String
    let icon: String
    let urlString: String
    let tileColor: Color
}

private let platforms: [SocialPlatform] = [
    SocialPlatform(
        name: "Facebook",
        icon: "person.2.fill",
        urlString: "https://www.facebook.com/DiteloSuiTetti",
        tileColor: Color(red: 24/255, green: 119/255, blue: 242/255)
    ),
    SocialPlatform(
        name: "X",
        icon: "xmark",
        urlString: "https://x.com/DiteloSuiTetti",
        tileColor: Color(red: 15/255, green: 20/255, blue: 25/255)
    ),
    SocialPlatform(
        name: "YouTube",
        icon: "play.rectangle.fill",
        urlString: "https://www.youtube.com/@DiteloSuiTetti",
        tileColor: Color(red: 255/255, green: 0/255, blue: 0/255)
    ),
]

struct SocialLinksSheet: View {
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            VStack(spacing: 10) {
                ForEach(platforms, id: \.name) { platform in
                    SocialPlatformRow(platform: platform)
                }

                Text("I link si apriranno nel browser o nell'app del social.")
                    .font(.system(size: 12))
                    .foregroundStyle(.brandGrayLight)
                    .multilineTextAlignment(.center)
                    .padding(.top, 8)
            }
            .padding(.horizontal, 20)
            .padding(.top, 12)
            .padding(.bottom, 40)
            .frame(maxWidth: .infinity)
            .navigationTitle("Seguici sui social")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Chiudi") { dismiss() }
                        .foregroundStyle(.brandRed)
                        .fontWeight(.medium)
                }
            }
        }
        .presentationDetents([.medium])
        .presentationDragIndicator(.visible)
        .presentationBackground(.brandCream)
    }
}

// MARK: - SocialPlatformRow

private struct SocialPlatformRow: View {
    let platform: SocialPlatform

    var body: some View {
        Button {
            guard let url = URL(string: platform.urlString) else { return }
            UIApplication.shared.open(url)
        } label: {
            HStack(spacing: 14) {
                RoundedRectangle(cornerRadius: 12)
                    .fill(platform.tileColor.opacity(0.12))
                    .frame(width: 44, height: 44)
                    .overlay {
                        Image(systemName: platform.icon)
                            .font(.system(size: 18, weight: .semibold))
                            .foregroundStyle(platform.tileColor)
                    }
                    .accessibilityHidden(true)

                Text(platform.name)
                    .font(.system(size: 16, weight: .medium))
                    .foregroundStyle(.brandBlack)

                Spacer()

                Image(systemName: "arrow.up.right")
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundStyle(.brandGrayLight)
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 14)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(.white.opacity(0.82))
            .clipShape(.rect(cornerRadius: DT.cornerRadius))
            .overlay {
                RoundedRectangle(cornerRadius: DT.cornerRadius)
                    .strokeBorder(.white.opacity(0.75), lineWidth: 0.5)
            }
            .cardShadow()
        }
        .buttonStyle(.plain)
        .accessibilityLabel("Seguici su \(platform.name)")
    }
}

// MARK: - Preview

#Preview {
    SocialLinksSheet()
}
