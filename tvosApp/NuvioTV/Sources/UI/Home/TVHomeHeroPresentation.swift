import Foundation

/// Keeps Home's featured carousel, focused-title information, and focused
/// artwork rules consistent across Modern and Grid layouts. The featured
/// carousel and focused-title presentation are independent: browsing a row
/// must not remove the carousel from the scroll content.
enum TVHomeHeroPresentation {
    static func focusedValue<Value>(pending: Value?, settled: Value?, fallback: Value?) -> Value? {
        pending ?? settled ?? fallback
    }

    static func showsFeaturedHero(
        heroEnabled: Bool,
        hasFeaturedTitles: Bool
    ) -> Bool {
        heroEnabled && hasFeaturedTitles
    }

    static func showsFocusedTitleInformation(
        heroEnabled: Bool,
        showsFocusedTitle: Bool
    ) -> Bool {
        heroEnabled && showsFocusedTitle
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
        if heroEnabled && hasFeaturedTitles && (isFeaturedHeroFocused || !showsFocusedTitle) {
            return false
        }
        return true
    }
}
