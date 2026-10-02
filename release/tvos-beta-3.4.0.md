## tvOS Beta 3.4.0

> **Install:** [NuvioTV-3.4.0-unsigned-release.ipa](https://github.com/bobsupra/NuvioTVOS/releases/download/tvos-beta-3.4.0/NuvioTV-3.4.0-unsigned-release.ipa) requires a compatible tvOS development or sideloading signing workflow before installation.

> **New beta alerts:** [Manage notifications](https://github.com/bobsupra/NuvioTVOS/subscription) → choose **Custom → Releases** · [Report a bug or suggest an idea](https://github.com/bobsupra/NuvioTVOS/issues/new/choose)

> 🎉 **Thank you for 200+ GitHub Stars!** A huge thank you to everyone in the community for supporting NuvioTVOS and helping reach 200+ stars on GitHub! Your feedback, issue reports, and testing make this possible.

### High-Throughput Stream Caching & MPV/Aether Reliability

- **Universal Engine Disk Caching:** Overhauled `PlaybackStreamDiskCache.swift` and `PlaybackStreamCacheServer.swift` with resilient multi-tier disk caching, dedicated session path resolution, and eviction budget isolation for rock-solid stability across both AetherEngine and MPVKit.
- **Local Stream Scrub Thumbnails:** Enabled live video frame scrub thumbnail extraction directly from local cached streams (`AetherEngine+ScrubThumbnail.swift`) for instantaneous visual scrubbing.
- **Adaptive Fetch Policies:** Bypassed rate-limit cooldown for on-demand player chunk requests, added smart retry strategies for dropped network chunks, and improved memory lead depth.

### Modernized Simkl OAuth 2.0 (v2 Client ID) & Sync Services

- **OAuth 2.0 Device Flow Modernization:** Upgraded Simkl authentication to the new v2 client credentials and modern OAuth 2.0 Device Flow (`SimklAuthService.swift`), allowing users to easily connect/reconnect their accounts.
- **Automated Token Refresh:** Hardened background token rotation and automatic refresh to maintain uninterrupted sync sessions.
- **Bi-Directional Watch Status & Scrobbling:** Streamlined episode watch status, anime scrobbling, and continue-watching sync deduplication across multi-profile setups (`SimklSyncService.swift`).

### Continue Watching Row Customization & Synchronization Fixes

- **Home Row Visibility Toggle:** Added a dedicated toggle in Layout Settings (`SettingsKey.continueWatchingVisible`) allowing users to show or hide the Continue Watching row on the Home screen, backed by automated test coverage (`HomeLayoutSettingsTests.swift`).
- **Row Truncation & Re-Watching Fixes:** Resolved issues where continue watching items could be prematurely truncated or fail to update when re-watching previously completed series episodes (closes #133, #134).
- **Default Profile Bootstrap:** Improved sync bootstrapping to gracefully initialize local profiles when remote account profiles are empty.

### Player Engine Selection & Live/Sports Stream Optimization

- **Intelligent Engine Routing:** Optimized playback backend selection (`PlaybackBackendPolicy.swift`) for HLS manifests, live sports streams, and custom HTTP request headers.
- **Remote Touch & Interaction Polish:** Refined Siri Remote clickpad touch interaction, timeline scrub preview positioning, and scene panel focus flow.
- **Aether HDR10+ & Subtitle Compositing:** Enhanced HDR10+ dynamic metadata scanning, live recording ingest, and stylized subtitle compositing.

### Details Screen, Cast Rows & Addon Management

- **Dynamic Cast Visibility:** Refined actor and crew row display logic to cleanly show active cast members and seamlessly pass live/sports context to the playback coordinator.
- **Trailer Handoff & Addon Priority:** Added seamless trailer playback handoff and customizable addon priority ordering in settings.

### MDBList & Jellyfin Enhancements

- **MDBList Progress Tracking:** Enhanced watch progress tracking and scrobble synchronization with remote MDBList accounts.
- **Jellyfin Server-Level API Keys:** Added support for server-level API keys and fallback username matching.
- **Concurrent Subtitle Addon Resolution:** Accelerated subtitle discovery across third-party addon manifests with concurrent resolution and clean label sanitization.

### Tests & Stability

- 455+ automated unit and regression tests passing with 0 failures across playback backend policy, stream caching, remote input, Simkl OAuth, and layout configuration.

### Known issues

- Picture in Picture requires a supported Apple TV 4K / tvOS 15+ device.
- Physical Apple TV playback, HDMI/HDR/Dolby Vision, AirPlay receivers, Atmos hardware, and live-TV paths still need real-device validation; the Apple TV Simulator cannot play AV1.
