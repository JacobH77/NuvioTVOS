import Foundation

/// Keeps Home's featured carousel, focused-title information, and focused
/// artwork rules consistent across Modern and Grid layouts. The featured
/// carousel and focused-title presentation are independent: browsing a row
/// must not remove the carousel from the scroll content.
enum TVHomeHeroPresentation {
    struct FeaturedItemIdentity: Hashable {
        let type: String
        let id: String

        init(type: String, id: String) {
            self.type = type.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
            self.id = id
        }

        init(_ meta: NuvioMeta) {
            self.init(type: meta.type, id: meta.id)
        }
    }

    struct FeaturedSelection: Equatable {
        let index: Int
        let identity: FeaturedItemIdentity?
    }

    struct ArtworkRequestIdentity: Equatable {
        let item: FeaturedItemIdentity
        let imdbID: String?
        let backgroundURL: String?
        let posterURL: String?
    }

    static func featuredSelection(
        identities: [FeaturedItemIdentity],
        selectedIdentity: FeaturedItemIdentity?,
        fallbackIndex: Int
    ) -> FeaturedSelection {
        guard !identities.isEmpty else {
            return FeaturedSelection(index: 0, identity: nil)
        }
        let index = selectedIdentity.flatMap { identities.firstIndex(of: $0) }
            ?? min(max(fallbackIndex, 0), identities.count - 1)
        return FeaturedSelection(index: index, identity: identities[index])
    }

    static func artworkRequestIdentity(for meta: NuvioMeta) -> ArtworkRequestIdentity {
        ArtworkRequestIdentity(
            item: FeaturedItemIdentity(meta),
            imdbID: meta.imdbId,
            backgroundURL: meta.backgroundUrl,
            posterURL: meta.posterUrl
        )
    }

    static func focusedValue<Value>(pending: Value?, settled: Value?, fallback: Value?) -> Value? {
        pending ?? settled ?? fallback
    }

    static func showsFeaturedHero(
        heroEnabled: Bool,
        hasFeaturedTitles: Bool
    ) -> Bool {
        heroEnabled && hasFeaturedTitles
    }

    static func shouldReturnFocusToFeaturedHero(
        directionIsUp: Bool,
        focusedRowIndex: Int,
        heroEnabled: Bool,
        hasFeaturedTitles: Bool
    ) -> Bool {
        directionIsUp && focusedRowIndex == 0 && heroEnabled && hasFeaturedTitles
    }

    static func showsFocusedTitleInformation(
        heroEnabled: Bool,
        showsFocusedTitle: Bool
    ) -> Bool {
        heroEnabled && showsFocusedTitle
    }

    static func showsFeaturedArtwork(
        isLoading: Bool,
        heroEnabled: Bool,
        hasFeaturedTitles: Bool,
        isFeaturedHeroFocused: Bool,
        showsFocusedTitle: Bool
    ) -> Bool {
        guard !isLoading, heroEnabled, hasFeaturedTitles else { return false }
        return isFeaturedHeroFocused || !showsFocusedTitle
    }

    static func showsFocusedArtwork(
        isLoading: Bool,
        isGridLayout: Bool,
        heroEnabled: Bool,
        hasFeaturedTitles: Bool,
        isFeaturedHeroFocused: Bool,
        showsFocusedTitle: Bool
    ) -> Bool {
        guard !isLoading else { return false }
        if isGridLayout && !showsFocusedTitle { return false }
        return !showsFeaturedArtwork(
            isLoading: isLoading,
            heroEnabled: heroEnabled,
            hasFeaturedTitles: hasFeaturedTitles,
            isFeaturedHeroFocused: isFeaturedHeroFocused,
            showsFocusedTitle: showsFocusedTitle
        )
    }
}
