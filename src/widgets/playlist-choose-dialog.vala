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
using Gee;

namespace Cassette {
    [GtkTemplate (ui = "/space/rirusha/Cassette/ui/playlist-choose-dialog.ui")]
    public class PlaylistChooseDialog : Adw.Dialog {
        [GtkChild]
        unowned Gtk.Box main_box;
        [GtkChild]
        unowned Gtk.Spinner spinner_loading;
        [GtkChild]
        unowned Gtk.Stack main_stack;

        public YaMAPI.Track target_track { get; construct; }

        public PlaylistChooseDialog (YaMAPI.Track target_track) {
            Object (target_track: target_track);
        }

        construct {
            main_stack.visible_child_name = "loading";
            spinner_loading.start ();

            load_playlists.begin ();

            if (Config.IS_DEVEL) {
                add_css_class ("devel");
            }
        }

        async void load_playlists () {
            Gee.ArrayList<YaMAPI.Playlist>? playlists_info = null;

            var yam_helper = Application.tape_client.yam_helper;
            try {
                playlists_info = yield yam_helper.get_playlist_list (null);
            } catch (Error e) {
                warning ("Failed to load playlists: %s", e.message);
            }

            set_values (playlists_info);
        }

        void set_values (Gee.ArrayList<YaMAPI.Playlist>? playlists_info) {
            if (playlists_info != null) {
                foreach (var playlist in playlists_info) {
                    main_box.append (new PlaylistRow (playlist, target_track));
                }

                spinner_loading.stop ();
                main_stack.set_visible_child_name ("done");
            } else {
                spinner_loading.stop ();
                main_stack.set_visible_child_name ("done");
            }
        }
    }
}

