# podcaxt

An iOS app for listening to podcasts via RSS feed, built with SwiftUI.

## Features

- Add podcasts by RSS feed URL
- Recently accessed feed history
- Episode listing per podcast
- Audio player with playback queue, play/pause, next and previous controls
- Dynamic artwork with dominant color extracted from the cover
- Image and RSS feed caching

## Architecture

The project follows a layered architecture:

- `App` — entry point, navigation coordinator
- `Domain` — models (`Podcast`, `Episode`, `RSSFeedURL`)
- `Data` — services (`AudioPlayerService`, `RSSService`, `ImageService`, `PersistenceService`) and cache
- `Presentation` — views and view models per feature (`RSSInput`, `PodcastDetail`, `Player`, `Settings`)
- `Core` — shared extensions and utilities

## Requirements

- iOS 17+
- Xcode 15+
