import Foundation

enum HTMLTextFormatter {

    static func plainText(from html: String?) -> String {
        guard let html, !html.isEmpty else { return "" }

        // Replace block-level closing tags with newlines before stripping
        var result = html
            .replacingOccurrences(of: "</p>",   with: "\n\n", options: .caseInsensitive)
            .replacingOccurrences(of: "</div>", with: "\n",   options: .caseInsensitive)
            .replacingOccurrences(of: "</li>",  with: "\n",   options: .caseInsensitive)
            .replacingOccurrences(of: "<br>",   with: "\n",   options: .caseInsensitive)
            .replacingOccurrences(of: "<br/>",  with: "\n",   options: .caseInsensitive)
            .replacingOccurrences(of: "<br />", with: "\n",   options: .caseInsensitive)

        // Strip all remaining HTML tags
        result = result.replacingOccurrences(of: "<[^>]+>", with: "", options: .regularExpression)

        // Decode numeric entities first (&#8220; decimal and &#x201C; hex)
        result = decodeNumericEntities(result)

        // Decode named HTML entities (including Italian accented characters)
        let namedEntities: [(String, String)] = [
            ("&nbsp;",   " "),
            ("&amp;",    "&"),
            ("&lt;",     "<"),
            ("&gt;",     ">"),
            ("&quot;",   "\""),
            ("&#39;",    "'"),
            ("&apos;",   "'"),
            ("&laquo;",  "«"),  ("&raquo;",  "»"),
            ("&ldquo;",  "\u{201C}"), ("&rdquo;",  "\u{201D}"),
            ("&lsquo;",  "\u{2018}"), ("&rsquo;",  "\u{2019}"),
            ("&hellip;", "…"),  ("&mdash;",  "—"),  ("&ndash;", "–"),
            ("&agrave;", "à"),  ("&Agrave;", "À"),
            ("&egrave;", "è"),  ("&Egrave;", "È"),
            ("&eacute;", "é"),  ("&Eacute;", "É"),
            ("&igrave;", "ì"),  ("&Igrave;", "Ì"),
            ("&ograve;", "ò"),  ("&Ograve;", "Ò"),
            ("&ugrave;", "ù"),  ("&Ugrave;", "Ù"),
        ]
        for (entity, replacement) in namedEntities {
            result = result.replacingOccurrences(of: entity, with: replacement)
        }

        // Collapse runs of 3+ newlines to a single blank line
        while result.contains("\n\n\n") {
            result = result.replacingOccurrences(of: "\n\n\n", with: "\n\n")
        }

        return result.trimmingCharacters(in: .whitespacesAndNewlines)
    }

    // MARK: - Numeric entity decoding

    private static func decodeNumericEntities(_ string: String) -> String {
        guard string.contains("&#") else { return string }
        guard let regex = try? NSRegularExpression(pattern: "&#(x?)([0-9a-fA-F]+);") else { return string }

        var result = string
        let matches = regex.matches(in: string, range: NSRange(string.startIndex..., in: string))

        // Process in reverse so earlier string indices remain valid
        for match in matches.reversed() {
            guard let hexFlagRange = Range(match.range(at: 1), in: string),
                  let codeRange   = Range(match.range(at: 2), in: string),
                  let fullRange   = Range(match.range,         in: string) else { continue }

            let isHex = !string[hexFlagRange].isEmpty
            let codeStr = String(string[codeRange])

            let replacement: String
            if let codePoint = UInt32(codeStr, radix: isHex ? 16 : 10),
               let scalar    = Unicode.Scalar(codePoint) {
                replacement = String(scalar)
            } else {
                replacement = ""
            }
            result.replaceSubrange(fullRange, with: replacement)
        }
        return result
    }
}
