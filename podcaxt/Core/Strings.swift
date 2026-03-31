enum Strings {
    enum Cache {
        static let imageCacheDirectory = "ImageCache"
        static let rssCacheDirectory = "RSSCache"
        static let metadataExtension = ".meta"
    }

    enum Persistence {
        static let rssFeedHistoryKey = "rss_feed_history"
    }

    enum App {
        static let title = "Buscar"
    }

    enum RSSInput {
        static let urlPlaceholder = "Cole uma URL de feed RSS ..."
        static let loadButton = "Carregar Podcast"
        static let invalidURL = "URL Inválida"
        static let recentHeader = "Recente"
        static let clearButton = "Limpar"
    }

    enum PodcastDetail {
        static func episodesHeader(_ count: Int) -> String { "\(count) Episodes" }
    }

    enum Tab {
        static let search = "Buscar"
        static let settings = "Configurações"
    }

    enum Settings {
        static let navigationTitle = "Configurações"
        static let storageSection = "Armazenamento"
        static let cacheLabel = "Cache"
        static let clearCache = "Limpar Cache"
        static let calculating = "Calculando..."
        static let clearCacheConfirmTitle = "Limpar Cache"
        static let clearCacheConfirmMessage = "Isso removerá todos os dados de RSS e imagens em cache."
        static let clearCacheSuccessTitle = "Cache Limpo"
        static let clearCacheSuccessMessage = "O cache foi removido com sucesso."
        static let clearCacheFailureTitle = "Erro ao Limpar"
    }

    enum General {
        static let ok = "OK"
        static let cancel = "Cancelar"
    }
}
