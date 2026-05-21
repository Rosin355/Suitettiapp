import SwiftUI

extension Color {
    static let brandRed         = Color(red: 232/255, green: 25/255,  blue: 44/255)
    static let brandCream       = Color(red: 242/255, green: 239/255, blue: 233/255)
    static let brandYellow      = Color(red: 245/255, green: 232/255, blue: 74/255)
    static let brandYellowLight = Color(red: 252/255, green: 239/255, blue: 170/255)
    static let brandBlack       = Color(red: 26/255,  green: 26/255,  blue: 26/255)
    static let brandGray        = Color(red: 94/255,  green: 94/255,  blue: 94/255)
    static let brandGrayLight   = Color(red: 160/255, green: 160/255, blue: 160/255)
    static let brandSep         = Color.black.opacity(0.08)
}

extension ShapeStyle where Self == Color {
    static var brandRed:         Color { .init(red: 232/255, green: 25/255,  blue: 44/255) }
    static var brandCream:       Color { .init(red: 242/255, green: 239/255, blue: 233/255) }
    static var brandYellow:      Color { .init(red: 245/255, green: 232/255, blue: 74/255) }
    static var brandYellowLight: Color { .init(red: 252/255, green: 239/255, blue: 170/255) }
    static var brandBlack:       Color { .init(red: 26/255,  green: 26/255,  blue: 26/255) }
    static var brandGray:        Color { .init(red: 94/255,  green: 94/255,  blue: 94/255) }
    static var brandGrayLight:   Color { .init(red: 160/255, green: 160/255, blue: 160/255) }
}
