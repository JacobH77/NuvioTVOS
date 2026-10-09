## tvOS Beta 3.4.2

> **Install:** [NuvioTV-3.4.2-unsigned-release.ipa](https://github.com/JacobH77/NuvioTVOS/releases/download/tvos-beta-3.4.2/NuvioTV-3.4.2-unsigned-release.ipa) requires a compatible tvOS development or sideloading signing workflow before installation.

> **New beta alerts:** [Manage notifications](https://github.com/JacobH77/NuvioTVOS/subscription) → choose **Custom → Releases** · [Report a bug or suggest an idea](https://github.com/JacobH77/NuvioTVOS/issues/new/choose)

### Home Hero & Focus Reliability

- Kept the featured selection attached to the same media when catalog order or content changes, and prevented stale artwork metadata from replacing the selected title.
- Removed the duplicate, clipped title banner when the focused Home card is also the selected featured title; distinct focused titles still show their own information.
- Improved profile-scoped Continue Watching refresh and Home section updates so stale progress or library rows do not persist across profile/source changes.
- Tightened watched-item identity matching to avoid collisions between different IMDb/TMDb titles while preserving provider-local series matching.

### Tests & Stability

- 97 Home and media-identity regression tests passed.
- The full suite reported 641 passed and 4 failed; failures were in three `PlaybackErrorDiagnosticTests` assertions and one `PlayerControlsSettingsTests` seek assertion (expected 10 seconds, observed 15 seconds).

### Known issues

- Physical Apple TV playback, HDMI/HDR/Dolby Vision, AirPlay receivers, Atmos hardware, and live-TV paths still need real-device validation; the Apple TV Simulator cannot play AV1.
