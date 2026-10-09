import XCTest
@testable import NuvioTV

final class HomeHeroPresentationTests: XCTestCase {
    func testPendingFocusImmediatelyReplacesSettledTitle() {
        XCTAssertEqual(
            TVHomeHeroPresentation.focusedValue(
                pending: "newly focused",
                settled: "previous card",
                fallback: "featured title"
            ),
            "newly focused"
        )
        XCTAssertEqual(
            TVHomeHeroPresentation.focusedValue(
                pending: Optional<String>.none,
                settled: "settled card",
                fallback: "featured title"
            ),
            "settled card"
        )
        XCTAssertEqual(
            TVHomeHeroPresentation.focusedValue(
                pending: Optional<String>.none,
                settled: Optional<String>.none,
                fallback: "featured title"
            ),
            "featured title"
        )
    }

    func testFocusedTitleInformationDoesNotSuppressFeaturedHero() {
        XCTAssertTrue(
            TVHomeHeroPresentation.showsFeaturedHero(
                heroEnabled: true,
                hasFeaturedTitles: true
            )
        )
        XCTAssertTrue(
            TVHomeHeroPresentation.showsFocusedTitleInformation(
                heroEnabled: true,
                showsFocusedTitle: true
            )
        )
    }

    func testFeaturedHeroReturnsWhenFocusMovesBackToIt() {
        XCTAssertTrue(
            TVHomeHeroPresentation.showsFeaturedHero(
                heroEnabled: true,
                hasFeaturedTitles: true
            )
        )
        XCTAssertFalse(
            TVHomeHeroPresentation.showsFocusedTitleInformation(
                heroEnabled: true,
                showsFocusedTitle: false
            )
        )
        XCTAssertFalse(
            TVHomeHeroPresentation.showsFocusedArtwork(
                isLoading: false,
                isGridLayout: true,
                heroEnabled: true,
                hasFeaturedTitles: true,
                isFeaturedHeroFocused: true,
                showsFocusedTitle: false
            )
        )
    }

    func testGridBackdropStaysHiddenUntilAContentTitleIsFocused() {
        XCTAssertFalse(
            TVHomeHeroPresentation.showsFocusedArtwork(
                isLoading: false,
                isGridLayout: true,
                heroEnabled: true,
                hasFeaturedTitles: true,
                isFeaturedHeroFocused: false,
                showsFocusedTitle: false
            )
        )
        XCTAssertFalse(
            TVHomeHeroPresentation.showsFocusedArtwork(
                isLoading: true,
                isGridLayout: false,
                heroEnabled: true,
                hasFeaturedTitles: true,
                isFeaturedHeroFocused: false,
                showsFocusedTitle: true
            )
        )
    }

    func testFocusedBackdropRemainsAvailableForAnyFocusedCatalogRow() {
        for isGridLayout in [false, true] {
            XCTAssertTrue(
                TVHomeHeroPresentation.showsFocusedArtwork(
                    isLoading: false,
                    isGridLayout: isGridLayout,
                    heroEnabled: true,
                    hasFeaturedTitles: true,
                    isFeaturedHeroFocused: false,
                    showsFocusedTitle: true
                )
            )
        }
    }
}
