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
using GLib;

[GtkTemplate (ui = "/space/rirusha/Cassette/ui/playlist-micro.ui")]
public class Cassette.PlaylistMicro : Adw.Bin {
    [GtkChild]
    unowned CoverImage cover_image;
    [GtkChild]
    unowned Gtk.Label playlist_title;
    [GtkChild (name = "root_button")]
    unowned Gtk.Button root_button;
    [GtkChild]
    unowned SaveStack save_stack;

    public BaseView? playlists_view { get; set; }
    public YaMAPI.Playlist? short_playlist_info { get; construct; default = null; }

    public PlaylistMicro (BaseView? playlists_view, YaMAPI.Playlist? playlist_info) {
        Object (playlists_view: playlists_view, short_playlist_info: playlist_info);
    }

    public PlaylistMicro.empty () {
        Object ();
    }

        construct {
            if (short_playlist_info != null) {
                var yam_helper = Application.tape_client.yam_helper;

                if (short_playlist_info.uid == yam_helper.me.oid) {
                    yam_helper.playlist_start_delete.connect (on_playlist_start_delete);

                    yam_helper.playlist_stop_delete.connect (on_playlist_stop_delete);
                }

                yam_helper.playlist_changed.connect (on_playlist_changed);

                var motion_controller = new Gtk.EventControllerMotion ();
                root_button.add_controller (motion_controller);

                set_values ();

            } else {
                sensitive = false;
            }
        }

        [GtkCallback]
        void on_clicked () {
            if (playlists_view != null && playlists_view.root_view != null) {
                debug ("[TEST] PlaylistMicro clicked: uid=%s kind=%s",
                       short_playlist_info.uid ?? "<null>",
                       short_playlist_info.kind ?? "<null>");
                playlists_view.root_view.add_view (new PlaylistView (
                    short_playlist_info.uid,
                    short_playlist_info.kind
                ));
            }
        }

        void on_playlist_start_delete (string kind) {
            if (short_playlist_info.kind == kind) {
                sensitive = false;
            }
        }

        void on_playlist_stop_delete (string kind) {
            if (short_playlist_info.kind == kind) {
                sensitive = true;
            }
        }

        void on_playlist_changed (YaMAPI.Playlist new_playlist) {
            if (new_playlist.oid == short_playlist_info.oid) {
                short_playlist_info.cover = new_playlist.cover;
                short_playlist_info.title = new_playlist.title;

                set_values ();
            }
        }

    void set_values () {
        if (short_playlist_info == null) {
            return;
        }

        var yam_helper = Application.tape_client.yam_helper;

        if (short_playlist_info.owner != null) {
            if (short_playlist_info.owner.uid != yam_helper.me.oid) {
                root_button.tooltip_text = _("Owner: %s").printf (short_playlist_info.owner.get_user_name ());
            }
        }

        if (short_playlist_info.uid == null) {
            var me = yam_helper.me;
            if (me.oid != null) {
                short_playlist_info.uid = me.oid;
            }
        }
        if (short_playlist_info.uid != null) {
            save_stack.init_content (short_playlist_info.oid);
        }

        playlist_title.label = short_playlist_info.title;

        cover_image.init_content (short_playlist_info);
        cover_image.load_image.begin ();
    }
}
