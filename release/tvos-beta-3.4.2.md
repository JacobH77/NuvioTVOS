## tvOS Beta 3.4.2

> **Install:** [NuvioTV-3.4.2-unsigned-release.ipa](https://github.com/bobsupra/NuvioTVOS/releases/download/tvos-beta-3.4.2/NuvioTV-3.4.2-unsigned-release.ipa) requires a compatible tvOS development or sideloading signing workflow before installation.

> **New beta alerts:** [Manage notifications](https://github.com/bobsupra/NuvioTVOS/subscription) → choose **Custom → Releases** · [Report a bug or suggest an idea](https://github.com/bobsupra/NuvioTVOS/issues/new/choose)

> 🎉 **Thank you for 200+ GitHub Stars!** A huge thank you to everyone in the community for supporting NuvioTVOS and helping reach 200+ stars on GitHub! Your feedback, issue reports, and testing make this possible.

### WeTrakr Integration & Unified Cloud Tracking

- **WeTrakr Authorization & Device Pairing:** Integrated full WeTrakr authorization flow (`WeTrakrAuthService.swift`), device registration, and real-time sync pairing.
- **Bi-Directional Watch Status & Scrobbling:** Added `WeTrakrTrackingClient.swift` and `WeTrakrLibraryService.swift` to seamlessly synchronize watch history, playback scrobbles, ratings, and custom watchlist entries while preserving multi-source ownership across Trakt, Simkl, and local progress.
- **Snapshot Reconciliation:** Hardened WeTrakr snapshot reconciliation (`WatchedStore.reconcileWeTrakrSnapshot`) to isolate provider updates without overwriting active playback progress from other services.

### Trakt OAuth PKCE & Multi-Account Enhancements

- **PKCE Support for Trakt:** Modernized Trakt device and authorization workflows with PKCE support (`TraktAuthService.swift`), enabling seamless authentication without requiring static client secrets.
- **Profile-Scoped Sync Tokens:** Hardened background token rotation and profile isolation during simultaneous sync cycles.

### Playback Error Diagnostics & Localized Host Formatting

- **Enhanced Stream Diagnostic Insights:** Refined `PlaybackErrorDiagnostic.swift` to format host labels with localized placeholders (`L10n.format`), providing clean, informative error banners during upstream network or debrid interruptions.
- **Localization Catalog Expansion:** Corrected string token interpolations across translations in `AppLanguageCatalog.json`.

### Catalog Storage Concurrency & Focus Safety

- **Deadlock-Free Catalog Payload Store:** Decoupled `UserDefaults` notification broadcasts from internal synchronization locks in `HomeCatalogPayloadStore.swift`, eliminating UI thread lock contention.
- **Disarmed Debug Watchdogs:** Turned off debug tracing watchdog (`TVHomeDebugTrace.enabled = false`) for silky smooth 60fps Home shelf scrolling and zero console logging overhead in release builds.

### Media Identity Resolution & UI Polish

- **Standard Media ID Conflict Guard:** Enhanced canonical identity resolution in `WatchedStore.swift` to prevent cross-show watch state collisions across standard IMDb/TMDb identifiers while retaining graceful fallback for custom provider feeds.
- **Poster Card & Navigation Alignment:** Polished card index tracking, horizontal row focus transitions, and cloud library browsing.
- **Optimized ASS Subtitle Compositing:** Streamlined `ASSRenderCoordinator.swift` and player overlays for frame-accurate typesetting and subtitle timing.

### Tests & Stability

- 640 automated unit and regression tests passing with 0 failures across playback backends, stream caching, subtitle rendering, sync services, and layout settings.
- Enabled persistent derived data caching in test scripts for ultra-fast incremental test execution.

### Known issues

- Picture in Picture requires a supported Apple TV 4K / tvOS 15+ device.
- Physical Apple TV playback, HDMI/HDR/Dolby Vision, AirPlay receivers, Atmos hardware, and live-TV paths still need real-device validation; the Apple TV Simulator cannot play AV1.
