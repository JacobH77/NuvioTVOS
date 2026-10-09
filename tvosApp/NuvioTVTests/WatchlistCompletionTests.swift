import XCTest
@testable import NuvioTV

@MainActor
final class WatchlistCompletionTests: XCTestCase {
    private var previousLibraryProfile: String?
    private var previousWatchedProfile: String?
    private var previousSource: TraktLibrarySourceMode = .local
    private var testProfile = ""

    override func setUp() async throws {
        previousLibraryProfile = LibraryStore.activeProfileId
        previousWatchedProfile = WatchedStore.activeProfileId
        previousSource = TraktSettingsStore.librarySourceMode
        testProfile = "watchlist-test-\(UUID().uuidString)"
        LibraryStore.setActiveProfile(testProfile)
        WatchedStore.setActiveProfile(testProfile)
        TraktSettingsStore.librarySourceMode = .local
    }

    override func tearDown() async throws {
        LibraryStore.eraseProfile(testProfile)
        WatchedStore.eraseProfile(testProfile)
        LibraryStore.setActiveProfile(previousLibraryProfile)
        WatchedStore.setActiveProfile(previousWatchedProfile)
        TraktSettingsStore.librarySourceMode = previousSource
    }

    func testFinishedMovieIsRemovedAndOtherTitlesRemain() async throws {
        let movie = NuvioMeta(id: "watchlist-movie", name: "Movie", type: "movie")
        let other = NuvioMeta(id: "watchlist-other", name: "Other", type: "movie")
        LibraryStore.add(movie)
        LibraryStore.add(other)
        XCTAssertTrue(WatchedStore.markWatched(movie))
        await settleCompletion()
        XCTAssertFalse(LibraryStore.contains(metaId: movie.id, type: movie.type))
        XCTAssertTrue(LibraryStore.contains(metaId: other.id, type: other.type))
    }

    func testSeriesStaysAfterOneEpisodeAndLeavesAfterLastAiredEpisode() async throws {
        let series = NuvioMeta(
            id: "watchlist-series", name: "Series", type: "series",
            videos: [
                NuvioVideo(id: "watchlist-series:1:1", title: "One", season: 1, episode: 1),
                NuvioVideo(id: "watchlist-series:1:2", title: "Two", season: 1, episode: 2),
                NuvioVideo(id: "watchlist-series:0:1", title: "Special", season: 0, episode: 1)
            ]
        )
        LibraryStore.add(series)
        XCTAssertTrue(WatchedStore.markWatched(series, season: 1, episode: 1))
        await settleCompletion()
        XCTAssertTrue(LibraryStore.contains(metaId: series.id, type: series.type))
        XCTAssertTrue(WatchedStore.markWatched(series, season: 1, episode: 2))
        await settleCompletion()
        XCTAssertFalse(LibraryStore.contains(metaId: series.id, type: series.type))
    }

    func testCompletionCannotRemoveEntryFromAnotherProfile() async throws {
        let movie = NuvioMeta(id: "watchlist-shared", name: "Movie", type: "movie")
        LibraryStore.add(movie)
        XCTAssertTrue(WatchedStore.markWatched(movie))
        let otherProfile = testProfile + "-other"
        LibraryStore.setActiveProfile(otherProfile)
        WatchedStore.setActiveProfile(otherProfile)
        LibraryStore.add(movie)
        await settleCompletion()
        XCTAssertTrue(LibraryStore.contains(metaId: movie.id, type: movie.type))
        LibraryStore.eraseProfile(otherProfile)
        WatchedStore.eraseProfile(otherProfile)
    }

    private func settleCompletion() async {
        // Completion without a metadata fetch is one MainActor task.
        for _ in 0..<5 { await Task.yield() }
    }
}
