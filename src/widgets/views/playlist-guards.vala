/*
 * SPDX-License-Identifier: GPL-3.0-or-later
 */

using Tape.YaMAPI;

namespace Cassette {
    internal class PlaylistGuards : Object {
        internal static Playlist? ensure_playlist_info (HasTracks? info) {
            if (info == null) {
                warning ("PlaylistView encountered null playlist info");
                return null;
            }

            var playlist_info = info as Playlist;

            if (playlist_info == null) {
                warning ("PlaylistView received unexpected HasTracks type: %s", info.get_type ().name ());
                return null;
            }

            return playlist_info;
        }
    }
}

