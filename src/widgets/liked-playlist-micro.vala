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

[GtkTemplate (ui = "/space/rirusha/Cassette/ui/liked-playlist-micro.ui")]
public class Cassette.LikedPlaylistMicro : Adw.Bin {
    [GtkChild]
    unowned CoverImage cover_image;
    [GtkChild]
    unowned Gtk.Label playlist_title;
    [GtkChild]
    unowned Gtk.Button self;
    [GtkChild]
    unowned SaveStack save_stack;

    public BaseView? collection_view { get; set; }
    public YaMAPI.LikedPlaylist? liked_playlist_info { get; construct; default = null; }

    public LikedPlaylistMicro (BaseView? collection_view, YaMAPI.LikedPlaylist? liked_playlist_info) {
        Object (collection_view: collection_view, liked_playlist_info: liked_playlist_info);
    }

    public LikedPlaylistMicro.empty () {
        Object ();
    }

    construct {
        if (liked_playlist_info != null) {
            self.clicked.connect (() => {
                if (collection_view != null && collection_view.root_view != null) {
                    // LikedPlaylist has a playlist property
                    if (liked_playlist_info.playlist != null) {
                        collection_view.root_view.add_view (new PlaylistView (
                            liked_playlist_info.playlist.uid,
                            liked_playlist_info.playlist.kind
                        ));
                    }
                }
            });

            var yam_helper = Application.tape_client.yam_helper;

            yam_helper.playlist_changed.connect ((new_playlist) => {
                if (liked_playlist_info.playlist != null && new_playlist.oid == liked_playlist_info.playlist.oid) {
                    liked_playlist_info.playlist.cover = new_playlist.cover;
                    liked_playlist_info.playlist.title = new_playlist.title;

                    set_values ();
                }
            });

            var motion_controller = new Gtk.EventControllerMotion ();
            add_controller (motion_controller);

            set_values ();
        } else {
            sensitive = false;
        }
    }

    void set_values () {
        if (liked_playlist_info == null || liked_playlist_info.playlist == null) {
            return;
        }

        playlist_title.label = liked_playlist_info.playlist.title;

        if (liked_playlist_info.playlist.oid != null) {
            save_stack.init_content (liked_playlist_info.playlist.oid);
        }

        cover_image.init_content (liked_playlist_info.playlist);
        cover_image.load_image.begin ();
    }
}

