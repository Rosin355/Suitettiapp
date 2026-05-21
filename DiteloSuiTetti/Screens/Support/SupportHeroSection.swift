import SwiftUI

struct SupportHeroSection: View {
    var body: some View {
        GCard {
            VStack(alignment: .leading, spacing: 0) {
                Text("iniziativa civica")
                    .font(Font.custom("Georgia", size: 13).italic())
                    .foregroundStyle(.brandGrayLight)
                    .padding(.bottom, 10)

                Text("Sostieni\nla rete civica")
                    .font(.system(size: 26, weight: .black))
                    .foregroundStyle(.white)
                    .kerning(-0.6)
                    .lineSpacing(2)
                    .padding(.bottom, 10)

                Text("Ogni contributo — grande o piccolo — fa la differenza per la vita, la famiglia e l'educazione.")
                    .font(.system(size: 14))
                    .foregroundStyle(.white.opacity(0.65))
                    .lineSpacing(3)
                    .padding(.bottom, 20)

                Button("Sostienici →") {}
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundStyle(.white)
                    .frame(height: 48)
                    .padding(.horizontal, 22)
                    .background(.brandRed)
                    .clipShape(Capsule())
                    .shadow(color: .brandRed.opacity(0.4), radius: 8, x: 0, y: 4)
            }
            .padding(22)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background {
                ZStack(alignment: .topTrailing) {
                    LinearGradient(
                        colors: [.brandBlack, Color(red: 42/255, green: 42/255, blue: 42/255)],
                        startPoint: .topLeading, endPoint: .bottomTrailing
                    )
                    Circle()
                        .fill(.brandRed.opacity(0.15))
                        .frame(width: 120, height: 120)
                        .offset(x: 20, y: -20)
                }
            }
        }
        .padding(.horizontal, DT.padding)
        .padding(.top, 8)
        .padding(.bottom, 14)
    }
}
