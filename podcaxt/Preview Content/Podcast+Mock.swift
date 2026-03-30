import Foundation

extension Podcast {
    static let mock = Podcast(
        title: "La Cotorrisa",
        link: URL(string: "https://www.lacotorrisa.com")!,
        language: "es",
        imageURL: URL(string: "https://megaphone.imgix.net/podcasts/la-cotorrisa.jpg")!,
        category: PodcastCategory(name: "Comedy", subcategory: "Stand-Up"),
        isExplicit: true,
        description: "La Cotorrisa es un podcast de comedia conducido por Slobotzky y Ricardo Pérez, donde comparten historias, anécdotas y reflexiones sobre la vida cotidiana con un toque de humor.",
        author: "Slobotzky & Ricardo Pérez",
        episodes: Episode.mocks
    )
}

extension RSSFeedURL {
    static let mock = RSSFeedURL(url: URL(string: "https://feeds.megaphone.fm/lacotorrisa")!)
}

extension Episode {
    static let mocks: [Episode] = [
        Episode(
            title: "Episodio 200 - El especial de aniversario",
            enclosureURL: URL(string: "https://traffic.megaphone.fm/episode200.mp3")!,
            enclosureMimeType: "audio/mpeg",
            enclosureLength: 52428800,
            guid: "lacotorrisa-ep200",
            isExplicit: true,
            description: "Celebramos 200 episodios con los mejores momentos, invitados especiales y muchas sorpresas para todos nuestros oyentes.",
            pubDate: Calendar.current.date(byAdding: .day, value: -3, to: .now),
            duration: 5400,
            imageURL: nil,
            author: "Slobotzky & Ricardo Pérez",
            season: 4,
            episodeNumber: 200,
            episodeType: .full
        ),
        Episode(
            title: "Episodio 199 - Historias de terror",
            enclosureURL: URL(string: "https://traffic.megaphone.fm/episode199.mp3")!,
            enclosureMimeType: "audio/mpeg",
            enclosureLength: 41943040,
            guid: "lacotorrisa-ep199",
            isExplicit: false,
            description: "Ricardo y Slobotzky comparten sus historias más aterradoras y los momentos que nunca olvidarán.",
            pubDate: Calendar.current.date(byAdding: .day, value: -10, to: .now),
            duration: 3780,
            imageURL: nil,
            author: "Slobotzky & Ricardo Pérez",
            season: 4,
            episodeNumber: 199,
            episodeType: .full
        ),
        Episode(
            title: "Trailer - Temporada 5",
            enclosureURL: URL(string: "https://traffic.megaphone.fm/trailer-s5.mp3")!,
            enclosureMimeType: "audio/mpeg",
            enclosureLength: 5242880,
            guid: "lacotorrisa-trailer-s5",
            isExplicit: false,
            description: "Un adelanto de lo que viene en la temporada 5 de La Cotorrisa.",
            pubDate: Calendar.current.date(byAdding: .day, value: -1, to: .now),
            duration: 120,
            imageURL: nil,
            author: "Slobotzky & Ricardo Pérez",
            season: 5,
            episodeNumber: nil,
            episodeType: .trailer
        )
    ]
}
