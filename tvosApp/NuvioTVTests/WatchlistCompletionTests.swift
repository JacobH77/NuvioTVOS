import XCTest
@testable import NuvioTV

final class WatchlistCompletionTests: XCTestCase {
    private let profileId = "watchlist-completion-\(UUID().uuidString)"
    private var previousLibraryProfileId: String?
    private var previousContinueWatchingProfileId: String?
    private var previousWatchedProfileId: String?
    private var settingsStore: UserDefaults!
    private var previousLibrarySource: Any?
    private var previousWatchProgressSource: Any?

    override func setUp() {
        super.setUp()
        previousLibraryProfileId = LibraryStore.activeProfileId
        previousContinueWatchingProfileId = ContinueWatchingStore.activeProfileId
        previousWatchedProfileId = WatchedStore.activeProfileId
        LibraryStore.setActiveProfile(profileId)
        ContinueWatchingStore.setActiveProfile(profileId)
        WatchedStore.setActiveProfile(profileId)
        LibraryStore.eraseProfile(profileId)
        ContinueWatchingStore.eraseProfile(profileId)
        WatchedStore.eraseProfile(profileId)

        settingsStore = ProfileSettings.current
        previousLibrarySource = settingsStore.object(forKey: SettingsKey.traktLibrarySourceMode)
        previousWatchProgressSource = settingsStore.object(forKey: SettingsKey.traktWatchProgressSource)
        settingsStore.set(TraktLibrarySourceMode.local.rawValue, forKey: SettingsKey.traktLibrarySourceMode)
        settingsStore.set(TraktWatchProgressSource.nuvioSync.rawValue, forKey: SettingsKey.traktWatchProgressSource)
    }

    override func tearDown() {
        LibraryStore.eraseProfile(profileId)
        ContinueWatchingStore.eraseProfile(profileId)
        WatchedStore.eraseProfile(profileId)
        ContinueWatchingStore.setActiveProfile(previousContinueWatchingProfileId)
        WatchedStore.setActiveProfile(previousWatchedProfileId)
        LibraryStore.setActiveProfile(previousLibraryProfileId)
        restore(previousLibrarySource, forKey: SettingsKey.traktLibrarySourceMode)
        restore(previousWatchProgressSource, forKey: SettingsKey.traktWatchProgressSource)
        super.tearDown()
    }

    func testCompletedMovieLeavesWatchlistAndWatchProgressSeparate() {
        let movie = NuvioMeta(id: "tt-watchlist-movie", name: "Watchlist Movie", type: "movie")
        LibraryStore.add(movie)

        XCTAssertTrue(LibraryStore.contains(metaId: movie.id, type: movie.type))
        XCTAssertTrue(ContinueWatchingStore.items().isEmpty)

        LibraryStore.setActiveProfile(nil)
        LibraryStore.setActiveProfile(profileId)
        XCTAssertTrue(LibraryStore.contains(metaId: movie.id, type: movie.type))

        XCTAssertTrue(WatchedStore.markWatched(movie))
        XCTAssertFalse(LibraryStore.contains(metaId: movie.id, type: movie.type))
        XCTAssertTrue(ContinueWatchingStore.items().isEmpty)
    }

    func testSeriesStaysOnWatchlistUntilEveryAiredEpisodeIsWatched() {
        let series = NuvioMeta(
            id: "tt-watchlist-series",
            name: "Watchlist Series",
            description: nil,
            posterUrl: nil,
            backgroundUrl: nil,
            logoUrl: nil,
            imdbId: "tt-watchlist-series",
            tmdbId: nil,
            type: "series",
            year: nil,
            genres: nil,
            rating: nil,
            releaseInfo: nil,
            runtime: nil,
            cast: nil,
            director: nil,
            writer: nil,
            certification: nil,
            country: nil,
            released: nil,
            videos: [
                episode(1),
                episode(2)
            ]
        )
        LibraryStore.add(series)

        XCTAssertTrue(WatchedStore.markWatched(series, season: 1, episode: 1))
        XCTAssertTrue(LibraryStore.contains(metaId: series.id, type: series.type))

        XCTAssertTrue(WatchedStore.markWatched(series, season: 1, episode: 2))
        XCTAssertFalse(LibraryStore.contains(metaId: series.id, type: series.type))
    }

    private func episode(_ number: Int) -> NuvioVideo {
        NuvioVideo(
            id: "tt-watchlist-series:1:\(number)",
            title: "Episode \(number)",
            season: 1,
            episode: number,
            thumbnail: nil,
            overview: nil,
            released: "2020-01-01",
            rating: nil
        )
    }

    private func restore(_ value: Any?, forKey key: String) {
        if let value {
            settingsStore.set(value, forKey: key)
        } else {
            settingsStore.removeObject(forKey: key)
        }
    }
}
