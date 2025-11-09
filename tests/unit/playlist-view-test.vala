/*
 * SPDX-License-Identifier: GPL-3.0-or-later
 */

using GLib;
using Tape.YaMAPI;

void add_playlist_view_guard_tests () {
    Test.add_func ("/ui/playlist/ensure_playlist_info/null_guard", () => {
        var result = Cassette.PlaylistGuards.ensure_playlist_info (null);
        assert_true (result == null);
    });

    Test.add_func ("/ui/playlist/ensure_playlist_info/type_guard", () => {
        var non_playlist = new TrackHeap ();
        var result = Cassette.PlaylistGuards.ensure_playlist_info (non_playlist);
        assert_true (result == null);
    });

    Test.add_func ("/ui/playlist/ensure_playlist_info/pass_through", () => {
        var playlist = new Playlist ();
        playlist.title = "Test playlist";

        var result = Cassette.PlaylistGuards.ensure_playlist_info (playlist);

        assert_true (result != null);
        assert_true (result == playlist);
    });
}

int main (string[] args) {
    Test.init (ref args);
    Log.set_always_fatal (LogLevelFlags.LEVEL_ERROR | LogLevelFlags.LEVEL_CRITICAL);

    add_playlist_view_guard_tests ();

    return Test.run ();
}

