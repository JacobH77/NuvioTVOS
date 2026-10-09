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

    func testBackdropArtworkMovesBetweenFeaturedAndFocusedItem() {
        for isGridLayout in [false, true] {
            let featuredState = (
                loading: false,
                heroFocused: false,
                titleFocused: false
            )
            XCTAssertTrue(
                TVHomeHeroPresentation.showsFeaturedArtwork(
                    isLoading: featuredState.loading,
                    heroEnabled: true,
                    hasFeaturedTitles: true,
                    isFeaturedHeroFocused: featuredState.heroFocused,
                    showsFocusedTitle: featuredState.titleFocused
                )
            )
            XCTAssertFalse(
                TVHomeHeroPresentation.showsFocusedArtwork(
                    isLoading: featuredState.loading,
                    isGridLayout: isGridLayout,
                    heroEnabled: true,
                    hasFeaturedTitles: true,
                    isFeaturedHeroFocused: featuredState.heroFocused,
                    showsFocusedTitle: featuredState.titleFocused
                )
            )

            let cardFocusedState = (
                loading: false,
                heroFocused: false,
                titleFocused: true
            )
            XCTAssertFalse(
                TVHomeHeroPresentation.showsFeaturedArtwork(
                    isLoading: cardFocusedState.loading,
                    heroEnabled: true,
                    hasFeaturedTitles: true,
                    isFeaturedHeroFocused: cardFocusedState.heroFocused,
                    showsFocusedTitle: cardFocusedState.titleFocused
                )
            )
            XCTAssertTrue(
                TVHomeHeroPresentation.showsFocusedArtwork(
                    isLoading: cardFocusedState.loading,
                    isGridLayout: isGridLayout,
                    heroEnabled: true,
                    hasFeaturedTitles: true,
                    isFeaturedHeroFocused: cardFocusedState.heroFocused,
                    showsFocusedTitle: cardFocusedState.titleFocused
                )
            )

            let heroFocusedState = (
                loading: false,
                heroFocused: true,
                titleFocused: false
            )
            XCTAssertTrue(
                TVHomeHeroPresentation.showsFeaturedArtwork(
                    isLoading: heroFocusedState.loading,
                    heroEnabled: true,
                    hasFeaturedTitles: true,
                    isFeaturedHeroFocused: heroFocusedState.heroFocused,
                    showsFocusedTitle: heroFocusedState.titleFocused
                )
            )
            XCTAssertFalse(
                TVHomeHeroPresentation.showsFocusedArtwork(
                    isLoading: heroFocusedState.loading,
                    isGridLayout: isGridLayout,
                    heroEnabled: true,
                    hasFeaturedTitles: true,
                    isFeaturedHeroFocused: heroFocusedState.heroFocused,
                    showsFocusedTitle: heroFocusedState.titleFocused
                )
            )
        }
    }

    func testLoadingNeverShowsEitherBackdropArtworkLayer() {
        XCTAssertFalse(
            TVHomeHeroPresentation.showsFeaturedArtwork(
                isLoading: true,
                heroEnabled: true,
                hasFeaturedTitles: true,
                isFeaturedHeroFocused: false,
                showsFocusedTitle: true
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
}
