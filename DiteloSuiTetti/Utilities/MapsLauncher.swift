import UIKit

enum MapsLauncher {
    /// Opens Apple Maps search for the given location string.
    /// Percent-encodes the query before building the URL.
    static func open(location: String) {
        let trimmed = location.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty,
              let encoded = trimmed.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed),
              let url = URL(string: "http://maps.apple.com/?q=\(encoded)")
        else { return }
        UIApplication.shared.open(url)
    }
}
