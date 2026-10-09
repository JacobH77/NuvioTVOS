import XCTest
@testable import NuvioTV

final class HomeHeroSelectionTests: XCTestCase {
    func testHeroSourceSelectionUsesConfiguredCatalogsAndExcludesContinueRows() throws {
        let sections = [
            section(TVHomeSection.continueWatchingId, title: "Continue", itemId: "resume"),
            section(TVHomeSection.upcomingId, title: "Upcoming", itemId: "upcoming"),
            section("catalog-movies", title: "Movies", itemId: "movie"),
            section("addon-series", title: "Series", itemId: "series")
        ]
        let selection = try JSONEncoder().encode(["addon-series"])

        XCTAssertEqual(
            TVHomeHeroSelection.featuredTitle(in: sections, selectionData: selection)?.id,
            "series"
        )
        XCTAssertEqual(
            TVHomeHeroSelection.catalogSections(in: sections, selectionData: selection).map(\.id),
            ["addon-series"]
        )
    }

    func testMissingOrEmptyHeroSelectionFallsBackToAvailableCatalogOrder() throws {
        let sections = [
            section(TVHomeSection.continueWatchingId, title: "Continue", itemId: "resume"),
            section(TVHomeSection.upcomingId, title: "Upcoming", itemId: "upcoming"),
            section("catalog-movies", title: "Movies", itemId: "movie"),
            section("addon-series", title: "Series", itemId: "series")
        ]
        let removedSource = try JSONEncoder().encode(["removed-source"])

        XCTAssertEqual(
            TVHomeHeroSelection.featuredTitle(in: sections, selectionData: Data())?.id,
            "movie"
        )
        XCTAssertEqual(
            TVHomeHeroSelection.featuredTitle(in: sections, selectionData: removedSource)?.id,
            "movie"
        )
        XCTAssertEqual(
            TVHomeHeroSelection.catalogSections(in: sections, selectionData: removedSource).map(\.id),
            ["catalog-movies", "addon-series"]
        )
    }

    func testFeaturedTitlePrefersBackdropArtworkWithinConfiguredCatalog() throws {
        let posterOnly = NuvioMeta(
            id: "poster-only",
            name: "Poster only",
            posterUrl: "https://example.com/poster.jpg",
            type: "movie"
        )
        let backdrop = NuvioMeta(
            id: "with-backdrop",
            name: "Backdrop title",
            backgroundUrl: "https://example.com/backdrop.jpg",
            type: "movie"
        )
        let section = TVHomeSection(
            id: "catalog",
            title: "Catalog",
            items: [posterOnly, backdrop]
        )

        XCTAssertEqual(
            TVHomeHeroSelection.featuredTitle(in: [section], selectionData: Data())?.id,
            "with-backdrop"
        )
        XCTAssertEqual(
            TVHomeHeroSelection.featuredItems(in: section).map(\.id),
            ["with-backdrop"]
        )
    }

    private func section(_ id: String, title: String, itemId: String) -> TVHomeSection {
        TVHomeSection(
            id: id,
            title: title,
            items: [NuvioMeta(id: itemId, name: title, type: "movie")]
        )
    }
}
