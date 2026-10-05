## tvOS Beta 3.4.1

> **Install:** [NuvioTV-3.4.1-unsigned-release.ipa](https://github.com/bobsupra/NuvioTVOS/releases/download/tvos-beta-3.4.1/NuvioTV-3.4.1-unsigned-release.ipa) requires a compatible tvOS development or sideloading signing workflow before installation.

> **New beta alerts:** [Manage notifications](https://github.com/bobsupra/NuvioTVOS/subscription) → choose **Custom → Releases** · [Report a bug or suggest an idea](https://github.com/bobsupra/NuvioTVOS/issues/new/choose)

> 🎉 **Thank you for 200+ GitHub Stars!** A huge thank you to everyone in the community for supporting NuvioTVOS and helping reach 200+ stars on GitHub! Your feedback, issue reports, and testing make this possible.

### Fullscreen Trailer Playback & Details Screen Enhancements

- **Dedicated Fullscreen Trailer Mode:** Added seamless fullscreen trailer playback directly from the Details screen (`DetailsScreen.swift`, `DetailsViewModel.swift`) with native audio and subtitle track selectors.
- **Batch Episode Watch Action:** Added `markWatchedUpTo` to mark all previous episodes in a season or series as watched in a single action (`WatchedStore.swift`).
- **Details Action Placement Customization:** Configurable action bar layout options (`SettingsKey.detailsActionPlacement`) with refined trailer focus and cast navigation.

### Landscape Layouts & Home Screen Customization

- **Landscape Poster & Continue Watching Rows:** Added landscape card layout options for Home catalogs and the Continue Watching row, providing a sleek modern alternative to standard portrait posters.
- **Scroll & Focus Alignment Refinements:** Polished scroll alignment in `TVCatalogRow.swift`, collection folder browse views, and card index tracking for buttery smooth 60fps navigation.
- **Addon Manifest Home Visibility:** Implemented `showInHome` manifest flag support and collection source eligibility filtering for third-party catalog feeds.

### Stream Discovery & Live/Sports Optimization

- **Stream Unavailability Notices:** Smart detection for provider unavailability notices, preserving user manual stream selections without premature failover.
- **Live & Sports Debrid Filtering:** Automatically exempts live events and sports streams from cached-only Debrid filtering so live broadcast links remain accessible.

### Player Stability, Subtitles & AetherEngine Refinements

- **Smart Subtitle Matching & Fast Track Updates:** Optimized subtitle matching heuristics and instant loaded track updates in `PlayerControls.swift`.
- **AetherEngine Surface Stability:** Enhanced subtitle decoding pipeline, surface rebind lifecycle, and idle screen overlay presentation.

### Cloud Sync & Profile Isolation

- **Catalog Snapshot Metadata:** Streamlined catalog snapshot metadata persistence, preventing sync collisions and maintaining strict profile isolation.

### Tests & Stability

- 455+ automated unit and regression test suite passing with 0 failures across playback backend policy, stream caching, remote input, trailer handoff, and layout configuration.

### Known issues

- Picture in Picture requires a supported Apple TV 4K / tvOS 15+ device.
- Physical Apple TV playback, HDMI/HDR/Dolby Vision, AirPlay receivers, Atmos hardware, and live-TV paths still need real-device validation; the Apple TV Simulator cannot play AV1.
