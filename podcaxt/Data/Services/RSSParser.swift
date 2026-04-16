import Foundation

protocol RSSParsing {
    func parse(_ data: Data) throws -> Podcast
}

final class RSSParser: RSSParsing {
    /// Parses raw RSS `Data` into a `Podcast`.
    /// Each call creates an isolated ParseContext as delegate, making it fully thread-safe.
    func parse(_ data: Data) throws -> Podcast {
        let context = ParseContext()
        let xmlParser = XMLParser(data: data)
        xmlParser.delegate = context
        guard xmlParser.parse(), let podcast = context.podcast else {
            throw RSSParserError.invalidFeed
        }
        return podcast
    }
}

// MARK: - ParseContext

private final class ParseContext: NSObject, XMLParserDelegate {
    var podcast: Podcast?

    private var episodes: [Episode] = []
    private var currentEpisode: EpisodeBuilder?
    private var currentText = ""
    private var podcastBuilder = PodcastBuilder()

    /// Called when the parser encounters a start tag.
    /// Initializes episode builders and extracts attributes like enclosure and image URLs.
    func parser(_ parser: XMLParser, didStartElement element: String, namespaceURI: String?, qualifiedName: String?, attributes: [String: String] = [:]) {
        currentText = ""

        if element == "item" {
            currentEpisode = EpisodeBuilder()
        }

        if element == "enclosure", let episode = currentEpisode {
            episode.enclosureURL = attributes["url"].flatMap(URL.init)
            episode.enclosureMimeType = attributes["type"]
            episode.enclosureLength = attributes["length"].flatMap(Int.init) ?? 0
        }

        if element == "itunes:image" {
            let href = attributes["href"].flatMap(URL.init)
            if currentEpisode != nil {
                currentEpisode?.imageURL = href
            } else {
                podcastBuilder.imageURL = href
            }
        }
    }

    /// Accumulates text content between XML tags.
    func parser(_ parser: XMLParser, foundCharacters string: String) {
        currentText += string
    }

    /// Called when the parser encounters an end tag.
    /// Assigns accumulated text to the appropriate podcast or episode field.
    func parser(_ parser: XMLParser, didEndElement element: String, namespaceURI: String?, qualifiedName: String?) {
        let text = currentText.trimmingCharacters(in: .whitespacesAndNewlines)

        if let episode = currentEpisode {
            switch element {
            case "title":              episode.title = text
            case "description":        episode.description = text.strippingHTML
            case "guid":               episode.guid = text
            case "pubDate":            episode.pubDate = DateFormatter.rss.date(from: text)
            case "itunes:duration":    episode.duration = parseDuration(text)
            case "itunes:author":      episode.author = text
            case "itunes:season":      episode.season = Int(text)
            case "itunes:episode":     episode.episodeNumber = Int(text)
            case "itunes:episodeType": episode.episodeType = EpisodeType(rawValue: text) ?? .full
            case "itunes:explicit":    episode.isExplicit = text == "true"
            case "item":
                if let built = episode.build() { episodes.append(built) }
                currentEpisode = nil
            default: break
            }
        } else {
            switch element {
            case "title":            podcastBuilder.title = text
            case "link":             podcastBuilder.link = URL(string: text)
            case "language":         podcastBuilder.language = text
            case "description":      podcastBuilder.description = text.strippingHTML
            case "itunes:author":    podcastBuilder.author = text
            case "itunes:explicit":  podcastBuilder.isExplicit = text == "true"
            case "itunes:category":  podcastBuilder.categoryName = text
            case "channel":          podcast = podcastBuilder.build(episodes: episodes)
            default: break
            }
        }
    }
}

// MARK: - Builders

private final class PodcastBuilder {
    var title: String?
    var link: URL?
    var language: String?
    var imageURL: URL?
    var categoryName: String?
    var isExplicit = false
    var description = ""
    var author = ""

    /// Builds a Podcast instance from accumulated data.
    /// Returns nil if required fields are missing.
    func build(episodes: [Episode]) -> Podcast? {
        guard let title, let link, let language, let imageURL else { return nil }
        return Podcast(
            title: title,
            link: link,
            language: language,
            imageURL: imageURL,
            category: PodcastCategory(name: categoryName ?? ""),
            isExplicit: isExplicit,
            description: description,
            author: author,
            episodes: episodes
        )
    }
}

private final class EpisodeBuilder {
    var title: String?
    var enclosureURL: URL?
    var enclosureMimeType: String?
    var enclosureLength = 0
    var guid: String?
    var isExplicit = false
    var description = ""
    var pubDate: Date?
    var duration: TimeInterval?
    var imageURL: URL?
    var author: String?
    var season: Int?
    var episodeNumber: Int?
    var episodeType: EpisodeType = .full

    /// Builds an Episode instance from accumulated data.
    /// Returns nil if required fields are missing.
    func build() -> Episode? {
        guard let title, let enclosureURL, let guid else { return nil }
        return Episode(
            title: title,
            enclosureURL: enclosureURL,
            enclosureMimeType: enclosureMimeType ?? "audio/mpeg",
            enclosureLength: enclosureLength,
            guid: guid,
            isExplicit: isExplicit,
            description: description,
            pubDate: pubDate,
            duration: duration,
            imageURL: imageURL,
            author: author,
            season: season,
            episodeNumber: episodeNumber,
            episodeType: episodeType
        )
    }
}

// MARK: - Helpers

/// Parses duration string from RSS feed into seconds.
/// Supports formats: seconds ("123"), minutes:seconds ("12:34"), or hours:minutes:seconds ("1:23:45").
private func parseDuration(_ text: String) -> TimeInterval? {
    let parts = text.split(separator: ":").compactMap { Double($0) }
    switch parts.count {
    case 1: return parts[0]
    case 2: return parts[0] * 60 + parts[1]
    case 3: return parts[0] * 3600 + parts[1] * 60 + parts[2]
    default: return nil
    }
}

private extension DateFormatter {
    static let rss: DateFormatter = {
        let f = DateFormatter()
        f.locale = Locale(identifier: "en_US_POSIX")
        f.dateFormat = "EEE, dd MMM yyyy HH:mm:ss Z"
        return f
    }()
}

enum RSSParserError: Error {
    case invalidFeed
}
