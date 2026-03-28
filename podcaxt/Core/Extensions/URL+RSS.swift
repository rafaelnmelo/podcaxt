import Foundation

extension URL {
    /// Creates a URL from a string, validating that it has an http or https scheme.
    /// Returns `nil` if the string is not a valid URL or has an unsupported scheme.
    /// - Parameter string: Raw string to parse as an RSS feed URL.
    static func rss(from string: String) -> URL? {
        let trimmed = string.trimmingCharacters(in: .whitespacesAndNewlines)
        guard
            let url = URL(string: trimmed),
            url.scheme == "http" || url.scheme == "https"
        else { return nil }
        return url
    }
}
