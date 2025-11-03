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

[GtkTemplate (ui = "/space/rirusha/Cassette/ui/album-micro.ui")]
public class Cassette.AlbumMicro : Adw.Bin {
    [GtkChild]
    unowned CoverImage cover_image;
    [GtkChild]
    unowned Gtk.Label album_title;
    [GtkChild]
    unowned Gtk.Label album_artist;
    [GtkChild]
    unowned Gtk.Button self;

    public BaseView? collection_view { get; set; }
    public YaMAPI.Album? album_info { get; construct; default = null; }

    public AlbumMicro (BaseView? collection_view, YaMAPI.Album? album_info) {
        Object (collection_view: collection_view, album_info: album_info);
    }

    public AlbumMicro.empty () {
        Object ();
    }

    construct {
        if (album_info != null) {
            self.clicked.connect (() => {
                if (collection_view != null && collection_view.root_view != null) {
                    collection_view.root_view.add_view (new AlbumView (album_info.id));
                }
            });

            set_values ();
        } else {
            sensitive = false;
        }
    }

    void set_values () {
        if (album_info == null) {
            return;
        }

        album_title.label = album_info.title;

        if (album_info.artists.size > 0) {
            var artist_names = new Gee.ArrayList<string> ();
            foreach (var artist in album_info.artists) {
                artist_names.add (artist.name);
            }
            album_artist.label = string.joinv (", ", artist_names.to_array ());
        } else {
            album_artist.label = "";
        }

        cover_image.init_content (album_info);
        cover_image.load_image.begin ();
    }
}

