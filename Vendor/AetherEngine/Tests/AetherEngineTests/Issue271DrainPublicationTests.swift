import Foundation
import CoreGraphics
import Testing
import AetherLibavcodec
import AetherLibavutil
@testable import AetherEngine

/// #271: `$subtitleCues` published once per DECODED PACKET, each publication carrying the whole
/// cumulative array. `applyEventMutations` takes the channel's cue array inout, and `@Published`
/// exposes get/set with no `_modify`, so every event copy-on-wrote the array and republished it.
/// On a typeset ASS track (5,852 retained cues, ~52 packets per 500 ms tick) the reporter measured
/// 104 publications and 608,608 cue visits per second in one consumer, with zero new cues found:
/// a cumulative snapshot does not say which elements are new, so no host can skip the walk.
///
/// Three things are asserted here, all of them decisions the drain tick makes:
///
/// - the batch is bounded per tick and the bound falls on a PTS boundary (`batchEnd`),
/// - a tick that ran long is not mistaken for a seek by the next one (`drainPlan`),
/// - the insert reports whether it changed anything and finds same-start cues without walking the
///   whole retained array.
struct Issue271DrainPublicationTests {

    private func textCue(id: Int, start: Double, end: Double, _ s: String) -> SubtitleCue {
        SubtitleCue(id: id, startTime: start, endTime: end, body: .text(s))
    }
    private func img(width: Int = 1) -> SubtitleCue.Body {
        let ctx = CGContext(data: nil, width: width, height: 1, bitsPerComponent: 8,
                            bytesPerRow: 4 * width, space: CGColorSpaceCreateDeviceRGB(),
                            bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue)!
        return .image(SubtitleImage(cgImage: ctx.makeImage()!, position: .zero))
    }

    // MARK: - Batch bound on a PTS boundary

    @Test("a window at or under the cap decodes whole")
    func batchUnderCapIsWhole() {
        let pts: [Double] = [1, 2, 3, 4]
        #expect(SubtitleOverlayDrainer.batchEnd(count: 4, cap: 8) { pts[$0] } == 4)
        #expect(SubtitleOverlayDrainer.batchEnd(count: 4, cap: 4) { pts[$0] } == 4)
        #expect(SubtitleOverlayDrainer.batchEnd(count: 0, cap: 4) { pts[$0] } == 0)
    }

    @Test("a cap landing between two timestamps cuts there")
    func capOnPTSBoundaryCutsExactly() {
        let pts: [Double] = [1, 2, 3, 4, 5, 6]
        #expect(SubtitleOverlayDrainer.batchEnd(count: 6, cap: 3) { pts[$0] } == 3)
    }

    /// The load-bearing case. The cursor is a bare PTS advanced by `lastDecodedPts.nextUp`, so the
    /// next tick asks the store for packets AFTER the last decoded timestamp. A cut inside a
    /// same-PTS run would therefore skip its remainder for good, and a dense typeset track puts
    /// hundreds of distinct payloads on one timestamp (the reporter measured 303 on the densest).
    @Test("a cap landing inside a same-PTS run extends to the end of that run")
    func capExtendsThroughSamePTSRun() {
        let pts: [Double] = [1, 2, 2, 2, 2, 5, 6]
        #expect(SubtitleOverlayDrainer.batchEnd(count: 7, cap: 2) { pts[$0] } == 5)
        #expect(SubtitleOverlayDrainer.batchEnd(count: 7, cap: 3) { pts[$0] } == 5)
        #expect(SubtitleOverlayDrainer.batchEnd(count: 7, cap: 5) { pts[$0] } == 5)
    }

    @Test("a single run longer than the cap is decoded whole rather than split")
    func oversizedRunIsNotSplit() {
        let pts = [Double](repeating: 107.680, count: 303)
        #expect(SubtitleOverlayDrainer.batchEnd(count: 303, cap: 48) { pts[$0] } == 303)
    }

    @Test("a non-positive cap disables bounding")
    func zeroCapIsUnbounded() {
        let pts: [Double] = [1, 2, 3]
        #expect(SubtitleOverlayDrainer.batchEnd(count: 3, cap: 0) { pts[$0] } == 3)
    }

    @Test("ASS rechecks its cursor PTS and admits a later packet there once")
    func lateSamePTSPacketIsDrainedOnNextTick() {
        let store = SubtitlePacketStore()
        store.append(streamIndex: 3, ptsSeconds: 30, durationSeconds: 0, payload: Data("A".utf8))
        let firstSnapshot = store.entries(streamIndex: 3, from: 30, through: 60)
        #expect(firstSnapshot.map { String(decoding: $0.payload, as: UTF8.self) } == ["A"])
        guard let firstSequence = SubtitleOverlayDrainer.maxSequence(at: 30, in: firstSnapshot) else {
            Issue.record("expected the first packet at 30 s"); return
        }
        let cursor = SubtitleDrainCursor(lastDecodedPts: 30, lastDecodedSequence: firstSequence,
                                         lastPlayhead: 0)

        // The default plan remains exclusive for bitmap and other subtitle codecs.
        let bitmapPlan = SubtitleOverlayDrainer.drainPlan(
            cursor: cursor, playhead: 0, lead: 60, backscan: 15, jumpThreshold: 2.5)
        guard case .decode(let bitmapFrom, _) = bitmapPlan else {
            Issue.record("expected a steady bitmap decode, got \(bitmapPlan)"); return
        }
        #expect(bitmapFrom == 30.nextUp)

        store.append(streamIndex: 3, ptsSeconds: 30, durationSeconds: 0, payload: Data("B".utf8))
        let assPlan = SubtitleOverlayDrainer.drainPlan(
            cursor: cursor, playhead: 0, lead: 60, backscan: 15, jumpThreshold: 2.5,
            includeCursorPTS: true)
        guard case .decode(let from, let through) = assPlan else {
            Issue.record("expected an ASS steady decode, got \(assPlan)"); return
        }
        #expect(from == 30)

        let snapshot = store.entries(streamIndex: 3, from: from, through: through)
        let pending = SubtitleOverlayDrainer.excludingDecodedCursorPackets(snapshot, cursor: cursor)
        #expect(pending.map { String(decoding: $0.payload, as: UTF8.self) } == ["B"])
        #expect(SubtitleOverlayDrainer.harvestGapCut(
            count: pending.count,
            ptsAt: { pending[$0].ptsSeconds },
            sequenceAt: { pending[$0].sequence },
            resumeFrom: (cursor.lastDecodedPts, cursor.lastDecodedSequence),
            notBefore: 0) == nil)
        guard let nextSequence = SubtitleOverlayDrainer.maxSequence(at: 30, in: pending) else {
            Issue.record("expected the late packet at 30 s to advance the cursor"); return
        }
        let advancedCursor = SubtitleDrainCursor(lastDecodedPts: 30, lastDecodedSequence: nextSequence,
                                                 lastPlayhead: 0)

        let thirdPlan = SubtitleOverlayDrainer.drainPlan(
            cursor: advancedCursor, playhead: 0, lead: 60, backscan: 15, jumpThreshold: 2.5,
            includeCursorPTS: true)
        guard case .decode(let thirdFrom, let thirdThrough) = thirdPlan else {
            Issue.record("expected a third steady scan, got \(thirdPlan)"); return
        }
        let thirdSnapshot = store.entries(streamIndex: 3, from: thirdFrom, through: thirdThrough)
        #expect(SubtitleOverlayDrainer.excludingDecodedCursorPackets(thirdSnapshot,
                                                                      cursor: advancedCursor).isEmpty)
    }

    @Test("a refreshed earlier packet carries the PTS run's maximum sequence and dedupes on replay")
    func refreshedPacketKeepsBoundarySequenceAndDoesNotRepublish() {
        let store = SubtitlePacketStore()
        let packetA = Data("A".utf8)
        store.append(streamIndex: 3, ptsSeconds: 30, durationSeconds: 0, payload: packetA)
        store.append(streamIndex: 3, ptsSeconds: 30, durationSeconds: 0, payload: Data("B".utf8))
        let beforeRefresh = store.entries(streamIndex: 3, from: 30, through: 30)
        guard let oldMaximum = SubtitleOverlayDrainer.maxSequence(at: 30, in: beforeRefresh) else {
            Issue.record("expected a stored same-PTS run"); return
        }
        let cursor = SubtitleDrainCursor(lastDecodedPts: 30, lastDecodedSequence: oldMaximum,
                                         lastPlayhead: 0)

        store.append(streamIndex: 3, ptsSeconds: 30, durationSeconds: 0, payload: packetA)
        let refreshed = store.entries(streamIndex: 3, from: 30, through: 30)
        #expect(refreshed.map(\.sequence) == refreshed.map(\.sequence).sorted(by: >))
        let replay = SubtitleOverlayDrainer.excludingDecodedCursorPackets(refreshed, cursor: cursor)
        #expect(replay.count == 1)
        #expect(replay[0].payload == packetA)
        #expect(SubtitleOverlayDrainer.maxSequence(at: 30, in: refreshed) == replay[0].sequence)

        var cues: [SubtitleCue] = []
        var nextID = 0
        #expect(AetherEngine.insertCueSorted(textCue(id: 0, start: 30, end: 40, "line"),
                                             into: &cues, nextID: &nextID))
        #expect(!AetherEngine.insertCueSorted(textCue(id: 0, start: 30, end: 40, "line"),
                                              into: &cues, nextID: &nextID))
        #expect(cues.count == 1)
        #expect(nextID == 1)
    }

    @MainActor
    @Test("the prepared ASS snapshot admits a same-PTS append before the next finish")
    func preparedASSDrainAdmitsLateSamePTSPacket() throws {
        let data = try #require(Data(base64Encoded:
            Issue587PreserveASSMarkupCodecGateTests.base64.joined()))
        let demuxer = Demuxer()
        try demuxer.open(reader: DataIOReader(data: data), formatHint: "matroska")
        defer { demuxer.close() }
        let streamIndex = Issue587PreserveASSMarkupCodecGateTests.assStreamIndex
        let stream = try #require(demuxer.stream(at: streamIndex))

        let store = SubtitlePacketStore()
        let packetA = Data("0,0,Default,,0,0,0,,first".utf8)
        let packetB = Data("1,0,Default,,0,0,0,,late".utf8)
        store.append(streamIndex: streamIndex, ptsSeconds: 30, durationSeconds: 10, payload: packetA)

        let engine = try AetherEngine()
        engine.loadedURL = URL(string: "https://s/movie.mkv")!
        engine.softwareSubtitlePacketStore = store
        engine.isSubtitleActive = true
        engine.subtitleTracks = [TrackInfo(id: Int(streamIndex), name: "ASS", codec: "ass",
                                           language: nil, isDefault: false)]
        engine.subtitleDrainTargets[.primary] = streamIndex
        engine.subtitleDrainDecoderFactoryForTesting = { index in
            guard index == streamIndex else { return nil }
            return EmbeddedSubtitleDecoder(stream: stream, sourceVideoWidth: 16,
                                           sourceVideoHeight: 16, preserveASSMarkup: true)
        }
        engine.clock.sourceTime = 0

        // The drain owns this immutable snapshot after prepare. Appending B now reproduces a packet
        // arriving while the first tick is decoding A.
        let first = try #require(engine.prepareSubtitleDrainTick())
        #expect(first.channels.count == 1)
        #expect(first.channels[0].entries.map(\.payload) == [packetA])
        store.append(streamIndex: streamIndex, ptsSeconds: 30, durationSeconds: 10, payload: packetB)
        engine.finishSubtitleDrainTick(first, events: first.decodeHandoff.decode())
        #expect(engine.subtitleCues.count == 1)

        let second = try #require(engine.prepareSubtitleDrainTick())
        #expect(second.channels[0].entries.map(\.payload) == [packetB])
        engine.finishSubtitleDrainTick(second, events: second.decodeHandoff.decode())
        #expect(engine.subtitleCues.count == 2)
        let texts = engine.subtitleCues.compactMap { cue -> String? in
            guard case .text(let text) = cue.body else { return nil }
            return text
        }
        #expect(texts.contains { $0.contains("first") })
        #expect(texts.contains { $0.contains("late") })

        let third = try #require(engine.prepareSubtitleDrainTick())
        #expect(third.channels[0].entries.isEmpty)
        #expect(third.decodeHandoff.isEmpty)
        engine.finishSubtitleDrainTick(third, events: third.decodeHandoff.decode())
        #expect(engine.subtitleCues.count == 2)

        // The store refreshes A in place. Its new sequence exceeds B's, although A remains first
        // in array order; the cursor must use the run maximum so B does not re-enter the next scan.
        store.append(streamIndex: streamIndex, ptsSeconds: 30, durationSeconds: 10, payload: packetA)
        let refreshed = try #require(engine.prepareSubtitleDrainTick())
        #expect(refreshed.channels[0].entries.map(\.payload) == [packetA])
        engine.finishSubtitleDrainTick(refreshed, events: refreshed.decodeHandoff.decode())
        #expect(engine.subtitleDrainCursors[.primary]?.lastDecodedSequence == 3)
        #expect(engine.subtitleCues.count == 2)

        let settled = try #require(engine.prepareSubtitleDrainTick())
        #expect(settled.channels[0].entries.isEmpty)
    }

    // MARK: - A slow tick is not a seek

    /// `drainPlan` compares the live playhead against the playhead captured at the PREVIOUS tick's
    /// start, so a tick lasting longer than the 2.5 s jump threshold made the next one see a
    /// discontinuity and reset onto a fresh, disjoint window: a positive feedback loop, since the
    /// reset window is the expensive one.
    @Test("forward drift within the tick's own duration is not a seek")
    func slowTickIsNotASeek() {
        let cursor = SubtitleDrainCursor(lastDecodedPts: 150, lastPlayhead: 100)
        let plan = SubtitleOverlayDrainer.drainPlan(cursor: cursor, playhead: 104,
                                                    lead: 60, backscan: 15, jumpThreshold: 2.5,
                                                    elapsedSinceLastPlan: 4.0)
        guard case .decode = plan else {
            Issue.record("expected decode, got \(plan)"); return
        }
    }

    @Test("a real forward seek during a slow tick still resets")
    func realSeekDuringSlowTickStillResets() {
        let cursor = SubtitleDrainCursor(lastDecodedPts: 150, lastPlayhead: 100)
        let plan = SubtitleOverlayDrainer.drainPlan(cursor: cursor, playhead: 400,
                                                    lead: 60, backscan: 15, jumpThreshold: 2.5,
                                                    elapsedSinceLastPlan: 4.0)
        guard case .resetAndDecode(let from, _) = plan else {
            Issue.record("expected resetAndDecode, got \(plan)"); return
        }
        #expect(from == 385)
    }

    /// Playback never moves the playhead backwards, so elapsed wall time explains nothing about a
    /// backward delta and must not forgive one.
    @Test("a backward jump is a seek at any tick duration")
    func backwardJumpIsNeverForgiven() {
        let cursor = SubtitleDrainCursor(lastDecodedPts: 150, lastPlayhead: 100)
        let plan = SubtitleOverlayDrainer.drainPlan(cursor: cursor, playhead: 96,
                                                    lead: 60, backscan: 15, jumpThreshold: 2.5,
                                                    elapsedSinceLastPlan: 30)
        guard case .resetAndDecode(let from, _) = plan else {
            Issue.record("expected resetAndDecode, got \(plan)"); return
        }
        #expect(from == 81)
    }

    @Test("elapsed defaults to zero, so the threshold alone still governs a fast tick")
    func fastTickKeepsThresholdOnly() {
        let cursor = SubtitleDrainCursor(lastDecodedPts: 150, lastPlayhead: 100)
        let plan = SubtitleOverlayDrainer.drainPlan(cursor: cursor, playhead: 104,
                                                    lead: 60, backscan: 15, jumpThreshold: 2.5)
        guard case .resetAndDecode = plan else {
            Issue.record("expected resetAndDecode, got \(plan)"); return
        }
    }

    // MARK: - The insert reports change, and finds same-start cues without a full walk

    @Test("a re-decoded text cue reports no change and consumes no id")
    func dedupedInsertReportsNoChange() {
        var cues: [SubtitleCue] = []
        var nextID = 0
        #expect(AetherEngine.insertCueSorted(textCue(id: 0, start: 100, end: 110, "line"),
                                             into: &cues, nextID: &nextID))
        #expect(!AetherEngine.insertCueSorted(textCue(id: 0, start: 100, end: 110, "line"),
                                              into: &cues, nextID: &nextID))
        #expect(cues.count == 1)
        #expect(nextID == 1)
    }

    @Test("a same-start image re-decode reports a change: it replaces the retained bitmap")
    func imageReplaceReportsChange() {
        var cues: [SubtitleCue] = []
        var nextID = 0
        #expect(AetherEngine.insertCueSorted(SubtitleCue(id: 0, startTime: 100, endTime: 110, body: img()),
                                             into: &cues, nextID: &nextID))
        #expect(AetherEngine.insertCueSorted(SubtitleCue(id: 0, startTime: 100, endTime: 118, body: img()),
                                             into: &cues, nextID: &nextID))
        #expect(cues.count == 1)
        #expect(cues[0].endTime == 118)
    }

    /// The dedupe key requires an exact start match, so the equal-start run is the only place a
    /// match can live and the binary-search lookup must find it wherever the run sits in a large
    /// sorted array. Same text at a DIFFERENT start is a genuine repeat and still inserts.
    @Test("dedupe over a large sorted store finds the buried same-start cue, and only that one")
    func dedupeFindsBuriedRunInLargeStore() {
        var cues: [SubtitleCue] = []
        var nextID = 0
        for i in 0..<2000 {
            AetherEngine.insertCueSorted(textCue(id: 0, start: Double(i), end: Double(i) + 0.5, "l\(i)"),
                                         into: &cues, nextID: &nextID)
        }
        #expect(cues.count == 2000)
        #expect(!AetherEngine.insertCueSorted(textCue(id: 0, start: 1337, end: 1337.5, "l1337"),
                                              into: &cues, nextID: &nextID))
        #expect(cues.count == 2000)
        // Same text, different start: a genuine repeat.
        #expect(AetherEngine.insertCueSorted(textCue(id: 0, start: 4000, end: 4000.5, "l1337"),
                                             into: &cues, nextID: &nextID))
        #expect(cues.count == 2001)
        // Simultaneous speaker at a start already present: distinct text, both kept.
        #expect(AetherEngine.insertCueSorted(textCue(id: 0, start: 1337, end: 1337.5, "other"),
                                             into: &cues, nextID: &nextID))
        #expect(cues.count == 2002)
        #expect(cues.map(\.startTime) == cues.map(\.startTime).sorted())
    }

    @Test("insertion order among cues sharing a start is unchanged by the binary-search lookup")
    func sameStartInsertPositionUnchanged() {
        var cues: [SubtitleCue] = []
        var nextID = 0
        AetherEngine.insertCueSorted(textCue(id: 0, start: 100, end: 110, "first"), into: &cues, nextID: &nextID)
        AetherEngine.insertCueSorted(textCue(id: 0, start: 100, end: 110, "second"), into: &cues, nextID: &nextID)
        AetherEngine.insertCueSorted(textCue(id: 0, start: 100, end: 110, "third"), into: &cues, nextID: &nextID)
        #expect(cues.map(\.text) == ["third", "second", "first"])
    }

    // MARK: - Trim and prune report change

    @Test("a trim covering no open window reports no change")
    func trimReportsNoChange() {
        var cues = [textCue(id: 0, start: 10, end: 12, "done")]
        #expect(!AetherEngine.trimTextCues(&cues, at: 50))
        #expect(AetherEngine.trimTextCues(&cues, at: 11))
        #expect(cues[0].endTime == 11)
    }

    @Test("a prune that drops nothing reports no change")
    func pruneReportsNoChange() {
        var cues = [textCue(id: 0, start: 100, end: 110, "a"),
                    textCue(id: 1, start: 500, end: 510, "b")]
        #expect(!AetherEngine.pruneCues(&cues, before: 50))
        // A non-positive cutoff is "no retention pressure yet", not "drop everything".
        #expect(!AetherEngine.pruneCues(&cues, before: -300))
        #expect(cues.count == 2)
        #expect(AetherEngine.pruneCues(&cues, before: 200))
        #expect(cues.count == 1)
    }
}
