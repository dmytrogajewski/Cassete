/*
 * Copyright (C) 2023-2025 Vladimir Romanov <rirusha@altlinux.org>
 * 
 * This program is free software: you can redistribute it and/or modify
 * it under the terms of the GNU General Public License as published by
 * the Free Software Foundation, either version 3 of the License, or
 * (at your option) any later version.
 * 
 * SPDX-License-Identifier: GPL-3.0-or-later
 */

using Tape;
using Tape.YaMAPI;

namespace Cassette {
    [GtkTemplate (ui = "/space/rirusha/Cassette/ui/playlist-row.ui")]
    public class PlaylistRow : Gtk.Frame {
        [GtkChild]
        unowned CoverImage cover_image;
        [GtkChild]
        unowned Gtk.Label playlist_title;
        [GtkChild]
        unowned Gtk.Label track_num_label;
        [GtkChild]
        unowned Gtk.Button add_button;

        public YaMAPI.Playlist playlist_info { get; construct; }
        public YaMAPI.Track track_info { get; construct; }

        public PlaylistRow (YaMAPI.Playlist playlist_info, YaMAPI.Track track_info) {
            Object (playlist_info: playlist_info, track_info: track_info);
        }

        construct {
            playlist_title.label = playlist_info.title;
            if (playlist_info.track_count != 0) {
                set_track_count ();
            }

            add_button.clicked.connect (() => {
                add_button_clicked_async.begin ();
            });

            cover_image.init_content (playlist_info);
            cover_image.load_image.begin ();
        }

        async void add_button_clicked_async () {
            add_button.sensitive = false;

            YaMAPI.Playlist? new_playlist = null;

            // TODO: Uncomment when API method is available in libtape
            // var yam_helper = Application.tape_client.yam_helper;
            // new_playlist = yield yam_helper.add_track_to_playlist (
            //     track_info,
            //     playlist_info
            // );

            if (new_playlist != null) {
                playlist_info.track_count = new_playlist.track_count;

                if (new_playlist.revision != playlist_info.revision) {
                    success ();
                } else {
                    unsuccess ();
                }
            } else {
                unsuccess ();
            }
        }

        void set_track_count () {
            track_num_label.label = _("Track count: %s").printf (playlist_info.track_count.to_string ());
        }

        public void success () {
            add_button.icon_name = "emblem-ok-symbolic";

            set_track_count ();
        }

        public void unsuccess () {
            add_button.sensitive = true;
        }
    }
}

