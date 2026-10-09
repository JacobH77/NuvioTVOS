import XCTest
@testable import NuvioTV

final class HomeHeroFocusTests: XCTestCase {
    func testUpFromFirstRowReturnsToEnabledFeaturedHero() {
        XCTAssertTrue(TVHomeHeroPresentation.shouldReturnFocusToFeaturedHero(
            directionIsUp: true,
            focusedRowIndex: 0,
            heroEnabled: true,
            hasFeaturedTitles: true
        ))
    }

    func testHeroReturnRequiresUpFromFirstRowAndAvailableHero() {
        XCTAssertFalse(TVHomeHeroPresentation.shouldReturnFocusToFeaturedHero(
            directionIsUp: false,
            focusedRowIndex: 0,
            heroEnabled: true,
            hasFeaturedTitles: true
        ))
        XCTAssertFalse(TVHomeHeroPresentation.shouldReturnFocusToFeaturedHero(
            directionIsUp: true,
            focusedRowIndex: 1,
            heroEnabled: true,
            hasFeaturedTitles: true
        ))
        XCTAssertFalse(TVHomeHeroPresentation.shouldReturnFocusToFeaturedHero(
            directionIsUp: true,
            focusedRowIndex: 0,
            heroEnabled: false,
            hasFeaturedTitles: true
        ))
        XCTAssertFalse(TVHomeHeroPresentation.shouldReturnFocusToFeaturedHero(
            directionIsUp: true,
            focusedRowIndex: 0,
            heroEnabled: true,
            hasFeaturedTitles: false
        ))
    }
}
