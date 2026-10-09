import XCTest
@testable import NuvioTV

final class ContinueWatchingAndPlayerSyncTests: XCTestCase {
    private let dismissalTestProfileId = "continue-watching-sync-\(UUID().uuidString)"
    private var previousDismissalProfileId: String?

    override func setUp() {
        super.setUp()
        previousDismissalProfileId = ContinueWatchingDismissStore.activeProfileId
        ContinueWatchingDismissStore.setActiveProfile(dismissalTestProfileId)
        ContinueWatchingDismissStore.eraseProfile(dismissalTestProfileId)
    }

    override func tearDown() {
        ContinueWatchingDismissStore.eraseProfile(dismissalTestProfileId)
        ContinueWatchingDismissStore.setActiveProfile(previousDismissalProfileId)
        super.tearDown()
    }

    private func makeDismissalTestItem(contentId: String) -> ContinueWatchingItem {
        ContinueWatchingItem(
            meta: NuvioMeta(id: contentId, name: "Dismiss test", type: "series"),
            streamUrl: "",
            position: 100,
            duration: 1_800,
            lastWatchedAt: Date(timeIntervalSince1970: 1_700_000_000),
            season: 1,
            episode: 1
        )
    }

    // MARK: - Continue Watching Sync Tests

    func testContinueWatchingSortModeMapping() {
        XCTAssertEqual(ContinueWatchingSyncMapper.sortModeToWire("Default"), "DEFAULT")
        XCTAssertEqual(ContinueWatchingSyncMapper.sortModeToWire("Streaming Style"), "STREAMING_STYLE")
        XCTAssertEqual(ContinueWatchingSyncMapper.sortModeToWire("Separate Upcoming Row"), "DEFAULT")
        XCTAssertEqual(ContinueWatchingSyncMapper.sortModeToWire(nil), "DEFAULT")

        XCTAssertEqual(ContinueWatchingSyncMapper.sortModeFromWire("STREAMING_STYLE"), "Streaming Style")
        XCTAssertEqual(ContinueWatchingSyncMapper.sortModeFromWire("DEFAULT"), "Default")
        XCTAssertEqual(ContinueWatchingSyncMapper.sortModeFromWire(nil), "Default")
        XCTAssertEqual(ContinueWatchingSyncMapper.sortModeFromWire("UNKNOWN"), "Default")
    }

    func testContinueWatchingExportPayload() {
        let payload = ContinueWatchingSyncMapper.exportPayload(
            upNextFromFurthestEpisode: true,
            showUnairedNextUp: false,
            continueWatchingSort: "Streaming Style",
            existingPayload: nil
        )

        XCTAssertFalse(payload.isEmpty)
        guard let data = payload.data(using: .utf8),
              let json = (try? JSONSerialization.jsonObject(with: data)) as? [String: Any] else {
            XCTFail("Failed to parse exported JSON payload")
            return
        }

        XCTAssertEqual(json["upNextFromFurthestEpisode"] as? Bool, true)
        XCTAssertEqual(json["show_unaired_next_up"] as? Bool, false)
        XCTAssertEqual(json["sort_mode"] as? String, "STREAMING_STYLE")
        XCTAssertEqual(json["isVisible"] as? Bool, true)
        XCTAssertEqual(json["style"] as? String, "Card")
    }

    func testContinueWatchingExportPreservesAuxiliaryFields() {
        ContinueWatchingDismissStore.replaceKeys(
            ["tt1234567|1|1", "tt7654321|2|3"],
            profileId: dismissalTestProfileId
        )
        let existingPayload = """
        {
            "isVisible": false,
            "style": "Poster",
            "use_episode_thumbnails_in_cw": false,
            "blur_continue_watching_next_up": true,
            "showResumePromptOnLaunch": false,
            "sort_mode": "DEFAULT"
        }
        """

        let payload = ContinueWatchingSyncMapper.exportPayload(
            localProfileId: dismissalTestProfileId,
            upNextFromFurthestEpisode: false,
            showUnairedNextUp: true,
            continueWatchingSort: "Streaming Style",
            existingPayload: existingPayload
        )

        guard let data = payload.data(using: .utf8),
              let json = (try? JSONSerialization.jsonObject(with: data)) as? [String: Any] else {
            XCTFail("Failed to parse exported JSON payload")
            return
        }

        XCTAssertEqual(json["isVisible"] as? Bool, false)
        XCTAssertEqual(json["style"] as? String, "Poster")
        XCTAssertEqual(json["use_episode_thumbnails_in_cw"] as? Bool, false)
        XCTAssertEqual(json["blur_continue_watching_next_up"] as? Bool, true)
        XCTAssertEqual((json["dismissedNextUpKeys"] as? [String])?.count, 2)
        XCTAssertEqual(json["showResumePromptOnLaunch"] as? Bool, false)
        XCTAssertEqual(json["upNextFromFurthestEpisode"] as? Bool, false)
        XCTAssertEqual(json["show_unaired_next_up"] as? Bool, true)
        XCTAssertEqual(json["sort_mode"] as? String, "STREAMING_STYLE")
    }

    func testContinueWatchingExportDoesNotResurrectClearedDismissals() {
        // Given existing payload had a dismissal for tt33546863
        let existingPayload = """
        {
            "dismissedNextUpKeys": ["tt33546863|-1|-1", "tt1234567|1|1"]
        }
        """
        // But local store only has tt1234567|1|1 because tt33546863 was cleared on watch
        ContinueWatchingDismissStore.replaceKeys(["tt1234567|1|1"], profileId: dismissalTestProfileId)

        let payload = ContinueWatchingSyncMapper.exportPayload(
            localProfileId: dismissalTestProfileId,
            upNextFromFurthestEpisode: true,
            showUnairedNextUp: true,
            continueWatchingSort: "Default",
            existingPayload: existingPayload
        )

        guard let data = payload.data(using: .utf8),
              let json = (try? JSONSerialization.jsonObject(with: data)) as? [String: Any],
              let dismissed = json["dismissedNextUpKeys"] as? [String] else {
            XCTFail("Failed to parse exported JSON payload")
            return
        }

        XCTAssertEqual(dismissed, ["tt1234567|1|1"])
        XCTAssertFalse(dismissed.contains("tt33546863|-1|-1"))
    }

    func testContinueWatchingImportPayload() {
        let remoteJson = """
        {
            "isVisible": false,
            "upNextFromFurthestEpisode": false,
            "show_unaired_next_up": false,
            "sort_mode": "STREAMING_STYLE",
            "dismissedNextUpKeys": ["tt1234567|1|1"]
        }
        """

        let (isVisible, upNext, showUnaired, sortMode, dismissedKeys) = ContinueWatchingSyncMapper.importPayload(remoteJson)
        XCTAssertEqual(isVisible, false)
        XCTAssertEqual(upNext, false)
        XCTAssertEqual(showUnaired, false)
        XCTAssertEqual(sortMode, "Streaming Style")
        XCTAssertEqual(dismissedKeys, ["tt1234567|1|1"])
    }

    func testAndroidTraktDismissalStringSetRoundTripPreservesOtherPreferences() {
        let existing: [String: Any] = [
            "sync_enabled": ["type": "boolean", "value": true],
            "sort_order": ["type": "string", "value": "recent"]
        ]
        let exported = ContinueWatchingSyncMapper.exportAndroidTraktFeature(
            existing: existing,
            dismissedKeys: [
                "tt-plain",
                "tt-legacy|1|2",
                "tt-unit\u{1f}3\u{1f}4"
            ]
        )
        let entry = exported[ContinueWatchingSyncMapper.androidDismissedNextUpKeysKey] as? [String: Any]
        XCTAssertEqual(entry?["type"] as? String, "string_set")
        XCTAssertEqual(entry?["value"] as? [String], ["tt-legacy", "tt-plain", "tt-unit"])
        XCTAssertEqual((exported["sync_enabled"] as? [String: Any])?["value"] as? Bool, true)
        XCTAssertEqual((exported["sort_order"] as? [String: Any])?["value"] as? String, "recent")

        let imported = ContinueWatchingSyncMapper.androidDismissalKeys(from: exported)
        XCTAssertTrue(imported.isPresent)
        XCTAssertEqual(
            imported.keys,
            Set(["tt-legacy|-1|-1", "tt-plain|-1|-1", "tt-unit|-1|-1"])
        )
    }

    func testAndroidTraktDismissalImportNormalizesPlainAndLegacyIDs() {
        let feature: [String: Any] = [
            ContinueWatchingSyncMapper.androidDismissedNextUpKeysKey: [
                "type": "string_set",
                "value": [
                    " tt-plain ",
                    "tt-pipe|2|4",
                    "tt-unit\u{1f}3\u{1f}5"
                ]
            ]
        ]

        let imported = ContinueWatchingSyncMapper.androidDismissalKeys(from: feature)
        XCTAssertTrue(imported.isPresent)
        XCTAssertEqual(
            imported.keys,
            Set(["tt-plain|-1|-1", "tt-pipe|-1|-1", "tt-unit|-1|-1"])
        )
    }

    func testAndroidEmptyDismissalSetOverridesStaleLegacyPayload() {
        let androidFeature: [String: Any] = [
            ContinueWatchingSyncMapper.androidDismissedNextUpKeysKey: [
                "type": "string_set",
                "value": [String]()
            ]
        ]
        let legacyPayload: [String: Any] = [
            "dismissedNextUpKeys": ["tt-stale|-1|-1"]
        ]

        let imported = ContinueWatchingSyncMapper.dismissalKeysForImport(
            androidTraktFeature: androidFeature,
            legacyPayload: legacyPayload
        )

        XCTAssertTrue(imported.isPresent)
        XCTAssertEqual(imported.keys, [])
    }

    func testMalformedAndroidDismissalEntryDoesNotFallBackToStaleLegacyPayload() {
        let malformedFeatures: [[String: Any]] = [
            [
                ContinueWatchingSyncMapper.androidDismissedNextUpKeysKey: [
                    "type": "string",
                    "value": ["tt-android"]
                ]
            ],
            [
                ContinueWatchingSyncMapper.androidDismissedNextUpKeysKey: [
                    "type": "string_set",
                    "value": ["tt-android", 7]
                ]
            ]
        ]
        let legacyPayload: [String: Any] = [
            "dismissedNextUpKeys": ["tt-stale|-1|-1"]
        ]

        for feature in malformedFeatures {
            let imported = ContinueWatchingSyncMapper.dismissalKeysForImport(
                androidTraktFeature: feature,
                legacyPayload: legacyPayload
            )
            XCTAssertTrue(imported.isPresent)
            XCTAssertNil(imported.keys)
        }
    }

    func testAbsentAndroidDismissalEntryFallsBackToLegacyPayload() {
        let legacyPayload: [String: Any] = [
            "dismissedNextUpKeys": ["tt-legacy|2|3"]
        ]

        let imported = ContinueWatchingSyncMapper.dismissalKeysForImport(
            androidTraktFeature: ["other_setting": true],
            legacyPayload: legacyPayload
        )

        XCTAssertTrue(imported.isPresent)
        XCTAssertEqual(imported.keys, ["tt-legacy|2|3"])
    }

    func testClearedDismissalFiltersStaleImportedKeysAndExport() {
        let contentId = "tt-resumed-dismissal"
        ContinueWatchingDismissStore.dismiss(makeDismissalTestItem(contentId: contentId))
        ContinueWatchingDismissStore.clear(contentId: contentId)

        ContinueWatchingDismissStore.replaceKeys(
            ["\(contentId)|4|5", "tt-unrelated|1|1"],
            profileId: dismissalTestProfileId
        )

        XCTAssertEqual(ContinueWatchingDismissStore.keys(profileId: dismissalTestProfileId), ["tt-unrelated|1|1"])
        let payload = ContinueWatchingSyncMapper.exportPayload(
            localProfileId: dismissalTestProfileId,
            upNextFromFurthestEpisode: false,
            showUnairedNextUp: true,
            continueWatchingSort: "Default",
            existingPayload: nil
        )
        let json = try! XCTUnwrap(JSONSerialization.jsonObject(with: Data(payload.utf8)) as? [String: Any])
        XCTAssertEqual(json["dismissedNextUpKeys"] as? [String], ["tt-unrelated|1|1"])
    }

    func testClearWithoutLocalDismissalPersistsMarkerAndBlocksStaleImport() {
        let contentId = "tt-clear-before-import"
        ContinueWatchingDismissStore.clear(contentId: " \(contentId) ")

        let markerStorageKey = "nuvio.tv.continueWatching.resumedContentIDs.\(dismissalTestProfileId)"
        XCTAssertEqual(UserDefaults.standard.stringArray(forKey: markerStorageKey), [contentId])

        ContinueWatchingDismissStore.replaceKeys(
            ["\(contentId)|-1|-1", "tt-preserved|2|3"],
            profileId: dismissalTestProfileId
        )
        XCTAssertEqual(ContinueWatchingDismissStore.keys(profileId: dismissalTestProfileId), ["tt-preserved|2|3"])

        ContinueWatchingDismissStore.eraseProfile(dismissalTestProfileId)
        XCTAssertNil(UserDefaults.standard.object(forKey: markerStorageKey))
    }

    func testPersistedResumeMarkerLoadsAndFiltersExportedKeys() {
        let profileId = "\(dismissalTestProfileId)-persisted"
        defer { ContinueWatchingDismissStore.eraseProfile(profileId) }
        let contentId = "tt-persisted-resume-marker"
        let markerStorageKey = "nuvio.tv.continueWatching.resumedContentIDs.\(profileId)"
        let dismissalStorageKey = "nuvio.tv.continueWatching.dismissedKeys.\(profileId)"
        UserDefaults.standard.set([contentId], forKey: markerStorageKey)
        UserDefaults.standard.set(["\(contentId)|-1|-1", "tt-persisted-unrelated|1|1"], forKey: dismissalStorageKey)

        let payload = ContinueWatchingSyncMapper.exportPayload(
            localProfileId: profileId,
            upNextFromFurthestEpisode: false,
            showUnairedNextUp: true,
            continueWatchingSort: "Default",
            existingPayload: nil
        )
        let json = try! XCTUnwrap(JSONSerialization.jsonObject(with: Data(payload.utf8)) as? [String: Any])
        XCTAssertEqual(json["dismissedNextUpKeys"] as? [String], ["tt-persisted-unrelated|1|1"])
    }

    func testEraseAllProfilesRemovesResumeMarkersAndRestoresOtherStoredProfiles() {
        let defaults = UserDefaults.standard
        let relevantPrefixes = [
            "nuvio.tv.continueWatching.dismissedKeys",
            "nuvio.tv.continueWatching.pendingDismissedKeys",
            "nuvio.tv.continueWatching.resumedContentIDs"
        ]
        let previousValues = defaults.dictionaryRepresentation().filter { key, _ in
            relevantPrefixes.contains(where: key.hasPrefix)
        }
        defer {
            defaults.dictionaryRepresentation().keys
                .filter { key in relevantPrefixes.contains(where: key.hasPrefix) }
                .forEach { defaults.removeObject(forKey: $0) }
            previousValues.forEach { defaults.set($0.value, forKey: $0.key) }
        }

        let markerStorageKey = "nuvio.tv.continueWatching.resumedContentIDs.\(dismissalTestProfileId)"
        defaults.set(["tt-erase-all-marker"], forKey: markerStorageKey)
        ContinueWatchingDismissStore.eraseAllProfiles()

        XCTAssertNil(defaults.object(forKey: markerStorageKey))
    }

    func testClearMatchesCanonicalLegacyBareAndWildcardKeysButPreservesOtherTitles() {
        let legacyId = "tt-legacy-resumed"
        let bareId = "tt-bare-resumed"
        let wildcardId = "tt-wildcard-resumed"
        let canonicalId = "tt-canonical-resumed"
        [legacyId, bareId, wildcardId, canonicalId].forEach {
            ContinueWatchingDismissStore.clear(contentId: $0)
        }

        let legacySeparator = "\u{1f}"
        let importedKeys: Set<String> = [
            "\(legacyId)\(legacySeparator)1\(legacySeparator)2",
            bareId,
            "\(wildcardId)|-1|-1",
            "\(canonicalId)|3|4",
            "tt-kept-canonical|1|2",
            "tt-kept-legacy\(legacySeparator)4\(legacySeparator)5",
            " tt-kept-bare "
        ]

        ContinueWatchingDismissStore.replaceKeys(importedKeys, profileId: dismissalTestProfileId)

        XCTAssertEqual(
            ContinueWatchingDismissStore.keys(profileId: dismissalTestProfileId),
            ["tt-kept-canonical|1|2", "tt-kept-legacy\(legacySeparator)4\(legacySeparator)5", " tt-kept-bare "]
        )
    }

    func testExplicitRedismissThroughBothOverloadsRemovesResumeMarker() {
        let itemId = "tt-redismiss-item"
        ContinueWatchingDismissStore.clear(contentId: itemId)
        ContinueWatchingDismissStore.dismiss(makeDismissalTestItem(contentId: itemId))
        ContinueWatchingDismissStore.replaceKeys(["\(itemId)|2|3"], profileId: dismissalTestProfileId)
        XCTAssertEqual(ContinueWatchingDismissStore.keys(profileId: dismissalTestProfileId), ["\(itemId)|2|3"])

        let contentId = "tt-redismiss-content-id"
        ContinueWatchingDismissStore.clear(contentId: contentId)
        ContinueWatchingDismissStore.dismiss(contentId: contentId)
        ContinueWatchingDismissStore.replaceKeys(["\(contentId)|2|3"], profileId: dismissalTestProfileId)
        XCTAssertEqual(ContinueWatchingDismissStore.keys(profileId: dismissalTestProfileId), ["\(contentId)|2|3"])
    }

    func testResumeMarkersAreIsolatedByProfile() {
        let otherProfileId = "\(dismissalTestProfileId)-other"
        defer { ContinueWatchingDismissStore.eraseProfile(otherProfileId) }
        let contentId = "tt-profile-resume-marker"
        let staleKey = "\(contentId)|1|1"

        ContinueWatchingDismissStore.clear(contentId: contentId)
        ContinueWatchingDismissStore.setActiveProfile(otherProfileId)
        ContinueWatchingDismissStore.replaceKeys([staleKey], profileId: otherProfileId)
        XCTAssertEqual(ContinueWatchingDismissStore.keys(profileId: otherProfileId), [staleKey])

        ContinueWatchingDismissStore.setActiveProfile(dismissalTestProfileId)
        ContinueWatchingDismissStore.replaceKeys([staleKey], profileId: dismissalTestProfileId)
        XCTAssertTrue(ContinueWatchingDismissStore.keys(profileId: dismissalTestProfileId).isEmpty)
    }

    // MARK: - Player Settings Sync Tests

    func testPlayerSettingsMergeIsMobileFirstAndPreservesUnknownKeys() {
        let merged = PlayerSettingsSyncMapper.mergeRemoteSettings(
            mobile: ["stream_auto_play_mode": "FIRST_STREAM", "shared": "mobile"],
            tv: ["stream_auto_play_mode": "AUTO", "tv_only": true, "shared": "tv"]
        )
        XCTAssertEqual(merged["stream_auto_play_mode"] as? String, "FIRST_STREAM")
        XCTAssertEqual(merged["tv_only"] as? Bool, true)
        XCTAssertEqual(merged["shared"] as? String, "mobile")

        let overlaid = PlayerSettingsSyncMapper.overlayOwnedSettings(
            merged,
            with: ["smart_stream_selection": true, "shared": "tvos-owned"]
        )
        XCTAssertEqual(overlaid["stream_auto_play_mode"] as? String, "FIRST_STREAM")
        XCTAssertEqual(overlaid["tv_only"] as? Bool, true)
        XCTAssertEqual(overlaid["smart_stream_selection"] as? Bool, true)
        XCTAssertEqual(overlaid["shared"] as? String, "tvos-owned")
    }

    func testPlayerSettingsKeyMappingsCoverage() {
        let localKeys = PlayerSettingsSyncMapper.localToRemoteKeyMappings.map(\.local)
        XCTAssertTrue(localKeys.contains(SettingsKey.audioLanguage))
        XCTAssertTrue(localKeys.contains(SettingsKey.subtitleLanguage))
        XCTAssertTrue(localKeys.contains(SettingsKey.subtitleLanguageSecondary))
        XCTAssertTrue(localKeys.contains(SettingsKey.forcedSubtitles))
        XCTAssertTrue(localKeys.contains(SettingsKey.autoPlayNext))
        XCTAssertTrue(localKeys.contains(SettingsKey.autoPlayNextCountdown))
        XCTAssertTrue(localKeys.contains(SettingsKey.cachedOnlyStreams))
        XCTAssertTrue(localKeys.contains(SettingsKey.preserveAddonStreamOrder))
        XCTAssertTrue(localKeys.contains(SettingsKey.streamSortOption))
        XCTAssertTrue(localKeys.contains(SettingsKey.smartStreamSelection))
        XCTAssertTrue(localKeys.contains(SettingsKey.smartStreamUseTopResult))
        XCTAssertTrue(localKeys.contains(SettingsKey.smartStreamQuality))
        XCTAssertTrue(localKeys.contains(SettingsKey.externalPlayerForwardSubtitles))
        XCTAssertTrue(localKeys.contains(SettingsKey.frameRateMatching))
        XCTAssertTrue(localKeys.contains(SettingsKey.playerShowPiP))
        XCTAssertTrue(localKeys.contains(SettingsKey.playerShowEpisodes))
        XCTAssertTrue(localKeys.contains(SettingsKey.playerShowSources))
        XCTAssertTrue(localKeys.contains(SettingsKey.playerShowSubtitles))
        XCTAssertTrue(localKeys.contains(SettingsKey.seekPreviewEnabled))
        XCTAssertTrue(localKeys.contains(SettingsKey.showLoadingStatus))
        XCTAssertTrue(localKeys.contains(SettingsKey.streamAutoPlayPreferBingeGroup))
        XCTAssertTrue(localKeys.contains(SettingsKey.streamAutoPlayReuseBingeGroup))

        let remoteKeys = PlayerSettingsSyncMapper.remoteToLocalKeyMappings.map(\.remote)
        XCTAssertTrue(remoteKeys.contains("preferred_audio_language"))
        XCTAssertTrue(remoteKeys.contains("preferred_subtitle_language"))
        XCTAssertTrue(remoteKeys.contains("secondary_preferred_subtitle_language"))
        XCTAssertTrue(remoteKeys.contains("subtitle_use_forced_subtitles"))
        XCTAssertTrue(remoteKeys.contains("stream_auto_play_next_episode_enabled"))
        XCTAssertTrue(remoteKeys.contains("stream_auto_play_timeout_seconds"))
        XCTAssertTrue(remoteKeys.contains("stream_auto_play_prefer_binge_group"))
        XCTAssertTrue(remoteKeys.contains("stream_auto_play_reuse_binge_group"))
        XCTAssertTrue(remoteKeys.contains("stream_cached_only"))
        XCTAssertTrue(remoteKeys.contains("cached_only_streams"))
        XCTAssertTrue(remoteKeys.contains("preserve_addon_stream_order"))
        XCTAssertTrue(remoteKeys.contains("stream_sort_mode"))
        XCTAssertTrue(remoteKeys.contains("smart_stream_selection"))
        XCTAssertTrue(remoteKeys.contains("smart_stream_use_top_result"))
        XCTAssertTrue(remoteKeys.contains("smart_stream_quality"))
        XCTAssertTrue(remoteKeys.contains("external_player_forward_subtitles"))
        XCTAssertTrue(remoteKeys.contains("frame_rate_matching"))
        XCTAssertTrue(remoteKeys.contains("player_show_pip"))
        XCTAssertTrue(remoteKeys.contains("player_show_episodes"))
        XCTAssertTrue(remoteKeys.contains("player_show_sources"))
        XCTAssertTrue(remoteKeys.contains("player_show_subtitles"))
        XCTAssertTrue(remoteKeys.contains("seek_preview_enabled"))
        XCTAssertTrue(remoteKeys.contains("show_player_loading_status"))
        XCTAssertTrue(remoteKeys.contains("player_show_loading_status"))
    }

    func testAutoPlayModeWireMapping() {
        XCTAssertEqual(PlayerSettingsSyncMapper.autoPlayModeToWire(useTopResult: true, smartSelection: true, existingWireMode: nil), "FIRST_STREAM")
        XCTAssertEqual(PlayerSettingsSyncMapper.autoPlayModeToWire(useTopResult: false, smartSelection: true, existingWireMode: nil), "MANUAL")
        XCTAssertEqual(PlayerSettingsSyncMapper.autoPlayModeToWire(useTopResult: false, smartSelection: false, existingWireMode: "REGEX_MATCH"), "REGEX_MATCH")
        XCTAssertEqual(PlayerSettingsSyncMapper.autoPlayModeToWire(useTopResult: true, smartSelection: true, existingWireMode: "REGEX_MATCH"), "FIRST_STREAM")

        let first = PlayerSettingsSyncMapper.autoPlayModeFromWire("FIRST_STREAM")
        XCTAssertEqual(first?.useTopResult, true)
        XCTAssertEqual(first?.smartSelection, true)

        let manual = PlayerSettingsSyncMapper.autoPlayModeFromWire("MANUAL")
        XCTAssertEqual(manual?.useTopResult, false)
        XCTAssertEqual(manual?.smartSelection, false)

        let regex = PlayerSettingsSyncMapper.autoPlayModeFromWire("REGEX_MATCH")
        XCTAssertEqual(regex?.useTopResult, false)
        XCTAssertEqual(regex?.smartSelection, false)

        XCTAssertNil(PlayerSettingsSyncMapper.autoPlayModeFromWire(nil))
        XCTAssertNil(PlayerSettingsSyncMapper.autoPlayModeFromWire(""))
    }

    func testPlayerSettingsExportAutoPlayFirstSource() {
        let testProfileId = "test_player_export_\(UUID().uuidString)"
        let store = ProfileSettings.store(for: testProfileId)
        defer {
            store.removeObject(forKey: SettingsKey.smartStreamUseTopResult)
            store.removeObject(forKey: SettingsKey.smartStreamSelection)
        }

        store.set(true, forKey: SettingsKey.smartStreamUseTopResult)
        store.set(true, forKey: SettingsKey.smartStreamSelection)

        let exported = PlayerSettingsSyncMapper.exportPayload(
            localProfileId: testProfileId,
            existing: nil,
            encodeValue: { val in ["type": "mock", "value": val] }
        )

        let modeDict = exported[PlayerSettingsSyncMapper.streamAutoPlayModeRemoteKey] as? [String: Any]
        XCTAssertEqual(modeDict?["value"] as? String, "FIRST_STREAM")

        let topDict = exported[PlayerSettingsSyncMapper.smartStreamUseTopResultRemoteKey] as? [String: Any]
        XCTAssertEqual(topDict?["value"] as? Bool, true)

        store.set(false, forKey: SettingsKey.smartStreamUseTopResult)
        let exportedManual = PlayerSettingsSyncMapper.exportPayload(
            localProfileId: testProfileId,
            existing: exported,
            encodeValue: { val in ["type": "mock", "value": val] }
        )

        let modeDictManual = exportedManual[PlayerSettingsSyncMapper.streamAutoPlayModeRemoteKey] as? [String: Any]
        XCTAssertEqual(modeDictManual?["value"] as? String, "MANUAL")

        let topDictManual = exportedManual[PlayerSettingsSyncMapper.smartStreamUseTopResultRemoteKey] as? [String: Any]
        XCTAssertEqual(topDictManual?["value"] as? Bool, false)
    }

    func testPlayerSettingsImportAutoPlayFirstSource() {
        let testProfileId = "test_player_import_\(UUID().uuidString)"
        let store = ProfileSettings.store(for: testProfileId)
        defer {
            store.removeObject(forKey: SettingsKey.smartStreamUseTopResult)
            store.removeObject(forKey: SettingsKey.smartStreamSelection)
        }

        // Import FIRST_STREAM from remote (Android TV / mobile / desktop / website)
        let remoteFirstStream: [String: Any] = [
            PlayerSettingsSyncMapper.streamAutoPlayModeRemoteKey: [
                "type": "string",
                "value": "FIRST_STREAM"
            ]
        ]
        PlayerSettingsSyncMapper.importPayload(
            remoteFirstStream,
            localProfileId: testProfileId,
            decodeValue: { dict in dict["value"] }
        )
        XCTAssertEqual(store.bool(forKey: SettingsKey.smartStreamUseTopResult), true)
        XCTAssertEqual(store.bool(forKey: SettingsKey.smartStreamSelection), true)

        // Import MANUAL from remote (without explicit smart_stream_selection)
        let remoteManual: [String: Any] = [
            PlayerSettingsSyncMapper.streamAutoPlayModeRemoteKey: [
                "type": "string",
                "value": "MANUAL"
            ]
        ]
        PlayerSettingsSyncMapper.importPayload(
            remoteManual,
            localProfileId: testProfileId,
            decodeValue: { dict in dict["value"] }
        )
        XCTAssertEqual(store.bool(forKey: SettingsKey.smartStreamUseTopResult), false)
        XCTAssertEqual(store.bool(forKey: SettingsKey.smartStreamSelection), false)

        // Import MANUAL with explicit tvOS peer smart_stream_selection: true
        let remoteManualWithTvSmart: [String: Any] = [
            PlayerSettingsSyncMapper.streamAutoPlayModeRemoteKey: [
                "type": "string",
                "value": "MANUAL"
            ],
            PlayerSettingsSyncMapper.smartStreamSelectionRemoteKey: [
                "type": "boolean",
                "value": true
            ]
        ]
        PlayerSettingsSyncMapper.importPayload(
            remoteManualWithTvSmart,
            localProfileId: testProfileId,
            decodeValue: { dict in dict["value"] }
        )
        XCTAssertEqual(store.bool(forKey: SettingsKey.smartStreamUseTopResult), false)
        XCTAssertEqual(store.bool(forKey: SettingsKey.smartStreamSelection), true)

        // Legacy fallback: smart_stream_use_top_result without stream_auto_play_mode
        let remoteLegacyFallback: [String: Any] = [
            PlayerSettingsSyncMapper.smartStreamUseTopResultRemoteKey: [
                "type": "boolean",
                "value": true
            ]
        ]
        PlayerSettingsSyncMapper.importPayload(
            remoteLegacyFallback,
            localProfileId: testProfileId,
            decodeValue: { dict in dict["value"] }
        )
        XCTAssertEqual(store.bool(forKey: SettingsKey.smartStreamUseTopResult), true)
        XCTAssertEqual(store.bool(forKey: SettingsKey.smartStreamSelection), true)
    }

    // MARK: - MDBList Settings Sync Tests

    func testMdbListSettingsKeyMappingsCoverage() {
        let localKeys = MdbListSyncMapper.localToRemoteKeyMappings.map(\.local)
        XCTAssertTrue(localKeys.contains(SettingsKey.mdbListEnabled))
        XCTAssertTrue(localKeys.contains(SettingsKey.mdbListApiKey))
        XCTAssertTrue(localKeys.contains(SettingsKey.mdbListUseImdb))
        XCTAssertTrue(localKeys.contains(SettingsKey.mdbListUseTmdb))
        XCTAssertTrue(localKeys.contains(SettingsKey.mdbListUseTomatoes))
        XCTAssertTrue(localKeys.contains(SettingsKey.mdbListUseMetacritic))
        XCTAssertTrue(localKeys.contains(SettingsKey.mdbListUseTrakt))
        XCTAssertTrue(localKeys.contains(SettingsKey.mdbListUseLetterboxd))
        XCTAssertTrue(localKeys.contains(SettingsKey.mdbListUseAudience))

        let remoteKeys = MdbListSyncMapper.remoteToLocalKeyMappings.map(\.remote)
        XCTAssertTrue(remoteKeys.contains("mdblist_enabled"))
        XCTAssertTrue(remoteKeys.contains("mdblist_api_key"))
        XCTAssertTrue(remoteKeys.contains("mdblist_use_imdb"))
        XCTAssertTrue(remoteKeys.contains("mdblist_use_tmdb"))
        XCTAssertTrue(remoteKeys.contains("mdblist_use_tomatoes"))
        XCTAssertTrue(remoteKeys.contains("mdblist_use_metacritic"))
        XCTAssertTrue(remoteKeys.contains("mdblist_use_trakt"))
        XCTAssertTrue(remoteKeys.contains("mdblist_use_letterboxd"))
        XCTAssertTrue(remoteKeys.contains("mdblist_use_audience"))
    }

    // MARK: - Theme / Focus Color Settings Sync Tests

    func testThemeSettingsSyncMapping() {
        // Test Pink / Rose theme mapping
        XCTAssertEqual(ThemeSettingsSyncMapper.themeToWire("Rose"), "ROSE")
        XCTAssertEqual(ThemeSettingsSyncMapper.themeToWire("Pink"), "ROSE")
        XCTAssertEqual(ThemeSettingsSyncMapper.wireToTheme("ROSE"), "Rose")

        // Test Sky / Ocean
        XCTAssertEqual(ThemeSettingsSyncMapper.themeToWire("Sky"), "OCEAN")
        XCTAssertEqual(ThemeSettingsSyncMapper.wireToTheme("OCEAN"), "Sky")

        // Test Emerald
        XCTAssertEqual(ThemeSettingsSyncMapper.themeToWire("Emerald"), "EMERALD")
        XCTAssertEqual(ThemeSettingsSyncMapper.wireToTheme("EMERALD"), "Emerald")

        // Test Amber
        XCTAssertEqual(ThemeSettingsSyncMapper.themeToWire("Amber"), "AMBER")
        XCTAssertEqual(ThemeSettingsSyncMapper.wireToTheme("AMBER"), "Amber")

        // Test Violet
        XCTAssertEqual(ThemeSettingsSyncMapper.themeToWire("Violet"), "VIOLET")
        XCTAssertEqual(ThemeSettingsSyncMapper.wireToTheme("VIOLET"), "Violet")

        // Test White
        XCTAssertEqual(ThemeSettingsSyncMapper.themeToWire("White"), "WHITE")
        XCTAssertEqual(ThemeSettingsSyncMapper.wireToTheme("WHITE"), "White")
    }

    // MARK: - Settings Sync Flush Tests

    @MainActor
    func testSettingsFlushPendingPushesDoesNotCrashWhenUnauthenticated() async {
        let manager = NuvioSyncManager()
        // Calling flush on a manager with no auth/profile should safely complete without throwing or hanging
        await manager.flushPendingPushesNow()
        manager.flushPendingPushes()
    }

    @MainActor
    func testProgressHeartbeatSyncDebounceAndFlush() async {
        XCTAssertEqual(NuvioSyncManager.progressHeartbeatInterval, 30.0)
        XCTAssertEqual(NuvioSyncManager.defaultPushDelay, 1.5)

        let manager = NuvioSyncManager()
        // Multiple rapid progress schedule calls should not crash or throw
        manager.schedulePush(scope: .progress, delay: NuvioSyncManager.progressHeartbeatInterval)
        manager.schedulePush(scope: .progress, delay: NuvioSyncManager.progressHeartbeatInterval)
        // Shorter delay (e.g. settings or immediate flush) accelerates
        manager.schedulePush(scope: .settings, delay: NuvioSyncManager.defaultPushDelay)
        await manager.flushPendingPushesNow()
    }

    // MARK: - WatchedStore & Re-watch Tests

    func testWatchedSnapshotWatchedAtWithAliasing() {
        let watchedDate = Date(timeIntervalSince1970: 1_700_000_000)
        let seriesMeta = NuvioMeta(
            id: "tt1234567",
            name: "Test Show",
            description: nil,
            posterUrl: nil,
            backgroundUrl: nil,
            logoUrl: nil,
            imdbId: "tt1234567",
            tmdbId: 100,
            type: "series",
            year: 2024,
            genres: nil,
            rating: nil,
            releaseInfo: nil,
            runtime: nil,
            cast: nil,
            director: nil,
            writer: nil,
            certification: nil,
            country: nil,
            released: nil,
            videos: []
        )
        let episodeItem = WatchedStoreItem(
            meta: seriesMeta,
            watchedAt: watchedDate,
            season: 1,
            episode: 1,
            sources: [TraktWatchProgressSource.nuvioSync.rawValue]
        )
        let movieMeta = NuvioMeta(
            id: "tt7654321",
            name: "Test Movie",
            description: nil,
            posterUrl: nil,
            backgroundUrl: nil,
            logoUrl: nil,
            imdbId: "tt7654321",
            tmdbId: 200,
            type: "movie",
            year: 2024,
            genres: nil,
            rating: nil,
            releaseInfo: nil,
            runtime: nil,
            cast: nil,
            director: nil,
            writer: nil,
            certification: nil,
            country: nil,
            released: nil,
            videos: []
        )
        let movieItem = WatchedStoreItem(
            meta: movieMeta,
            watchedAt: watchedDate,
            season: nil,
            episode: nil,
            sources: [TraktWatchProgressSource.nuvioSync.rawValue]
        )

        let snapshot = WatchedSnapshot(items: [episodeItem, movieItem], source: .nuvioSync)

        // Exact match
        XCTAssertEqual(snapshot.watchedAt(metaId: "tt1234567", season: 1, episode: 1), watchedDate)
        // Alias match with imdb prefix
        XCTAssertEqual(snapshot.watchedAt(metaId: "imdb:tt1234567", season: 1, episode: 1), watchedDate)
        // Different episode returns nil
        XCTAssertNil(snapshot.watchedAt(metaId: "tt1234567", season: 1, episode: 2))

        // Movie match
        XCTAssertEqual(snapshot.watchedAt(metaId: "tt7654321"), watchedDate)
        XCTAssertEqual(snapshot.watchedAt(metaId: "imdb:tt7654321"), watchedDate)
        XCTAssertNil(snapshot.watchedAt(metaId: "tt9999999"))
    }

    func testContinueWatchingCandidatesAllowsRewatchingAfterWatchedStoreMark() {
        let movieMeta = NuvioMeta(
            id: "tt8888888",
            name: "Rewatch Movie",
            description: nil,
            posterUrl: nil,
            backgroundUrl: nil,
            logoUrl: nil,
            imdbId: "tt8888888",
            tmdbId: 300,
            type: "movie",
            year: 2024,
            genres: nil,
            rating: nil,
            releaseInfo: nil,
            runtime: nil,
            cast: nil,
            director: nil,
            writer: nil,
            certification: nil,
            country: nil,
            released: nil,
            videos: []
        )

        let seriesMeta = NuvioMeta(
            id: "tt8888889",
            name: "Rewatch Series",
            description: nil,
            posterUrl: nil,
            backgroundUrl: nil,
            logoUrl: nil,
            imdbId: "tt8888889",
            tmdbId: 301,
            type: "series",
            year: 2024,
            genres: nil,
            rating: nil,
            releaseInfo: nil,
            runtime: nil,
            cast: nil,
            director: nil,
            writer: nil,
            certification: nil,
            country: nil,
            released: nil,
            videos: []
        )

        let movieKey = WatchProgressLedger.progressKey(contentId: movieMeta.id, season: nil, episode: nil)
        let episodeKey = WatchProgressLedger.progressKey(contentId: seriesMeta.id, season: 1, episode: 1)

        defer {
            _ = WatchProgressLedger.remove(keys: [movieKey, episodeKey])
            if WatchedStore.contains(meta: movieMeta) {
                _ = WatchedStore.toggle(meta: movieMeta)
            }
            if WatchedStore.containsEpisode(meta: seriesMeta, season: 1, episode: 1) {
                _ = WatchedStore.toggleEpisode(meta: seriesMeta, season: 1, episode: 1)
            }
        }

        // Mark both as watched now
        XCTAssertTrue(WatchedStore.markWatched(movieMeta))
        XCTAssertTrue(WatchedStore.markWatched(seriesMeta, season: 1, episode: 1))

        guard let movieWatchedAt = WatchedStore.watchedAt(meta: movieMeta),
              let episodeWatchedAt = WatchedStore.watchedAt(meta: seriesMeta, season: 1, episode: 1) else {
            XCTFail("Watched dates should be recorded")
            return
        }

        // 1. Progress recorded BEFORE the watched mark must NOT be offered as a candidate
        let oldMovieRecord = WatchProgressRecord(
            progressKey: movieKey,
            contentId: movieMeta.id,
            contentType: movieMeta.type,
            videoId: movieMeta.id,
            season: nil,
            episode: nil,
            position: 300,
            duration: 1000,
            lastWatchedAt: movieWatchedAt.addingTimeInterval(-60),
            isPendingPush: false
        )
        _ = WatchProgressLedger.upsert(oldMovieRecord)
        XCTAssertFalse(WatchProgressLedger.continueWatchingCandidates().contains { $0.contentId == movieMeta.id })

        let oldEpisodeRecord = WatchProgressRecord(
            progressKey: episodeKey,
            contentId: seriesMeta.id,
            contentType: seriesMeta.type,
            videoId: "\(seriesMeta.id):1:1",
            season: 1,
            episode: 1,
            position: 300,
            duration: 1000,
            lastWatchedAt: episodeWatchedAt.addingTimeInterval(-60),
            isPendingPush: false
        )
        _ = WatchProgressLedger.upsert(oldEpisodeRecord)
        XCTAssertFalse(WatchProgressLedger.continueWatchingCandidates().contains { $0.contentId == seriesMeta.id })

        // 2. Progress recorded AFTER the watched mark (re-watch) MUST be offered as a candidate
        let newMovieRecord = WatchProgressRecord(
            progressKey: movieKey,
            contentId: movieMeta.id,
            contentType: movieMeta.type,
            videoId: movieMeta.id,
            season: nil,
            episode: nil,
            position: 300,
            duration: 1000,
            lastWatchedAt: movieWatchedAt.addingTimeInterval(60),
            isPendingPush: false
        )
        _ = WatchProgressLedger.upsert(newMovieRecord)
        XCTAssertTrue(WatchProgressLedger.continueWatchingCandidates().contains { $0.contentId == movieMeta.id })

        let newEpisodeRecord = WatchProgressRecord(
            progressKey: episodeKey,
            contentId: seriesMeta.id,
            contentType: seriesMeta.type,
            videoId: "\(seriesMeta.id):1:1",
            season: 1,
            episode: 1,
            position: 300,
            duration: 1000,
            lastWatchedAt: episodeWatchedAt.addingTimeInterval(60),
            isPendingPush: false
        )
        _ = WatchProgressLedger.upsert(newEpisodeRecord)
        XCTAssertTrue(WatchProgressLedger.continueWatchingCandidates().contains { $0.contentId == seriesMeta.id })
    }

    // MARK: - Issue #138 Autoplay and Unmark Regressions

    func testUnmarkingEpisodeRetiresCompletedLedgerRowsAndPreservesPartialResume() {
        let seriesMeta = NuvioMeta(
            id: "tt9999001",
            name: "Unmark Series",
            description: nil,
            posterUrl: nil,
            backgroundUrl: nil,
            logoUrl: nil,
            imdbId: "tt9999001",
            tmdbId: 401,
            type: "series",
            year: 2024,
            genres: nil,
            rating: nil,
            releaseInfo: nil,
            runtime: nil,
            cast: nil,
            director: nil,
            writer: nil,
            certification: nil,
            country: nil,
            released: nil,
            videos: [
                NuvioVideo(id: "tt9999001:1:1", title: "E1", season: 1, episode: 1),
                NuvioVideo(id: "tt9999001:1:2", title: "E2", season: 1, episode: 2),
                NuvioVideo(id: "tt9999001:1:3", title: "E3", season: 1, episode: 3)
            ]
        )

        let ep1Key = WatchProgressLedger.progressKey(contentId: seriesMeta.id, season: 1, episode: 1)
        let ep2Key = WatchProgressLedger.progressKey(contentId: seriesMeta.id, season: 1, episode: 2)

        defer {
            _ = WatchProgressLedger.remove(keys: [ep1Key, ep2Key])
            _ = WatchedStore.removeEpisode(meta: seriesMeta, season: 1, episode: 1)
            _ = WatchedStore.removeEpisode(meta: seriesMeta, season: 1, episode: 2)
        }

        // Ep 1 is completed (>= 90% progress)
        let ep1CompletedRecord = WatchProgressRecord(
            progressKey: ep1Key,
            contentId: seriesMeta.id,
            contentType: seriesMeta.type,
            videoId: "tt9999001:1:1",
            season: 1,
            episode: 1,
            position: 950,
            duration: 1000,
            lastWatchedAt: Date().addingTimeInterval(-100),
            isPendingPush: false
        )
        _ = WatchProgressLedger.upsert(ep1CompletedRecord)
        XCTAssertTrue(WatchProgressLedger.isComplete(ep1CompletedRecord))

        // Ep 2 is partial (< 90% progress)
        let ep2PartialRecord = WatchProgressRecord(
            progressKey: ep2Key,
            contentId: seriesMeta.id,
            contentType: seriesMeta.type,
            videoId: "tt9999001:1:2",
            season: 1,
            episode: 2,
            position: 300,
            duration: 1000,
            lastWatchedAt: Date().addingTimeInterval(-50),
            isPendingPush: false
        )
        _ = WatchProgressLedger.upsert(ep2PartialRecord)
        XCTAssertFalse(WatchProgressLedger.isComplete(ep2PartialRecord))

        // Mark Ep 1 watched in WatchedStore
        XCTAssertTrue(WatchedStore.markWatched(seriesMeta, season: 1, episode: 1))
        XCTAssertTrue(WatchedStore.containsEpisode(meta: seriesMeta, season: 1, episode: 1))

        // Ep 1 is a seed for Next Up
        let seedsBefore = WatchProgressLedger.upNextSeeds()
        XCTAssertTrue(seedsBefore.contains { $0.contentId == seriesMeta.id && $0.season == 1 && $0.episode == 1 })

        // Now unmark Ep 1
        XCTAssertTrue(WatchedStore.removeEpisode(meta: seriesMeta, season: 1, episode: 1))
        XCTAssertFalse(WatchedStore.containsEpisode(meta: seriesMeta, season: 1, episode: 1))

        // Ep 1's completed record should be retired from the ledger
        let ep1RecordAfter = WatchProgressLedger.record(forKey: ep1Key)
        XCTAssertNil(ep1RecordAfter, "Completed ledger row should be retired when unmarking episode")

        // Ep 2's partial resume record must be preserved
        let ep2RecordAfter = WatchProgressLedger.record(forKey: ep2Key)
        XCTAssertNotNil(ep2RecordAfter, "Partial resume record must be preserved when unmarking episode")
        XCTAssertEqual(ep2RecordAfter?.position, 300)

        // Ep 1 should no longer be an upNextSeed
        let seedsAfter = WatchProgressLedger.upNextSeeds()
        XCTAssertFalse(seedsAfter.contains { $0.contentId == seriesMeta.id && $0.season == 1 && $0.episode == 1 }, "Unmarked episode must not remain an upNextSeed")
    }

    @MainActor
    func testAetherPlaybackControllerAwaitingEngineLoadReportsZeroClockAndNoFirstFrame() {
        guard let controller = AetherPlaybackController() else {
            return
        }
        defer { controller.destroyPlayer() }

        let request = PlaybackLoadRequest(
            videoURL: URL(string: "http://example.com/video.mp4")!,
            streamName: "Test Episode",
            streamDescription: "S1:E2"
        )

        controller.load(request, generation: 1)

        // Immediately after load() is initiated, controller must report loading with zero clock and no first frame
        XCTAssertTrue(controller.isPlayerLoading)
        XCTAssertFalse(controller.isPlayerEnded)
        XCTAssertFalse(controller.isAtEndOfFile)
        XCTAssertFalse(controller.hasFirstFrameReadyForDisplay)
        XCTAssertFalse(controller.isTransportPlaying)
        XCTAssertEqual(controller.positionMs, 0)
        XCTAssertEqual(controller.durationMs, 0)
        XCTAssertFalse(controller.hasCoherentTimeSample)

        // refreshPlaybackState() while awaiting load must also keep loading and zero clock
        controller.refreshPlaybackState()
        XCTAssertTrue(controller.isPlayerLoading)
        XCTAssertFalse(controller.isPlayerEnded)
        XCTAssertFalse(controller.hasFirstFrameReadyForDisplay)
        XCTAssertEqual(controller.positionMs, 0)
    }
}
