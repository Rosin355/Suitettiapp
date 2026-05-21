import Foundation

enum HTMLTextFormatter {

    static func plainText(from html: String?) -> String {
        guard let html, !html.isEmpty else { return "" }

        // Strip all HTML tags, replacing block-level closings with newlines
        var result = html
            .replacingOccurrences(of: "</p>",   with: "\n\n", options: .caseInsensitive)
            .replacingOccurrences(of: "</div>", with: "\n",   options: .caseInsensitive)
            .replacingOccurrences(of: "</li>",  with: "\n",   options: .caseInsensitive)
            .replacingOccurrences(of: "<br>",   with: "\n",   options: .caseInsensitive)
            .replacingOccurrences(of: "<br/>",  with: "\n",   options: .caseInsensitive)
            .replacingOccurrences(of: "<br />", with: "\n",   options: .caseInsensitive)

        // Remove all remaining tags
        result = result.replacingOccurrences(of: "<[^>]+>", with: "", options: .regularExpression)

        // Decode common HTML entities (including Italian accents)
        let entities: [(String, String)] = [
            ("&nbsp;",   " "),
            ("&amp;",    "&"),
            ("&lt;",     "<"),
            ("&gt;",     ">"),
            ("&quot;",   "\""),
            ("&#39;",    "'"),
            ("&apos;",   "'"),
            ("&laquo;",  "«"),
            ("&raquo;",  "»"),
            ("&agrave;", "à"), ("&Agrave;", "À"),
            ("&egrave;", "è"), ("&Egrave;", "È"),
            ("&eacute;", "é"), ("&Eacute;", "É"),
            ("&igrave;", "ì"), ("&Igrave;", "Ì"),
            ("&ograve;", "ò"), ("&Ograve;", "Ò"),
            ("&ugrave;", "ù"), ("&Ugrave;", "Ù"),
            ("&hellip;", "…"), ("&mdash;",  "—"), ("&ndash;", "–"),
        ]
        for (entity, replacement) in entities {
            result = result.replacingOccurrences(of: entity, with: replacement)
        }

        // Collapse runs of 3+ newlines into two
        while result.contains("\n\n\n") {
            result = result.replacingOccurrences(of: "\n\n\n", with: "\n\n")
        }

        return result.trimmingCharacters(in: .whitespacesAndNewlines)
    }
}
