import XCTest
@testable import NuvioTV

@MainActor
final class WeTrakrAuthServiceTests: XCTestCase {
    private var suiteName: String!
    private var store: UserDefaults!
    private var memoryStorage: WeTrakrMemoryTokenStorage!

    override func setUp() {
        super.setUp()
        suiteName = "WeTrakrAuthServiceTests.\(UUID().uuidString)"
        store = UserDefaults(suiteName: suiteName)!
        memoryStorage = WeTrakrMemoryTokenStorage()
    }

    override func tearDown() {
        if let suiteName {
            UserDefaults.standard.removePersistentDomain(forName: suiteName)
        }
        store = nil
        memoryStorage = nil
        super.tearDown()
    }

    func testConfigAndCredentials() {
        XCTAssertFalse(WeTrakrConfig.isConfigured(in: store))
        XCTAssertEqual(WeTrakrConfig.clientID(in: store), "")

        store.set("wetrakr_client_123", forKey: SettingsKey.wetrakrClientID)
        store.set("wetrakr_secret_456", forKey: SettingsKey.wetrakrClientSecret)

        XCTAssertTrue(WeTrakrConfig.isConfigured(in: store))
        XCTAssertEqual(WeTrakrConfig.clientID(in: store), "wetrakr_client_123")
        XCTAssertEqual(WeTrakrConfig.clientSecret(in: store), "wetrakr_secret_456")
    }

    func testDeviceFlowSavingAndActiveCheck() {
        let clientID = "client_abc"
        store.set(clientID, forKey: SettingsKey.wetrakrClientID)

        let deviceResponse = WeTrakrDeviceCodeResponse(
            deviceCode: "dev_code_xyz",
            userCode: "K7PX4M",
            verificationUrl: "https://wetrakr.com/activate",
            expiresIn: 600,
            interval: 5
        )

        WeTrakrAuthStore.saveDeviceFlow(deviceResponse, clientID: clientID, store: store)

        let state = WeTrakrAuthStore.state(in: store, profileScope: "default", tokenStorage: memoryStorage)
        XCTAssertEqual(state.userCode, "K7PX4M")
        XCTAssertEqual(state.deviceCode, "dev_code_xyz")
        XCTAssertEqual(state.verificationURI, "https://wetrakr.com/activate")
        XCTAssertEqual(state.pollInterval, 5)
        XCTAssertTrue(state.hasActivePINFlow(in: store))
        XCTAssertFalse(state.isAuthenticated(in: store))

        WeTrakrAuthStore.clearDeviceFlow(store: store)
        let clearedState = WeTrakrAuthStore.state(in: store, profileScope: "default", tokenStorage: memoryStorage)
        XCTAssertNil(clearedState.userCode)
        XCTAssertFalse(clearedState.hasActivePINFlow(in: store))
    }

    func testTokenStorageAndAuthentication() {
        let clientID = "client_abc"
        store.set(clientID, forKey: SettingsKey.wetrakrClientID)

        WeTrakrAuthStore.saveToken(
            "access_token_123",
            refreshToken: "refresh_token_456",
            expiresIn: 604800,
            clientID: clientID,
            profileScope: "default",
            store: store,
            tokenStorage: memoryStorage
        )

        let state = WeTrakrAuthStore.state(in: store, profileScope: "default", tokenStorage: memoryStorage)
        XCTAssertTrue(state.isAuthenticated(in: store))
        XCTAssertEqual(state.accessToken, "access_token_123")
        XCTAssertEqual(state.refreshToken, "refresh_token_456")

        WeTrakrAuthStore.saveUser(
            username: "moviebuff",
            displayName: "Movie Buff",
            accountID: "1140",
            accountPlan: "vip",
            avatarURL: "https://media.wetrakr.com/avatars/test.webp",
            store: store
        )

        let userState = WeTrakrAuthStore.state(in: store, profileScope: "default", tokenStorage: memoryStorage)
        XCTAssertEqual(userState.username, "moviebuff")
        XCTAssertEqual(userState.displayName, "Movie Buff")
        XCTAssertEqual(userState.accountPlan, "vip")
        XCTAssertEqual(userState.accountID, "1140")

        WeTrakrAuthStore.clearAuth(profileScope: "default", store: store, tokenStorage: memoryStorage)
        let unauthState = WeTrakrAuthStore.state(in: store, profileScope: "default", tokenStorage: memoryStorage)
        XCTAssertFalse(unauthState.isAuthenticated(in: store))
        XCTAssertNil(unauthState.accessToken)
        XCTAssertNil(unauthState.username)
    }

    func testScrobblePayloadEncodability() throws {
        let moviePayload = WeTrakrScrobblePayload(
            movie: WeTrakrMediaPayload(
                title: "Inception",
                year: 2010,
                ids: WeTrakrSyncIDs(wetrakr: nil, imdb: "tt1375666", tmdb: 27205, tvdb: nil)
            ),
            show: nil,
            episode: nil,
            progress: 45.5,
            appVersion: "3.4.1"
        )

        let encoder = JSONEncoder()
        let data = try encoder.encode(moviePayload)
        let json = try JSONSerialization.jsonObject(with: data) as? [String: Any]

        XCTAssertNotNil(json?["movie"])
        XCTAssertNil(json?["show"])
        XCTAssertEqual(json?["progress"] as? Double, 45.5)
        XCTAssertEqual(json?["app_version"] as? String, "3.4.1")

        let showPayload = WeTrakrScrobblePayload(
            movie: nil,
            show: WeTrakrMediaPayload(
                title: "Breaking Bad",
                year: 2008,
                ids: WeTrakrSyncIDs(wetrakr: nil, imdb: "tt0903747", tmdb: 1396, tvdb: 81189)
            ),
            episode: WeTrakrEpisodePayload(season: 1, number: 1),
            progress: 85.0,
            appVersion: "3.4.1"
        )

        let showData = try encoder.encode(showPayload)
        let showJson = try JSONSerialization.jsonObject(with: showData) as? [String: Any]

        XCTAssertNotNil(showJson?["show"])
        XCTAssertNotNil(showJson?["episode"])
        XCTAssertEqual(showJson?["progress"] as? Double, 85.0)
    }

    func testRemoteTrackingStateWithWeTrakr() {
        store.set(TraktWatchProgressSource.wetrakr.rawValue, forKey: SettingsKey.traktWatchProgressSource)
        store.set(TraktLibrarySourceMode.wetrakr.rawValue, forKey: SettingsKey.traktLibrarySourceMode)

        // When not authenticated, isProgressSourceAuthenticated should be false
        XCTAssertFalse(RemoteTrackingState.isProgressSourceAuthenticated(.wetrakr, in: store))
        XCTAssertFalse(RemoteTrackingState.isLibrarySourceAuthenticated(.wetrakr, in: store))

        // Save valid token
        let clientID = "client_xyz"
        store.set(clientID, forKey: SettingsKey.wetrakrClientID)
        WeTrakrAuthStore.saveToken(
            "token_live",
            clientID: clientID,
            profileScope: "default",
            store: store,
            tokenStorage: memoryStorage
        )

        // WeTrakrRuntimeSession will check ProfileSettings / store
        let authState = WeTrakrRuntimeSession.authenticatedState(store: store, tokenStorage: memoryStorage, profileScope: "default")
        XCTAssertNotNil(authState)
    }

    func testWeTrakrIDsExtraction() {
        let imdbMeta = NuvioMeta(id: "tt0903747", name: "Breaking Bad", type: "series")
        let imdbIds = WeTrakrProgressService.wetrakrIDs(for: imdbMeta)
        XCTAssertEqual(imdbIds.imdb, "tt0903747")
        XCTAssertNil(imdbIds.tmdb)

        let tmdbEpisodeMeta = NuvioMeta(id: "tmdb:1396:1:1", name: "Breaking Bad", type: "series")
        let tmdbIds = WeTrakrProgressService.wetrakrIDs(for: tmdbEpisodeMeta)
        XCTAssertEqual(tmdbIds.tmdb, 1396)
        XCTAssertNil(tmdbIds.imdb)

        let tvdbMeta = NuvioMeta(id: "tvdb:81189", name: "Breaking Bad", type: "series")
        let tvdbIds = WeTrakrProgressService.wetrakrIDs(for: tvdbMeta)
        XCTAssertEqual(tvdbIds.tvdb, 81189)

        let wetrakrMeta = NuvioMeta(id: "wetrakr:126", name: "The Dark Knight", type: "movie")
        let wetrakrIds = WeTrakrProgressService.wetrakrIDs(for: wetrakrMeta)
        XCTAssertEqual(wetrakrIds.wetrakr, 126)
    }

    func testMoviePlayingItemDecoding() throws {
        let json = """
        {
            "id": 126,
            "type": "movie",
            "title": "The Dark Knight",
            "year": 2008,
            "ids": {
                "wetrakr": 126,
                "tmdb": 155,
                "imdb": "tt0468569"
            },
            "poster_path": "/qJ2tW6WMUDux911r6m7haRef0WH.jpg",
            "backdrop_path": "/nMKdUUepR0i5zn0y1T4CsSB5chy.jpg",
            "runtime": 152,
            "playback": {
                "status": "paused",
                "progress_percent": 45.2,
                "runtime_seconds": 9120,
                "tracked_at": "2026-08-15T21:31:34.956Z"
            }
        }
        """

        let decoder = JSONDecoder()
        let item = try decoder.decode(WeTrakrTrackingPlayingItemDTO.self, from: Data(json.utf8))

        XCTAssertFalse(item.resolvedIsSeries)
        XCTAssertEqual(item.resolvedMedia.title, "The Dark Knight")
        XCTAssertEqual(item.resolvedMedia.ids?.imdb, "tt0468569")
        XCTAssertEqual(item.resolvedMedia.ids?.tmdb, 155)
        XCTAssertEqual(item.resolvedProgressPercent, 45.2)
        XCTAssertEqual(item.resolvedRuntimeSeconds, 9120)
        XCTAssertNil(item.resolvedSeasonNumber)
        XCTAssertNil(item.resolvedEpisodeNumber)
    }

    func testEpisodePlayingItemDecoding() throws {
        let json = """
        {
            "id": 174658,
            "type": "episode",
            "title": "Pilot",
            "season_number": 1,
            "number": 1,
            "season_poster_path": "/1yeVJox3rjo2jBKrrihIMj7uoS9.jpg",
            "show": {
                "id": 1391953,
                "type": "show",
                "title": "Breaking Bad",
                "year": 2008,
                "ids": {
                    "wetrakr": 1391953,
                    "tmdb": 1396,
                    "imdb": "tt0903747",
                    "tvdb": 81189
                },
                "poster_path": "/ggFHVNu6YYI5L9pCfOacjizRGt.jpg"
            },
            "playback": {
                "status": "paused",
                "progress_percent": 35.0,
                "runtime_seconds": 3480,
                "tracked_at": "2026-08-15T21:31:34.956Z"
            }
        }
        """

        let decoder = JSONDecoder()
        let item = try decoder.decode(WeTrakrTrackingPlayingItemDTO.self, from: Data(json.utf8))

        XCTAssertTrue(item.resolvedIsSeries)
        XCTAssertEqual(item.resolvedMedia.title, "Breaking Bad")
        XCTAssertEqual(item.resolvedMedia.ids?.imdb, "tt0903747")
        XCTAssertEqual(item.resolvedMedia.ids?.tmdb, 1396)
        XCTAssertEqual(item.resolvedSeasonNumber, 1)
        XCTAssertEqual(item.resolvedEpisodeNumber, 1)
        XCTAssertEqual(item.resolvedEpisodeTitle, "Pilot")
        XCTAssertEqual(item.resolvedProgressPercent, 35.0)
        XCTAssertEqual(item.resolvedRuntimeSeconds, 3480)
    }

    func testScrobblePlayingNowDecoding() throws {
        let json = """
        {
            "status": "paused",
            "target": "movie",
            "progress_percent": 7.0,
            "runtime_seconds": 5880,
            "tracked_at": "2026-08-15T21:31:34.956Z",
            "media": {
                "id": 1053809,
                "type": "movie",
                "title": "Pizza Movie",
                "poster_path": "/3rovbwvxJ5eQrWrQnF1VfJoPcMD.jpg",
                "runtime": 98,
                "ids": {
                    "tmdb": 9999
                }
            }
        }
        """

        let decoder = JSONDecoder()
        let item = try decoder.decode(WeTrakrTrackingPlayingItemDTO.self, from: Data(json.utf8))

        XCTAssertFalse(item.resolvedIsSeries)
        XCTAssertEqual(item.resolvedMedia.title, "Pizza Movie")
        XCTAssertEqual(item.resolvedMedia.ids?.tmdb, 9999)
        XCTAssertEqual(item.resolvedProgressPercent, 7.0)
        XCTAssertEqual(item.resolvedRuntimeSeconds, 5880)
    }

    func testWatchedStoreSameContentMatchesSeriesTitleFallback() {
        let meta1 = NuvioMeta(
            id: "tt21097264",
            name: "East of Eden",
            description: nil,
            posterUrl: "https://image.tmdb.org/t/p/w500/test.jpg",
            backgroundUrl: nil,
            logoUrl: nil,
            imdbId: "tt21097264",
            tmdbId: 245318,
            type: "series",
            year: 2026,
            genres: nil,
            rating: nil,
            releaseInfo: nil,
            runtime: nil,
            cast: nil,
            director: nil,
            writer: nil,
            certification: nil,
            country: nil,
            language: nil,
            released: nil,
            status: nil,
            videos: nil,
            trailerYtIds: nil,
            externalRatings: nil,
            posterShape: nil
        )

        let meta2 = NuvioMeta(
            id: "wetrakr:1172533",
            name: "East of Eden",
            description: nil,
            posterUrl: "https://image.tmdb.org/t/p/w500/test.jpg",
            backgroundUrl: nil,
            logoUrl: nil,
            imdbId: nil,
            tmdbId: nil,
            type: "series",
            year: 2026,
            genres: nil,
            rating: nil,
            releaseInfo: nil,
            runtime: nil,
            cast: nil,
            director: nil,
            writer: nil,
            certification: nil,
            country: nil,
            language: nil,
            released: nil,
            status: nil,
            videos: nil,
            trailerYtIds: nil,
            externalRatings: nil,
            posterShape: nil
        )

        XCTAssertTrue(WatchedStore.sameContent(meta1, meta2), "Items with matching normalized series title and year should be treated as same content")
    }
}

