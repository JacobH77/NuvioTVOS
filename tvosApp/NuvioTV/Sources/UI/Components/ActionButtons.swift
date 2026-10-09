//
//  ActionButtons.swift
//  NuvioTV
//
//  Action buttons for content details (play, library/watchlist, watched, share).
//  Mobile/preview helpers — production tvOS details uses TvDetailsActionRow.
//

import SwiftUI

struct ActionButtons: View {
    let onPlayClick: () -> Void
    let onWatchlistClick: () -> Void
    let onWatchedClick: () -> Void
    let onShareClick: () -> Void
    let isInWatchlist: Bool
    var isWatched: Bool = false

    var body: some View {
        HStack(spacing: 16) {
            Button(action: onPlayClick) {
                HStack(spacing: 8) {
                    Image(systemName: "play.fill")
                        .accessibilityHidden(true)
                    Text(L10n.string("details_watch_now", fallback: "Watch Now"))
                }
                .frame(height: 56)
                .padding(.horizontal, 24)
            }
            .buttonStyle(.borderedProminent)
            .accessibilityLabel(L10n.string("details_watch_now", fallback: "Watch Now"))
            .accessibilityHint(L10n.string("details_play_hint", fallback: "Starts playback"))

            Button(action: onWatchlistClick) {
                HStack(spacing: 8) {
                    Image(systemName: isInWatchlist ? "checkmark" : "plus")
                        .accessibilityHidden(true)
                    Text(isInWatchlist
                        ? L10n.string("watchlist_in", fallback: "In watchlist")
                        : L10n.string("watchlist_title", fallback: "Watchlist"))
                }
                .frame(height: 56)
                .padding(.horizontal, 20)
            }
            .buttonStyle(.bordered)
            .accessibilityLabel(isInWatchlist
                ? L10n.string("watchlist_in", fallback: "In watchlist")
                : L10n.string("watchlist_add", fallback: "Add to watchlist"))
            .accessibilityHint(isInWatchlist
                ? L10n.string("watchlist_remove_hint", fallback: "Removes this title from your watchlist")
                : L10n.string("watchlist_add_hint", fallback: "Adds this title to your watchlist"))

            Button(action: onWatchedClick) {
                Image(systemName: isWatched ? "eye.fill" : "eye.slash.fill")
            }
            .buttonStyle(.plain)
            .accessibilityLabel(isWatched
                ? L10n.string("details_watched", fallback: "Watched")
                : L10n.string("details_not_watched", fallback: "Not watched"))
            .accessibilityHint(isWatched
                ? L10n.string("details_mark_unwatched_hint", fallback: "Marks this title as unwatched")
                : L10n.string("details_mark_watched_hint", fallback: "Marks this title as watched"))

            Button(action: onShareClick) {
                Image(systemName: "square.and.arrow.up")
            }
            .buttonStyle(.plain)
            .accessibilityLabel(L10n.string("action_share", fallback: "Share"))
            .accessibilityHint(L10n.string("details_share_hint", fallback: "Shares this title"))
        }
    }
}

