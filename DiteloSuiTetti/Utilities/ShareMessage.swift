import Foundation

/// Builds inviting share text for editorial content.
///
/// Every message embeds the canonical `www.suitetti.org` URL plus the App Store
/// link — never a raw URL alone, and never a legacy/preview domain.
enum ShareMessage {

    private static var appStoreLine: String {
        "App iOS:\n\(AppEnvironment.appStoreURL.absoluteString)"
    }

    static func article(title: String, url: URL) -> String {
        """
        Ti invito a leggere questo articolo su Ditelo sui Tetti:

        \(title)

        Aprilo sul sito o scarica l'app per seguire articoli, eventi e documenti:
        \(url.absoluteString)

        \(appStoreLine)
        """
    }

    static func event(title: String, url: URL, whenLine: String?, whereLine: String?) -> String {
        var details = [title]
        if let w = whenLine, !w.isEmpty  { details.append(w) }
        if let l = whereLine, !l.isEmpty { details.append(l) }
        return """
        Ti invito a questo evento di Ditelo sui Tetti:

        \(details.joined(separator: "\n"))

        Dettagli sul sito o scarica l'app per seguire articoli, eventi e documenti:
        \(url.absoluteString)

        \(appStoreLine)
        """
    }

    static func document(title: String, url: URL) -> String {
        """
        Ti invito a consultare questo documento su Ditelo sui Tetti:

        \(title)

        Aprilo sul sito o scarica l'app per seguire articoli, eventi e documenti:
        \(url.absoluteString)

        \(appStoreLine)
        """
    }
}
