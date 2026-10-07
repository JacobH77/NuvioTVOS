import Foundation

@MainActor
enum WeTrakrLibraryService {
    static let mutationNotification = Notification.Name("nuvio.tv.wetrakr.library.mutation")
    private static let client = WeTrakrAPIClient()

    static func fetchLibrary(
        repository: CatalogRepository,
        store: UserDefaults = ProfileSettings.current
    ) async -> [LibraryStoreItem]? {
        guard let token = WeTrakrRuntimeSession.authenticatedState(store: store)?.accessToken,
              !token.isEmpty else { return nil }
        let clientID = WeTrakrConfig.clientID(in: store)

        let extendedQuery = [URLQueryItem(name: "extended", value: "show_level_1,movie_level_1")]

        async let moviesResult: WeTrakrHTTPResult<[WeTrakrTrackingPlayingItemDTO]> = client.get(
            path: "/sync/tracking/movies",
            accessToken: token,
            clientID: clientID,
            queryItems: extendedQuery
        )
        async let showsResult: WeTrakrHTTPResult<[WeTrakrTrackingPlayingItemDTO]> = client.get(
            path: "/sync/tracking/shows",
            accessToken: token,
            clientID: clientID,
            queryItems: extendedQuery
        )

        var items: [LibraryStoreItem] = []

        if let movies = try? await moviesResult.valueOrThrow() {
            for item in movies {
                let media = item.resolvedMedia
                guard media.id != nil || media.ids?.hasUsableIdentifier == true else { continue }
                let meta = WeTrakrProgressService.makeNuvioMeta(from: media, isSeries: false)
                let added = WeTrakrProgressService.dateFromISO8601(item.updatedAt ?? item.trackedAt) ?? Date()
                items.append(LibraryStoreItem(meta: meta, addedAt: added))
            }
        }

        if let shows = try? await showsResult.valueOrThrow() {
            for item in shows {
                let media = item.resolvedMedia
                guard media.id != nil || media.ids?.hasUsableIdentifier == true else { continue }
                let meta = WeTrakrProgressService.makeNuvioMeta(from: media, isSeries: true)
                let added = WeTrakrProgressService.dateFromISO8601(item.updatedAt ?? item.trackedAt) ?? Date()
                items.append(LibraryStoreItem(meta: meta, addedAt: added))
            }
        }

        return items
    }

    static func setWatchlist(
        _ meta: NuvioMeta,
        isInWatchlist: Bool,
        store: UserDefaults = ProfileSettings.current
    ) async -> Bool {
        guard let token = WeTrakrRuntimeSession.authenticatedState(store: store)?.accessToken,
              !token.isEmpty else { return false }
        let clientID = WeTrakrConfig.clientID(in: store)
        let ids = WeTrakrProgressService.wetrakrIDs(for: meta)
        guard ids.hasUsableIdentifier else { return false }

        let mediaPayload = WeTrakrMediaPayload(title: meta.name, year: meta.year, ids: ids)

        do {
            if isInWatchlist {
                let payload = WeTrakrTrackingAddPayload(
                    status: "plan_to_watch",
                    movies: meta.isSeries ? nil : [mediaPayload],
                    shows: meta.isSeries ? [WeTrakrShowTrackingPayload(title: meta.name, year: meta.year, ids: ids, seasons: nil)] : nil
                )
                let result: WeTrakrHTTPResult<Data> = try await client.postRaw(
                    path: "/sync/tracking",
                    body: payload,
                    accessToken: token,
                    clientID: clientID
                )
                _ = try result.valueOrThrow()
            } else {
                let payload = WeTrakrTrackingRemovePayload(
                    movies: meta.isSeries ? nil : [mediaPayload],
                    shows: meta.isSeries ? [WeTrakrShowTrackingPayload(title: meta.name, year: meta.year, ids: ids, seasons: nil)] : nil
                )
                let result: WeTrakrHTTPResult<Data> = try await client.postRaw(
                    path: "/sync/tracking/remove",
                    body: payload,
                    accessToken: token,
                    clientID: clientID
                )
                _ = try result.valueOrThrow()
            }

            NotificationCenter.default.post(name: mutationNotification, object: nil)
            return true
        } catch {
            return false
        }
    }

    static func isInWatchlist(
        _ meta: NuvioMeta,
        store: UserDefaults = ProfileSettings.current
    ) async -> Bool? {
        guard let token = WeTrakrRuntimeSession.authenticatedState(store: store)?.accessToken,
              !token.isEmpty else { return nil }
        return nil
    }
}
