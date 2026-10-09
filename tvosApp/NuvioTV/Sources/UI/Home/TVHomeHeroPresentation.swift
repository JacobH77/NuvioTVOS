import Foundation

enum TVHomeHeroPresentation {
    static func shouldReturnFocusToFeaturedHero(
        directionIsUp: Bool,
        focusedRowIndex: Int,
        heroEnabled: Bool,
        hasFeaturedTitles: Bool
    ) -> Bool {
        directionIsUp && focusedRowIndex == 0 && heroEnabled && hasFeaturedTitles
    }
}
