import XCTest
@testable import NuvioTV

final class HomeHeroPresentationTests: XCTestCase {
    private func makeMeta(
        _ id: String,
        type: String = "movie",
        backgroundURL: String? = nil
    ) throws -> NuvioMeta {
        var payload: [String: Any] = ["id": id, "type": type, "name": id]
        if let backgroundURL {
            payload["backgroundUrl"] = backgroundURL
        }
        return try JSONDecoder().decode(
            NuvioMeta.self,
            from: JSONSerialization.data(withJSONObject: payload)
        )
    }

    func testFeaturedSelectionFollowsTheSelectedItemAcrossReordering() {
        let first = TVHomeHeroPresentation.FeaturedItemIdentity(type: "movie", id: "first")
        let selected = TVHomeHeroPresentation.FeaturedItemIdentity(type: "series", id: "selected")
        let initial = TVHomeHeroPresentation.featuredSelection(
            identities: [first, selected],
            selectedIdentity: selected,
            fallbackIndex: 0
        )
        let reordered = TVHomeHeroPresentation.featuredSelection(
            identities: [selected, first],
            selectedIdentity: selected,
            fallbackIndex: initial.index
        )

        XCTAssertEqual(initial, .init(index: 1, identity: selected))
        XCTAssertEqual(reordered, .init(index: 0, identity: selected))
    }

    func testFeaturedSelectionFallsBackWhenSelectedItemDisappears() {
        let remaining = TVHomeHeroPresentation.FeaturedItemIdentity(type: "movie", id: "remaining")
        let fallback = TVHomeHeroPresentation.featuredSelection(
            identities: [remaining],
            selectedIdentity: TVHomeHeroPresentation.FeaturedItemIdentity(type: "series", id: "removed"),
            fallbackIndex: 20
        )
        let empty = TVHomeHeroPresentation.featuredSelection(
            identities: [],
            selectedIdentity: remaining,
            fallbackIndex: 20
        )

        XCTAssertEqual(fallback, .init(index: 0, identity: remaining))
        XCTAssertEqual(empty, .init(index: 0, identity: nil))
    }

    func testHeroArtworkRequestIdentityChangesWhenTheArtworkURLChanges() throws {
        let original = try makeMeta("same-title", backgroundURL: "https://example.test/old.jpg")
        let refreshed = try makeMeta("same-title", backgroundURL: "https://example.test/new.jpg")

        XCTAssertNotEqual(
            TVHomeHeroPresentation.artworkRequestIdentity(for: original),
            TVHomeHeroPresentation.artworkRequestIdentity(for: refreshed)
        )
    }

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

    func testFocusedTitleInformationShowsForAnyFocusedHomeCardIncludingFeaturedTitle() {
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
        XCTAssertFalse(
            TVHomeHeroPresentation.showsFocusedTitleInformation(
                heroEnabled: false,
                showsFocusedTitle: true
            )
        )
        XCTAssertFalse(
            TVHomeHeroPresentation.showsFocusedTitleInformation(
                heroEnabled: true,
                showsFocusedTitle: false
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

    func testUpFromFirstEligibleRowReturnsFocusToFeaturedHero() {
        XCTAssertTrue(
            TVHomeHeroPresentation.shouldReturnFocusToFeaturedHero(
                directionIsUp: true,
                focusedRowIndex: 0,
                heroEnabled: true,
                hasFeaturedTitles: true
            )
        )
    }

    func testFeaturedHeroFocusReturnRequiresUpAndAnAvailableHero() {
        let unavailableCases: [(Bool, Int, Bool, Bool)] = [
            (false, 0, true, true),
            (true, 1, true, true),
            (true, 0, false, true),
            (true, 0, true, false)
        ]

        for (directionIsUp, focusedRowIndex, heroEnabled, hasFeaturedTitles) in unavailableCases {
            XCTAssertFalse(
                TVHomeHeroPresentation.shouldReturnFocusToFeaturedHero(
                    directionIsUp: directionIsUp,
                    focusedRowIndex: focusedRowIndex,
                    heroEnabled: heroEnabled,
                    hasFeaturedTitles: hasFeaturedTitles
                )
            )
        }
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
