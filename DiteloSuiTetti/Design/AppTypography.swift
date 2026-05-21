import SwiftUI

extension Font {
    static func georgia(_ size: CGFloat) -> Font {
        Font.custom("Georgia", size: size)
    }

    static func georgiaItalic(_ size: CGFloat) -> Font {
        Font.custom("Georgia", size: size).italic()
    }
}
