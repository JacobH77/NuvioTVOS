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

    private func section(_ id: String, title: String, itemId: String) -> TVHomeSection {
        TVHomeSection(
            id: id,
            title: title,
            items: [NuvioMeta(id: itemId, name: title, type: "movie")]
        )
    }
}
