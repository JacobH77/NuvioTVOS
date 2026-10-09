import Foundation
import SwiftUI

// MARK: - WeTrakr Identifiers & Payloads

struct WeTrakrSyncIDs: Codable, Equatable {
    let wetrakr: Int?
    let imdb: String?
    let tmdb: Int?
    let tvdb: Int?

    enum CodingKeys: String, CodingKey {
        case wetrakr, imdb, tmdb, tvdb
    }

    init(
        wetrakr: Int? = nil,
        imdb: String? = nil,
        tmdb: Int? = nil,
        tvdb: Int? = nil
    ) {
        self.wetrakr = wetrakr
        self.imdb = imdb
        self.tmdb = tmdb
        self.tvdb = tvdb
    }

    var hasUsableIdentifier: Bool {
        wetrakr != nil || imdb != nil || tmdb != nil || tvdb != nil
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        wetrakr = Self.flexibleInt(in: container, forKey: .wetrakr)
        tmdb = Self.flexibleInt(in: container, forKey: .tmdb)
        tvdb = Self.flexibleInt(in: container, forKey: .tvdb)
        imdb = try container.decodeIfPresent(String.self, forKey: .imdb)
    }

    private static func flexibleInt(
        in container: KeyedDecodingContainer<CodingKeys>,
        forKey key: CodingKeys
    ) -> Int? {
        if let value = try? container.decode(Int.self, forKey: key) {
            return value
        }
        if let value = try? container.decode(String.self, forKey: key) {
            return Int(value)
        }
        return nil
    }
}

struct WeTrakrMediaPayload: Codable, Equatable {
    let title: String?
    let year: Int?
    let ids: WeTrakrSyncIDs?
    let status: String?

    init(
        title: String? = nil,
        year: Int? = nil,
        ids: WeTrakrSyncIDs? = nil,
        status: String? = nil
    ) {
        self.title = title
        self.year = year
        self.ids = ids
        self.status = status
    }
}

struct WeTrakrEpisodePayload: Codable, Equatable {
    let season: Int
    let number: Int

    init(season: Int, number: Int) {
        self.season = season
        self.number = number
    }
}

struct WeTrakrScrobblePayload: Codable {
    let movie: WeTrakrMediaPayload?
    let show: WeTrakrMediaPayload?
    let episode: WeTrakrEpisodePayload?
    let progress: Double
    let appVersion: String?

    enum CodingKeys: String, CodingKey {
        case movie, show, episode, progress
        case appVersion = "app_version"
    }
}

struct WeTrakrCancelPlaybackPayload: Codable {
    let movie: WeTrakrMediaPayload?
    let show: WeTrakrMediaPayload?
    let episode: WeTrakrEpisodePayload?
}

// MARK: - Tracking DTOs

struct WeTrakrMediaDTO: Codable {
    let id: Int?
    let type: String?
    let title: String?
    let originalTitle: String?
    let overview: String?
    let year: Int?
    let releaseDate: String?
    let ids: WeTrakrSyncIDs?
    let posterPath: String?
    let backdropPath: String?
    let runtime: Double?

    enum CodingKeys: String, CodingKey {
        case id, type, title, overview, year, ids
        case originalTitle = "original_title"
        case releaseDate = "release_date"
        case posterPath = "poster_path"
        case backdropPath = "backdrop_path"
        case runtime
    }

    init(
        id: Int? = nil,
        type: String? = nil,
        title: String? = nil,
        originalTitle: String? = nil,
        overview: String? = nil,
        year: Int? = nil,
        releaseDate: String? = nil,
        ids: WeTrakrSyncIDs? = nil,
        posterPath: String? = nil,
        backdropPath: String? = nil,
        runtime: Double? = nil
    ) {
        self.id = id
        self.type = type
        self.title = title
        self.originalTitle = originalTitle
        self.overview = overview
        self.year = year
        self.releaseDate = releaseDate
        self.ids = ids
        self.posterPath = posterPath
        self.backdropPath = backdropPath
        self.runtime = runtime
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        id = Self.flexibleInt(in: container, forKey: .id)
        type = try container.decodeIfPresent(String.self, forKey: .type)
        title = try container.decodeIfPresent(String.self, forKey: .title)
        originalTitle = try container.decodeIfPresent(String.self, forKey: .originalTitle)
        overview = try container.decodeIfPresent(String.self, forKey: .overview)
        year = Self.flexibleInt(in: container, forKey: .year)
        releaseDate = try container.decodeIfPresent(String.self, forKey: .releaseDate)
        ids = try container.decodeIfPresent(WeTrakrSyncIDs.self, forKey: .ids)
        posterPath = try container.decodeIfPresent(String.self, forKey: .posterPath)
        backdropPath = try container.decodeIfPresent(String.self, forKey: .backdropPath)
        runtime = Self.flexibleDouble(in: container, forKey: .runtime)
    }

    private static func flexibleInt(
        in container: KeyedDecodingContainer<CodingKeys>,
        forKey key: CodingKeys
    ) -> Int? {
        if let value = try? container.decode(Int.self, forKey: key) { return value }
        if let value = try? container.decode(String.self, forKey: key) { return Int(value) }
        return nil
    }

    private static func flexibleDouble(
        in container: KeyedDecodingContainer<CodingKeys>,
        forKey key: CodingKeys
    ) -> Double? {
        if let value = try? container.decode(Double.self, forKey: key) { return value }
        if let value = try? container.decode(Int.self, forKey: key) { return Double(value) }
        if let value = try? container.decode(String.self, forKey: key) { return Double(value) }
        return nil
    }
}

struct WeTrakrEpisodeDTO: Codable {
    let id: Int?
    let seasonNumber: Int?
    let number: Int?
    let season: Int?
    let title: String?
    let overview: String?
    let runtime: Double?
    let seasonPosterPath: String?
    let show: WeTrakrMediaDTO?

    enum CodingKeys: String, CodingKey {
        case id, number, season, title, overview, runtime, show
        case seasonNumber = "season_number"
        case seasonPosterPath = "season_poster_path"
    }

    init(
        id: Int? = nil,
        seasonNumber: Int? = nil,
        number: Int? = nil,
        season: Int? = nil,
        title: String? = nil,
        overview: String? = nil,
        runtime: Double? = nil,
        seasonPosterPath: String? = nil,
        show: WeTrakrMediaDTO? = nil
    ) {
        self.id = id
        self.seasonNumber = seasonNumber
        self.number = number
        self.season = season
        self.title = title
        self.overview = overview
        self.runtime = runtime
        self.seasonPosterPath = seasonPosterPath
        self.show = show
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        id = Self.flexibleInt(in: container, forKey: .id)
        seasonNumber = Self.flexibleInt(in: container, forKey: .seasonNumber)
        number = Self.flexibleInt(in: container, forKey: .number)
        season = Self.flexibleInt(in: container, forKey: .season)
        title = try container.decodeIfPresent(String.self, forKey: .title)
        overview = try container.decodeIfPresent(String.self, forKey: .overview)
        runtime = Self.flexibleDouble(in: container, forKey: .runtime)
        seasonPosterPath = try container.decodeIfPresent(String.self, forKey: .seasonPosterPath)
        show = try container.decodeIfPresent(WeTrakrMediaDTO.self, forKey: .show)
    }

    private static func flexibleInt(
        in container: KeyedDecodingContainer<CodingKeys>,
        forKey key: CodingKeys
    ) -> Int? {
        if let value = try? container.decode(Int.self, forKey: key) { return value }
        if let value = try? container.decode(String.self, forKey: key) { return Int(value) }
        return nil
    }

    private static func flexibleDouble(
        in container: KeyedDecodingContainer<CodingKeys>,
        forKey key: CodingKeys
    ) -> Double? {
        if let value = try? container.decode(Double.self, forKey: key) { return value }
        if let value = try? container.decode(Int.self, forKey: key) { return Double(value) }
        if let value = try? container.decode(String.self, forKey: key) { return Double(value) }
        return nil
    }
}

struct WeTrakrPlaybackInfoDTO: Codable {
    let status: String?
    let progressPercent: Double?
    let runtimeSeconds: Double?
    let trackedAt: String?
    let updatedAt: String?

    enum CodingKeys: String, CodingKey {
        case status
        case progressPercent = "progress_percent"
        case runtimeSeconds = "runtime_seconds"
        case trackedAt = "tracked_at"
        case updatedAt = "updated_at"
    }

    init(
        status: String? = nil,
        progressPercent: Double? = nil,
        runtimeSeconds: Double? = nil,
        trackedAt: String? = nil,
        updatedAt: String? = nil
    ) {
        self.status = status
        self.progressPercent = progressPercent
        self.runtimeSeconds = runtimeSeconds
        self.trackedAt = trackedAt
        self.updatedAt = updatedAt
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        status = try container.decodeIfPresent(String.self, forKey: .status)
        progressPercent = Self.flexibleDouble(in: container, forKey: .progressPercent)
        runtimeSeconds = Self.flexibleDouble(in: container, forKey: .runtimeSeconds)
        trackedAt = try container.decodeIfPresent(String.self, forKey: .trackedAt)
        updatedAt = try container.decodeIfPresent(String.self, forKey: .updatedAt)
    }

    private static func flexibleDouble(
        in container: KeyedDecodingContainer<CodingKeys>,
        forKey key: CodingKeys
    ) -> Double? {
        if let value = try? container.decode(Double.self, forKey: key) { return value }
        if let value = try? container.decode(Int.self, forKey: key) { return Double(value) }
        if let value = try? container.decode(String.self, forKey: key) { return Double(value) }
        return nil
    }
}

struct WeTrakrTrackingPlayingItemDTO: Codable {
    // Top-level / Common fields
    let id: Int?
    let type: String?
    let title: String?
    let originalTitle: String?
    let overview: String?
    let year: Int?
    let releaseDate: String?
    let posterPath: String?
    let backdropPath: String?
    let seasonPosterPath: String?
    let runtime: Double?
    let ids: WeTrakrSyncIDs?

    // Episode specifics at top level
    let seasonNumber: Int?
    let number: Int?
    let season: Int?
    let show: WeTrakrMediaDTO?

    // Nested / Wrapped structures
    let media: WeTrakrMediaDTO?
    let episode: WeTrakrEpisodeDTO?
    let playback: WeTrakrPlaybackInfoDTO?

    // Scrobble Playing & Trakt-compatibility fields
    let status: String?
    let target: String?
    let progressPercent: Double?
    let runtimeSeconds: Double?
    let trackedAt: String?
    let updatedAt: String?
    let watchedAt: String?
    let pausedAt: String?
    let progress: Double?
    let movie: WeTrakrMediaDTO?

    enum CodingKeys: String, CodingKey {
        case id, type, title, overview, year, ids, number, season, show, media, episode, playback, status, target, movie, progress
        case originalTitle = "original_title"
        case releaseDate = "release_date"
        case posterPath = "poster_path"
        case backdropPath = "backdrop_path"
        case seasonPosterPath = "season_poster_path"
        case runtime
        case seasonNumber = "season_number"
        case progressPercent = "progress_percent"
        case runtimeSeconds = "runtime_seconds"
        case trackedAt = "tracked_at"
        case updatedAt = "updated_at"
        case watchedAt = "watched_at"
        case pausedAt = "paused_at"
    }

    init(
        id: Int? = nil,
        type: String? = nil,
        title: String? = nil,
        originalTitle: String? = nil,
        overview: String? = nil,
        year: Int? = nil,
        releaseDate: String? = nil,
        posterPath: String? = nil,
        backdropPath: String? = nil,
        seasonPosterPath: String? = nil,
        runtime: Double? = nil,
        ids: WeTrakrSyncIDs? = nil,
        seasonNumber: Int? = nil,
        number: Int? = nil,
        season: Int? = nil,
        show: WeTrakrMediaDTO? = nil,
        media: WeTrakrMediaDTO? = nil,
        episode: WeTrakrEpisodeDTO? = nil,
        playback: WeTrakrPlaybackInfoDTO? = nil,
        status: String? = nil,
        target: String? = nil,
        progressPercent: Double? = nil,
        runtimeSeconds: Double? = nil,
        trackedAt: String? = nil,
        updatedAt: String? = nil,
        watchedAt: String? = nil,
        pausedAt: String? = nil,
        progress: Double? = nil,
        movie: WeTrakrMediaDTO? = nil
    ) {
        self.id = id
        self.type = type
        self.title = title
        self.originalTitle = originalTitle
        self.overview = overview
        self.year = year
        self.releaseDate = releaseDate
        self.posterPath = posterPath
        self.backdropPath = backdropPath
        self.seasonPosterPath = seasonPosterPath
        self.runtime = runtime
        self.ids = ids
        self.seasonNumber = seasonNumber
        self.number = number
        self.season = season
        self.show = show
        self.media = media
        self.episode = episode
        self.playback = playback
        self.status = status
        self.target = target
        self.progressPercent = progressPercent
        self.runtimeSeconds = runtimeSeconds
        self.trackedAt = trackedAt
        self.updatedAt = updatedAt
        self.watchedAt = watchedAt
        self.pausedAt = pausedAt
        self.progress = progress
        self.movie = movie
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        id = Self.flexibleInt(in: container, forKey: .id)
        type = try container.decodeIfPresent(String.self, forKey: .type)
        title = try container.decodeIfPresent(String.self, forKey: .title)
        originalTitle = try container.decodeIfPresent(String.self, forKey: .originalTitle)
        overview = try container.decodeIfPresent(String.self, forKey: .overview)
        year = Self.flexibleInt(in: container, forKey: .year)
        releaseDate = try container.decodeIfPresent(String.self, forKey: .releaseDate)
        posterPath = try container.decodeIfPresent(String.self, forKey: .posterPath)
        backdropPath = try container.decodeIfPresent(String.self, forKey: .backdropPath)
        seasonPosterPath = try container.decodeIfPresent(String.self, forKey: .seasonPosterPath)
        runtime = Self.flexibleDouble(in: container, forKey: .runtime)
        ids = try container.decodeIfPresent(WeTrakrSyncIDs.self, forKey: .ids)
        seasonNumber = Self.flexibleInt(in: container, forKey: .seasonNumber)
        number = Self.flexibleInt(in: container, forKey: .number)
        season = Self.flexibleInt(in: container, forKey: .season)
        show = try container.decodeIfPresent(WeTrakrMediaDTO.self, forKey: .show)
        media = try container.decodeIfPresent(WeTrakrMediaDTO.self, forKey: .media)
        episode = try container.decodeIfPresent(WeTrakrEpisodeDTO.self, forKey: .episode)
        playback = try container.decodeIfPresent(WeTrakrPlaybackInfoDTO.self, forKey: .playback)
        status = try container.decodeIfPresent(String.self, forKey: .status)
        target = try container.decodeIfPresent(String.self, forKey: .target)
        progressPercent = Self.flexibleDouble(in: container, forKey: .progressPercent)
        runtimeSeconds = Self.flexibleDouble(in: container, forKey: .runtimeSeconds)
        trackedAt = try container.decodeIfPresent(String.self, forKey: .trackedAt)
        updatedAt = try container.decodeIfPresent(String.self, forKey: .updatedAt)
        watchedAt = try container.decodeIfPresent(String.self, forKey: .watchedAt)
        pausedAt = try container.decodeIfPresent(String.self, forKey: .pausedAt)
        progress = Self.flexibleDouble(in: container, forKey: .progress)
        movie = try container.decodeIfPresent(WeTrakrMediaDTO.self, forKey: .movie)
    }

    private static func flexibleInt(
        in container: KeyedDecodingContainer<CodingKeys>,
        forKey key: CodingKeys
    ) -> Int? {
        if let value = try? container.decode(Int.self, forKey: key) { return value }
        if let value = try? container.decode(String.self, forKey: key) { return Int(value) }
        return nil
    }

    private static func flexibleDouble(
        in container: KeyedDecodingContainer<CodingKeys>,
        forKey key: CodingKeys
    ) -> Double? {
        if let value = try? container.decode(Double.self, forKey: key) { return value }
        if let value = try? container.decode(Int.self, forKey: key) { return Double(value) }
        if let value = try? container.decode(String.self, forKey: key) { return Double(value) }
        return nil
    }

    var resolvedIsSeries: Bool {
        if let type = type?.lowercased(), type == "show" || type == "series" || type == "episode" {
            return true
        }
        if let target = target?.lowercased(), target == "show" || target == "series" || target == "episode" {
            return true
        }
        if show != nil || episode != nil || seasonNumber != nil || number != nil || season != nil {
            return true
        }
        if let mediaType = media?.type?.lowercased(), mediaType == "show" || mediaType == "series" {
            return true
        }
        return false
    }

    var resolvedMedia: WeTrakrMediaDTO {
        if let show { return show }
        if let media { return media }
        if let movie { return movie }
        return WeTrakrMediaDTO(
            id: id,
            type: type,
            title: title,
            originalTitle: originalTitle,
            overview: overview,
            year: year,
            releaseDate: releaseDate,
            ids: ids,
            posterPath: posterPath,
            backdropPath: backdropPath,
            runtime: runtime
        )
    }

    var resolvedSeasonNumber: Int? {
        seasonNumber ?? season ?? episode?.seasonNumber ?? episode?.season
    }

    var resolvedEpisodeNumber: Int? {
        number ?? episode?.number
    }

    var resolvedEpisodeTitle: String? {
        if resolvedIsSeries {
            return episode?.title ?? (seasonNumber != nil ? title : nil)
        }
        return nil
    }

    var resolvedProgressPercent: Double? {
        if let p = playback?.progressPercent, p > 0 { return p }
        if let p = progressPercent, p > 0 { return p }
        if let p = progress, p > 0 {
            return p <= 1.0 ? p * 100.0 : p
        }
        return nil
    }

    var resolvedRuntimeSeconds: Double? {
        if let r = playback?.runtimeSeconds, r > 0 { return r }
        if let r = runtimeSeconds, r > 0 { return r }
        if let r = episode?.runtime, r > 0 {
            return r > 600 ? r : r * 60.0
        }
        if let r = runtime, r > 0 {
            return r > 600 ? r : r * 60.0
        }
        if let r = media?.runtime, r > 0 {
            return r > 600 ? r : r * 60.0
        }
        return nil
    }

    var resolvedLastWatchedAt: Date {
        let dateString = playback?.trackedAt
            ?? playback?.updatedAt
            ?? trackedAt
            ?? updatedAt
            ?? watchedAt
            ?? pausedAt
        if let d = WeTrakrProgressService.dateFromISO8601(dateString) {
            return d
        }
        return Date()
    }
}

struct WeTrakrTrackingHistoryItemDTO: Codable {
    let id: String?
    let media: WeTrakrMediaDTO?
    let movie: WeTrakrMediaDTO?
    let episode: WeTrakrEpisodeDTO?
    let watchedAt: String?

    enum CodingKeys: String, CodingKey {
        case id, media, movie, episode
        case watchedAt = "watched_at"
    }

    init(
        id: String? = nil,
        media: WeTrakrMediaDTO? = nil,
        movie: WeTrakrMediaDTO? = nil,
        episode: WeTrakrEpisodeDTO? = nil,
        watchedAt: String? = nil
    ) {
        self.id = id
        self.media = media
        self.movie = movie
        self.episode = episode
        self.watchedAt = watchedAt
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        if let str = try? container.decode(String.self, forKey: .id) {
            id = str
        } else if let num = try? container.decode(Int.self, forKey: .id) {
            id = String(num)
        } else {
            id = nil
        }
        media = try container.decodeIfPresent(WeTrakrMediaDTO.self, forKey: .media)
        movie = try container.decodeIfPresent(WeTrakrMediaDTO.self, forKey: .movie)
        episode = try container.decodeIfPresent(WeTrakrEpisodeDTO.self, forKey: .episode)
        watchedAt = try container.decodeIfPresent(String.self, forKey: .watchedAt)
    }
}

// MARK: - Mutate Tracking Payloads

struct WeTrakrTrackingAddPayload: Codable {
    let movies: [WeTrakrMediaPayload]?
    let shows: [WeTrakrShowTrackingPayload]?
    let allowRewatch: Bool?

    enum CodingKeys: String, CodingKey {
        case movies, shows
        case allowRewatch = "allow_rewatch"
    }

    init(
        movies: [WeTrakrMediaPayload]? = nil,
        shows: [WeTrakrShowTrackingPayload]? = nil,
        allowRewatch: Bool? = nil
    ) {
        self.movies = movies
        self.shows = shows
        self.allowRewatch = allowRewatch
    }
}

struct WeTrakrShowTrackingPayload: Codable {
    let title: String?
    let year: Int?
    let ids: WeTrakrSyncIDs?
    let status: String?
    let seasons: [WeTrakrSeasonTrackingPayload]?

    init(
        title: String? = nil,
        year: Int? = nil,
        ids: WeTrakrSyncIDs? = nil,
        status: String? = nil,
        seasons: [WeTrakrSeasonTrackingPayload]? = nil
    ) {
        self.title = title
        self.year = year
        self.ids = ids
        self.status = status
        self.seasons = seasons
    }
}

struct WeTrakrSeasonTrackingPayload: Codable {
    let number: Int
    let status: String?
    let episodes: [WeTrakrEpisodeTrackingPayload]?

    init(
        number: Int,
        status: String? = nil,
        episodes: [WeTrakrEpisodeTrackingPayload]? = nil
    ) {
        self.number = number
        self.status = status
        self.episodes = episodes
    }
}

struct WeTrakrEpisodeTrackingPayload: Codable {
    let number: Int
    let status: String?

    init(
        number: Int,
        status: String? = nil
    ) {
        self.number = number
        self.status = status
    }
}

struct WeTrakrTrackingRemovePayload: Codable {
    let movies: [WeTrakrMediaPayload]?
    let shows: [WeTrakrShowTrackingPayload]?

    init(
        movies: [WeTrakrMediaPayload]? = nil,
        shows: [WeTrakrShowTrackingPayload]? = nil
    ) {
        self.movies = movies
        self.shows = shows
    }
}

struct WeTrakrWatchAllSeasonPayload: Codable {
    let show: WeTrakrMediaPayload
    let seasonNumber: Int

    enum CodingKeys: String, CodingKey {
        case show
        case seasonNumber = "season_number"
    }
}

// MARK: - WeTrakr Progress & Scrobble Service

@MainActor
struct WeTrakrProgressService {
    private static let client = WeTrakrAPIClient()

    static func reportPlayback(
        meta: NuvioMeta,
        position: Double,
        duration: Double,
        season: Int?,
        episode: Int?,
        action: TraktScrobbleAction,
        store: UserDefaults = ProfileSettings.current
    ) async -> Bool {
        guard let token = WeTrakrRuntimeSession.authenticatedState(store: store)?.accessToken,
              !token.isEmpty,
              position.isFinite,
              duration.isFinite,
              duration > 0 else {
            return false
        }

        let clientID = WeTrakrConfig.clientID(in: store)
        let progress = min(max(position / duration * 100.0, 0.01), 100.0)
        let ids = wetrakrIDs(for: meta)

        guard ids.hasUsableIdentifier else {
            return false
        }

        let endpoint: String
        switch action {
        case .start:
            endpoint = "/scrobble/start"
        case .pause:
            endpoint = "/scrobble/pause"
        case .stop:
            endpoint = "/scrobble/stop"
        }

        let payload: WeTrakrScrobblePayload
        if meta.isSeries {
            guard let s = season, s >= 0, let ep = episode, ep > 0 else { return false }
            payload = WeTrakrScrobblePayload(
                movie: nil,
                show: WeTrakrMediaPayload(title: meta.name, year: meta.year, ids: ids),
                episode: WeTrakrEpisodePayload(season: s, number: ep),
                progress: progress,
                appVersion: WeTrakrConfig.appVersion
            )
        } else {
            payload = WeTrakrScrobblePayload(
                movie: WeTrakrMediaPayload(title: meta.name, year: meta.year, ids: ids),
                show: nil,
                episode: nil,
                progress: progress,
                appVersion: WeTrakrConfig.appVersion
            )
        }

        do {
            let result: WeTrakrHTTPResult<Data> = try await client.postRaw(
                path: endpoint,
                body: payload,
                accessToken: token,
                clientID: clientID
            )
            _ = try result.valueOrThrow()
            NotificationCenter.default.post(
                name: TraktSettingsStore.continueWatchingChangedNotification,
                object: nil
            )
            return true
        } catch {
            print("[WeTrakrProgressService] reportPlayback failed: \(error.localizedDescription)")
            return false
        }
    }

    @discardableResult
    static func removePlayback(
        for item: ContinueWatchingItem,
        store: UserDefaults = ProfileSettings.current
    ) async -> Bool {
        guard let token = WeTrakrRuntimeSession.authenticatedState(store: store)?.accessToken,
              !token.isEmpty else {
            return false
        }
        let clientID = WeTrakrConfig.clientID(in: store)
        let meta = item.meta
        let ids = wetrakrIDs(for: meta)

        guard ids.hasUsableIdentifier else {
            return false
        }

        let seasonNum = item.season ?? item.episodeNumbers?.season
        let epNum = item.episode ?? item.episodeNumbers?.episode

        // 1. Cancel playback session in scrobble engine: DELETE /scrobble/playing
        let cancelPayload: WeTrakrCancelPlaybackPayload
        if meta.isSeries {
            let s = seasonNum ?? 1
            let ep = epNum ?? 1
            cancelPayload = WeTrakrCancelPlaybackPayload(
                movie: nil,
                show: WeTrakrMediaPayload(title: meta.name, year: meta.year, ids: ids),
                episode: WeTrakrEpisodePayload(season: s, number: ep)
            )
        } else {
            cancelPayload = WeTrakrCancelPlaybackPayload(
                movie: WeTrakrMediaPayload(title: meta.name, year: meta.year, ids: ids),
                show: nil,
                episode: nil
            )
        }

        do {
            _ = try await client.deleteRaw(
                path: "/scrobble/playing",
                body: cancelPayload,
                accessToken: token,
                clientID: clientID
            )
        } catch {
            print("[WeTrakrProgressService] cancel scrobble session failed: \(error.localizedDescription)")
        }

        // Also cancel session with no body as fallback to guarantee active session is dropped
        _ = try? await client.deleteRaw(
            path: "/scrobble/playing",
            accessToken: token,
            clientID: clientID
        )

        // 2. Remove item from "playing" tracking list: POST /sync/tracking/remove with status: "playing"
        let removePayload: WeTrakrTrackingRemovePayload
        if meta.isSeries {
            if let seasonNum, let epNum {
                let showPayload = WeTrakrShowTrackingPayload(
                    title: meta.name,
                    year: meta.year,
                    ids: ids,
                    status: "playing",
                    seasons: [
                        WeTrakrSeasonTrackingPayload(
                            number: seasonNum,
                            status: "playing",
                            episodes: [
                                WeTrakrEpisodeTrackingPayload(number: epNum, status: "playing")
                            ]
                        )
                    ]
                )
                removePayload = WeTrakrTrackingRemovePayload(
                    movies: nil,
                    shows: [showPayload]
                )
            } else {
                let showPayload = WeTrakrShowTrackingPayload(
                    title: meta.name,
                    year: meta.year,
                    ids: ids,
                    status: "playing"
                )
                removePayload = WeTrakrTrackingRemovePayload(
                    movies: nil,
                    shows: [showPayload]
                )
            }
        } else {
            let moviePayload = WeTrakrMediaPayload(
                title: meta.name,
                year: meta.year,
                ids: ids,
                status: "playing"
            )
            removePayload = WeTrakrTrackingRemovePayload(
                movies: [moviePayload],
                shows: nil
            )
        }

        do {
            let result: WeTrakrHTTPResult<Data> = try await client.postRaw(
                path: "/sync/tracking/remove",
                body: removePayload,
                accessToken: token,
                clientID: clientID
            )
            _ = try result.valueOrThrow()
        } catch {
            print("[WeTrakrProgressService] remove from playing tracking list failed: \(error.localizedDescription)")
        }

        NotificationCenter.default.post(
            name: TraktSettingsStore.continueWatchingChangedNotification,
            object: nil
        )
        return true
    }

    private static var externalIDCache: [String: String] = [:]
    private static let externalIDLock = NSLock()

    static func resolveExternalID(
        wetrakrID: String,
        isSeries: Bool,
        token: String,
        clientID: String
    ) async -> String? {
        let cacheKey = "\(isSeries ? "series" : "movie"):\(wetrakrID)"
        let cached = externalIDLock.withLock { externalIDCache[cacheKey] }
        if let cached {
            return cached
        }

        let endpoint = isSeries ? "/shows/\(wetrakrID)" : "/movies/\(wetrakrID)"
        let result: WeTrakrHTTPResult<WeTrakrMediaDTO> = (try? await client.get(
            path: endpoint,
            accessToken: token,
            clientID: clientID
        )) ?? WeTrakrHTTPResult(statusCode: 500, value: nil, rawData: Data(), errorMessage: nil)

        if let media = try? result.valueOrThrow() {
            let resolved: String? = {
                if let imdb = media.ids?.imdb, !imdb.isEmpty { return imdb }
                if let tmdb = media.ids?.tmdb { return "tmdb:\(tmdb)" }
                if let tvdb = media.ids?.tvdb { return "tvdb:\(tvdb)" }
                return nil
            }()
            if let resolved {
                externalIDLock.withLock {
                    externalIDCache[cacheKey] = resolved
                }
                return resolved
            }
        }
        return nil
    }

    static func fetchContinueWatching(
        repository: CatalogRepository,
        store: UserDefaults = ProfileSettings.current
    ) async -> [ContinueWatchingItem]? {
        guard let token = WeTrakrRuntimeSession.authenticatedState(store: store)?.accessToken,
              !token.isEmpty else {
            return []
        }

        let clientID = WeTrakrConfig.clientID(in: store)
        let extendedQuery = [URLQueryItem(name: "extended", value: "show_level_1,episode_level_1,movie_level_1")]

        async let moviesResult: WeTrakrHTTPResult<[WeTrakrTrackingPlayingItemDTO]> = client.get(
            path: "/sync/tracking/playing/movies",
            accessToken: token,
            clientID: clientID,
            queryItems: extendedQuery
        )
        async let episodesResult: WeTrakrHTTPResult<[WeTrakrTrackingPlayingItemDTO]> = client.get(
            path: "/sync/tracking/playing/episodes",
            accessToken: token,
            clientID: clientID,
            queryItems: extendedQuery
        )
        async let playingNowResult: WeTrakrHTTPResult<WeTrakrTrackingPlayingItemDTO> = client.get(
            path: "/scrobble/playing",
            accessToken: token,
            clientID: clientID
        )

        var rawItems: [WeTrakrTrackingPlayingItemDTO] = []
        var hadSuccessfulRequest = false

        if let movies = try? await moviesResult.valueOrThrow() {
            rawItems.append(contentsOf: movies)
            hadSuccessfulRequest = true
        }
        if let episodes = try? await episodesResult.valueOrThrow() {
            rawItems.append(contentsOf: episodes)
            hadSuccessfulRequest = true
        }
        if let playingNow = try? await playingNowResult.valueOrThrow(),
           let status = playingNow.status, status != "none" {
            rawItems.append(playingNow)
            hadSuccessfulRequest = true
        }

        guard hadSuccessfulRequest else {
            return nil
        }

        struct PlaybackPlan {
            let index: Int
            let placeholder: NuvioMeta
            let isSeries: Bool
            let season: Int?
            let episode: Int?
            let episodeTitle: String?
            let progressPercent: Double
            let runtimeSeconds: Double?
            let lastWatchedAt: Date
            let identity: String
        }

        var plans: [PlaybackPlan] = []
        var seenIdentities = Set<String>()
        var seenTitleKeys = Set<String>()

        for item in rawItems {
            let media = item.resolvedMedia
            guard media.id != nil || media.ids?.hasUsableIdentifier == true else { continue }
            guard let progress = item.resolvedProgressPercent,
                  progress > 0, progress < 90 else { continue }

            let isSeries = item.resolvedIsSeries
            let placeholder = makeNuvioMeta(from: media, isSeries: isSeries)
            let season = item.resolvedSeasonNumber
            let episode = item.resolvedEpisodeNumber
            let identity = "\(isSeries ? "series" : "movie"):\(placeholder.id):\(season ?? -1):\(episode ?? -1)"

            guard seenIdentities.insert(identity).inserted else { continue }

            let titleKey = WatchedStore.normalizedCatalogTitle(placeholder.name)
            if !titleKey.isEmpty {
                let dedupeTitleKey = "\(isSeries ? "series" : "movie"):\(titleKey):\(season ?? -1):\(episode ?? -1)"
                guard seenTitleKeys.insert(dedupeTitleKey).inserted else { continue }
            }

            plans.append(
                PlaybackPlan(
                    index: plans.count,
                    placeholder: placeholder,
                    isSeries: isSeries,
                    season: season,
                    episode: episode,
                    episodeTitle: item.resolvedEpisodeTitle,
                    progressPercent: progress,
                    runtimeSeconds: item.resolvedRuntimeSeconds,
                    lastWatchedAt: item.resolvedLastWatchedAt,
                    identity: identity
                )
            )
        }

        let sortedPlans = plans.sorted { $0.lastWatchedAt > $1.lastWatchedAt }
        let plansToResolve = Array(sortedPlans.prefix(25))

        let resolvedItems = await withTaskGroup(of: (Int, ContinueWatchingItem?).self) { group in
            for (orderIndex, plan) in plansToResolve.enumerated() {
                group.addTask { @MainActor in
                    var targetId = plan.placeholder.id
                    if targetId.hasPrefix("wetrakr:") {
                        let rawNum = String(targetId.dropFirst("wetrakr:".count))
                        if let resolved = await resolveExternalID(
                            wetrakrID: rawNum,
                            isSeries: plan.isSeries,
                            token: token,
                            clientID: clientID
                        ) {
                            targetId = resolved
                        }
                    }

                    let loaded: NuvioMeta?
                    if targetId.hasPrefix("wetrakr:") {
                        loaded = nil
                    } else {
                        loaded = try? await repository.getMetadata(
                            id: targetId,
                            type: plan.isSeries ? "series" : "movie"
                        )
                    }

                    let meta: NuvioMeta = {
                        guard let loaded else { return plan.placeholder }
                        let loadedNameIsFallback = loaded.name.isEmpty
                            || loaded.name == targetId
                            || loaded.name == plan.placeholder.id
                            || loaded.name.allSatisfy { $0.isNumber || $0 == " " }
                        var result = loaded
                        if loadedNameIsFallback,
                           !plan.placeholder.name.isEmpty,
                           !plan.placeholder.name.allSatisfy({ $0.isNumber || $0 == " " }) {
                            result = NuvioMeta(
                                id: result.id,
                                name: plan.placeholder.name,
                                description: result.description ?? plan.placeholder.description,
                                posterUrl: result.posterUrl ?? plan.placeholder.posterUrl,
                                backgroundUrl: result.backgroundUrl ?? plan.placeholder.backgroundUrl,
                                logoUrl: result.logoUrl ?? plan.placeholder.logoUrl,
                                imdbId: result.imdbId ?? plan.placeholder.imdbId,
                                tmdbId: result.tmdbId ?? plan.placeholder.tmdbId,
                                type: result.type,
                                year: result.year ?? plan.placeholder.year,
                                genres: result.genres ?? plan.placeholder.genres,
                                rating: result.rating ?? plan.placeholder.rating,
                                releaseInfo: result.releaseInfo ?? plan.placeholder.releaseInfo,
                                runtime: result.runtime ?? plan.placeholder.runtime,
                                cast: result.cast ?? plan.placeholder.cast,
                                director: result.director ?? plan.placeholder.director,
                                writer: result.writer ?? plan.placeholder.writer,
                                certification: result.certification ?? plan.placeholder.certification,
                                country: result.country ?? plan.placeholder.country,
                                language: result.language ?? plan.placeholder.language,
                                released: result.released ?? plan.placeholder.released,
                                status: result.status ?? plan.placeholder.status,
                                videos: result.videos ?? plan.placeholder.videos,
                                trailerYtIds: result.trailerYtIds ?? plan.placeholder.trailerYtIds,
                                externalRatings: result.externalRatings ?? plan.placeholder.externalRatings,
                                posterShape: result.posterShape ?? plan.placeholder.posterShape
                            )
                        } else if (result.posterUrl == nil || result.posterUrl?.isEmpty == true),
                                  let placeholderPoster = plan.placeholder.posterUrl, !placeholderPoster.isEmpty {
                            result = NuvioMeta(
                                id: result.id,
                                name: result.name,
                                description: result.description,
                                posterUrl: placeholderPoster,
                                backgroundUrl: result.backgroundUrl ?? plan.placeholder.backgroundUrl,
                                logoUrl: result.logoUrl,
                                imdbId: result.imdbId,
                                tmdbId: result.tmdbId,
                                type: result.type,
                                year: result.year,
                                genres: result.genres,
                                rating: result.rating,
                                releaseInfo: result.releaseInfo,
                                runtime: result.runtime,
                                cast: result.cast,
                                director: result.director,
                                writer: result.writer,
                                certification: result.certification,
                                country: result.country,
                                language: result.language,
                                released: result.released,
                                status: result.status,
                                videos: result.videos,
                                trailerYtIds: result.trailerYtIds,
                                externalRatings: result.externalRatings,
                                posterShape: result.posterShape
                            )
                        }
                        return result
                    }()

                    let duration: Double = {
                        if let r = loaded?.runtime, let rNum = Double(r), rNum > 0 {
                            return rNum > 600 ? rNum : rNum * 60.0
                        }
                        if let r = plan.runtimeSeconds, r > 0 {
                            return r
                        }
                        return plan.isSeries ? 2700.0 : 7200.0
                    }()
                    let position = max(1.0, min(duration * (plan.progressPercent / 100.0), max(duration - 5.0, 1.0)))

                    let item = ContinueWatchingItem(
                        meta: meta,
                        streamUrl: "",
                        position: position,
                        duration: duration,
                        lastWatchedAt: plan.lastWatchedAt,
                        season: plan.season,
                        episode: plan.episode,
                        released: nil,
                        episodeTitleOverride: plan.episodeTitle,
                        episodeOverviewOverride: nil,
                        episodeThumbnailOverride: nil,
                        isUpNext: false
                    )
                    return (orderIndex, item)
                }
            }

            var rows: [(Int, ContinueWatchingItem)] = []
            for await (idx, item) in group {
                if let item {
                    rows.append((idx, item))
                }
            }
            return rows.sorted { $0.0 < $1.0 }.map(\.1)
        }

        return resolvedItems
    }

    static func markWatched(
        meta: NuvioMeta,
        season: Int? = nil,
        episode: Int? = nil,
        episodes: [Int]? = nil,
        store: UserDefaults = ProfileSettings.current
    ) async -> Bool {
        guard let token = WeTrakrRuntimeSession.authenticatedState(store: store)?.accessToken,
              !token.isEmpty else { return false }
        let clientID = WeTrakrConfig.clientID(in: store)
        let ids = wetrakrIDs(for: meta)
        guard ids.hasUsableIdentifier else { return false }

        let payload: WeTrakrTrackingAddPayload
        if meta.isSeries {
            let episodeList: [Int]? = {
                if let episodes, !episodes.isEmpty { return episodes }
                if let ep = episode { return [ep] }
                return nil
            }()

            let seasonsPayload: [WeTrakrSeasonTrackingPayload]? = {
                guard let s = season else { return nil }
                if let eps = episodeList {
                    return [
                        WeTrakrSeasonTrackingPayload(
                            number: s,
                            status: "watched",
                            episodes: eps.map { WeTrakrEpisodeTrackingPayload(number: $0, status: "watched") }
                        )
                    ]
                } else {
                    return [
                        WeTrakrSeasonTrackingPayload(
                            number: s,
                            status: "watched",
                            episodes: nil
                        )
                    ]
                }
            }()

            payload = WeTrakrTrackingAddPayload(
                movies: nil,
                shows: [
                    WeTrakrShowTrackingPayload(
                        title: meta.name,
                        year: meta.year,
                        ids: ids,
                        status: "watched",
                        seasons: seasonsPayload
                    )
                ],
                allowRewatch: true
            )
        } else {
            payload = WeTrakrTrackingAddPayload(
                movies: [WeTrakrMediaPayload(title: meta.name, year: meta.year, ids: ids, status: "watched")],
                shows: nil,
                allowRewatch: true
            )
        }

        do {
            let result: WeTrakrHTTPResult<Data> = try await client.postRaw(
                path: "/sync/tracking",
                body: payload,
                accessToken: token,
                clientID: clientID
            )
            _ = try result.valueOrThrow()
            NotificationCenter.default.post(
                name: TraktSettingsStore.continueWatchingChangedNotification,
                object: nil
            )
            return true
        } catch {
            print("[WeTrakrProgressService] markWatched failed: \(error.localizedDescription)")
            return false
        }
    }

    static func markUnwatched(
        meta: NuvioMeta,
        season: Int? = nil,
        episode: Int? = nil,
        episodes: [Int]? = nil,
        store: UserDefaults = ProfileSettings.current
    ) async -> Bool {
        guard let token = WeTrakrRuntimeSession.authenticatedState(store: store)?.accessToken,
              !token.isEmpty else { return false }
        let clientID = WeTrakrConfig.clientID(in: store)
        let ids = wetrakrIDs(for: meta)
        guard ids.hasUsableIdentifier else { return false }

        let payload: WeTrakrTrackingRemovePayload
        if meta.isSeries {
            let episodeList: [Int]? = {
                if let episodes, !episodes.isEmpty { return episodes }
                if let ep = episode { return [ep] }
                return nil
            }()

            let seasonsPayload: [WeTrakrSeasonTrackingPayload]? = {
                guard let s = season else { return nil }
                if let eps = episodeList {
                    return [
                        WeTrakrSeasonTrackingPayload(
                            number: s,
                            status: "watched",
                            episodes: eps.map { WeTrakrEpisodeTrackingPayload(number: $0, status: "watched") }
                        )
                    ]
                } else {
                    return [
                        WeTrakrSeasonTrackingPayload(
                            number: s,
                            status: "watched",
                            episodes: nil
                        )
                    ]
                }
            }()

            payload = WeTrakrTrackingRemovePayload(
                movies: nil,
                shows: [
                    WeTrakrShowTrackingPayload(
                        title: meta.name,
                        year: meta.year,
                        ids: ids,
                        status: "watched",
                        seasons: seasonsPayload
                    )
                ]
            )
        } else {
            payload = WeTrakrTrackingRemovePayload(
                movies: [WeTrakrMediaPayload(title: meta.name, year: meta.year, ids: ids, status: "watched")],
                shows: nil
            )
        }

        do {
            let result: WeTrakrHTTPResult<Data> = try await client.postRaw(
                path: "/sync/tracking/remove/all",
                body: payload,
                accessToken: token,
                clientID: clientID
            )
            _ = try result.valueOrThrow()
            NotificationCenter.default.post(
                name: TraktSettingsStore.continueWatchingChangedNotification,
                object: nil
            )
            return true
        } catch {
            print("[WeTrakrProgressService] markUnwatched failed: \(error.localizedDescription)")
            return false
        }
    }

    static func markSeasonWatched(
        meta: NuvioMeta,
        season: Int,
        store: UserDefaults = ProfileSettings.current
    ) async -> Bool {
        await markWatched(meta: meta, season: season, episode: nil, episodes: nil, store: store)
    }

    static func markSeasonUnwatched(
        meta: NuvioMeta,
        season: Int,
        store: UserDefaults = ProfileSettings.current
    ) async -> Bool {
        await markUnwatched(meta: meta, season: season, episode: nil, episodes: nil, store: store)
    }

    private static var previousWatchedSnapshots: [String: [WatchedStoreItem]] = [:]

    @discardableResult
    static func syncWatchedHistory(
        store: UserDefaults = ProfileSettings.current
    ) async -> Bool {
        guard ProfileSettings.isActiveStore(store),
              TraktSettingsStore.watchProgressSource(in: store) == .wetrakr,
              let token = WeTrakrRuntimeSession.authenticatedState(store: store)?.accessToken,
              !token.isEmpty else {
            return false
        }
        let clientID = WeTrakrConfig.clientID(in: store)
        let syncStartedAt = Date()
        let profileScope = ProfileSettings.activeProfileID ?? "default"

        var remoteItems: [WatchedStoreItem] = []
        var anySuccess = false

        // 1. Fetch watched history for movies (up to 5 pages / 500 items)
        for page in 1...5 {
            let query = [
                URLQueryItem(name: "page", value: "\(page)"),
                URLQueryItem(name: "limit", value: "100"),
                URLQueryItem(name: "extended", value: "movie_level_1")
            ]
            let res: WeTrakrHTTPResult<[WeTrakrTrackingHistoryItemDTO]> = (try? await client.get(
                path: "/sync/tracking/watched/history/movies",
                accessToken: token,
                clientID: clientID,
                queryItems: query
            )) ?? WeTrakrHTTPResult(statusCode: 500, value: nil, rawData: Data(), errorMessage: nil)

            if let plays = try? res.valueOrThrow() {
                anySuccess = true
                for play in plays {
                    guard let media = play.movie ?? play.media else { continue }
                    guard media.id != nil || media.ids?.hasUsableIdentifier == true else { continue }
                    let meta = makeNuvioMeta(from: media, isSeries: false)
                    let watchedAt = dateFromISO8601(play.watchedAt) ?? Date()
                    remoteItems.append(
                        WatchedStoreItem(
                            meta: meta.persistenceSnapshot,
                            watchedAt: watchedAt,
                            sources: [TraktWatchProgressSource.wetrakr.rawValue]
                        )
                    )
                }
                if plays.count < 100 { break }
            } else {
                break
            }
        }

        // 2. Fetch watched movies list for whole-title marks
        if let moviesResult: WeTrakrHTTPResult<[WeTrakrTrackingPlayingItemDTO]> = try? await client.get(
            path: "/sync/tracking/watched/movies",
            accessToken: token,
            clientID: clientID,
            queryItems: [URLQueryItem(name: "extended", value: "movie_level_1"), URLQueryItem(name: "limit", value: "100")]
        ), let movies = try? moviesResult.valueOrThrow() {
            anySuccess = true
            for item in movies {
                let media = item.resolvedMedia
                guard media.id != nil || media.ids?.hasUsableIdentifier == true else { continue }
                let meta = makeNuvioMeta(from: media, isSeries: false)
                let watchedAt = dateFromISO8601(item.watchedAt ?? item.trackedAt ?? item.updatedAt) ?? Date()
                remoteItems.append(
                    WatchedStoreItem(
                        meta: meta.persistenceSnapshot,
                        watchedAt: watchedAt,
                        sources: [TraktWatchProgressSource.wetrakr.rawValue]
                    )
                )
            }
        }

        // 3. Fetch watched history for episodes (up to 10 pages / 1000 items)
        for page in 1...10 {
            let query = [
                URLQueryItem(name: "page", value: "\(page)"),
                URLQueryItem(name: "limit", value: "100"),
                URLQueryItem(name: "extended", value: "show_level_1,episode_level_1")
            ]
            let res: WeTrakrHTTPResult<[WeTrakrTrackingHistoryItemDTO]> = (try? await client.get(
                path: "/sync/tracking/watched/history/episodes",
                accessToken: token,
                clientID: clientID,
                queryItems: query
            )) ?? WeTrakrHTTPResult(statusCode: 500, value: nil, rawData: Data(), errorMessage: nil)

            if let plays = try? res.valueOrThrow() {
                anySuccess = true
                for play in plays {
                    guard let ep = play.episode,
                          let show = ep.show ?? play.media else { continue }
                    guard show.id != nil || show.ids?.hasUsableIdentifier == true else { continue }
                    let meta = makeNuvioMeta(from: show, isSeries: true)
                    let watchedAt = dateFromISO8601(play.watchedAt) ?? Date()
                    let season = ep.seasonNumber ?? ep.season ?? 1
                    let number = ep.number ?? 1
                    remoteItems.append(
                        WatchedStoreItem(
                            meta: meta.persistenceSnapshot,
                            watchedAt: watchedAt,
                            season: season,
                            episode: number,
                            sources: [TraktWatchProgressSource.wetrakr.rawValue]
                        )
                    )
                }
                if plays.count < 100 { break }
            } else {
                break
            }
        }

        guard anySuccess else { return false }

        let previous = previousWatchedSnapshots[profileScope]
            ?? WatchedStore.items().filter { $0.isVisible(under: .wetrakr) }
        let merged = WatchedStore.mergedByIdentity(remoteItems)
        guard WatchedStore.reconcileWeTrakrSnapshot(
            merged,
            previousRemoteItems: previous,
            syncStartedAt: syncStartedAt
        ) else { return false }

        previousWatchedSnapshots[profileScope] = merged
        NotificationCenter.default.post(name: WatchedStore.changedNotification, object: nil)
        return true
    }

    nonisolated static func wetrakrIDs(for meta: NuvioMeta) -> WeTrakrSyncIDs {
        let rawID = meta.id
        let parts = rawID.split(separator: ":").map(String.init)
        let imdb = meta.imdbId ?? (rawID.hasPrefix("tt") ? (parts.first ?? rawID) : nil)
        let tmdb: Int? = {
            if let tmdbId = meta.tmdbId { return tmdbId }
            if rawID.hasPrefix("tmdb:"), parts.count >= 2 {
                return Int(parts[1])
            }
            return nil
        }()
        let tvdb: Int? = {
            if rawID.hasPrefix("tvdb:"), parts.count >= 2 {
                return Int(parts[1])
            }
            return nil
        }()
        let wetrakr: Int? = {
            if rawID.hasPrefix("wetrakr:"), parts.count >= 2 {
                return Int(parts[1])
            }
            return nil
        }()
        return WeTrakrSyncIDs(wetrakr: wetrakr, imdb: imdb, tmdb: tmdb, tvdb: tvdb)
    }

    nonisolated static func makeNuvioMeta(from media: WeTrakrMediaDTO, isSeries: Bool) -> NuvioMeta {
        let metaId: String = {
            if let imdb = media.ids?.imdb, !imdb.isEmpty { return imdb }
            if let tmdb = media.ids?.tmdb { return "tmdb:\(tmdb)" }
            if let tvdb = media.ids?.tvdb { return "tvdb:\(tvdb)" }
            if let id = media.id { return "wetrakr:\(id)" }
            return UUID().uuidString
        }()

        let posterURL: String? = {
            guard let path = media.posterPath, !path.isEmpty else { return nil }
            if path.hasPrefix("http://") || path.hasPrefix("https://") { return path }
            return "https://image.tmdb.org/t/p/w500\(path)"
        }()

        let backdropURL: String? = {
            guard let path = media.backdropPath, !path.isEmpty else { return nil }
            if path.hasPrefix("http://") || path.hasPrefix("https://") { return path }
            return "https://image.tmdb.org/t/p/original\(path)"
        }()

        return NuvioMeta(
            id: metaId,
            name: media.title ?? "",
            description: media.overview,
            posterUrl: posterURL,
            backgroundUrl: backdropURL,
            logoUrl: nil,
            imdbId: media.ids?.imdb,
            tmdbId: media.ids?.tmdb,
            type: isSeries ? "series" : "movie",
            year: media.year,
            genres: nil,
            rating: nil,
            releaseInfo: media.year.map(String.init),
            runtime: media.runtime.map { "\($0)" },
            cast: nil,
            director: nil,
            writer: nil,
            certification: nil,
            country: nil,
            language: nil,
            released: media.releaseDate,
            status: nil,
            videos: nil,
            trailerYtIds: nil,
            externalRatings: nil,
            posterShape: nil
        )
    }

    nonisolated static func dateFromISO8601(_ string: String?) -> Date? {
        guard let string, !string.isEmpty else { return nil }
        let formatter = ISO8601DateFormatter()
        formatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        if let date = formatter.date(from: string) { return date }
        formatter.formatOptions = [.withInternetDateTime]
        return formatter.date(from: string)
    }
}
