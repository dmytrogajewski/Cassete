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

[GtkTemplate (ui = "/space/rirusha/Cassette/ui/album-micro.ui")]
public class Cassette.AlbumMicro : Adw.Bin {
    [GtkChild]
    unowned CoverImage cover_image;
    [GtkChild]
    unowned Gtk.Label album_title;
    [GtkChild]
    unowned Gtk.Label album_artist;
    [GtkChild]
    unowned Gtk.Button root_button;
    [GtkChild]
    unowned Gtk.Box card_box;

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
                // Add hover/active highlight like other action cards (apply to card_box)
                var hover = new Gtk.EventControllerMotion ();
                hover.enter.connect (on_hover_enter);
                hover.leave.connect (on_hover_leave);
                root_button.add_controller (hover);

                var press = new Gtk.GestureClick ();
                press.pressed.connect (on_press_pressed);
                press.released.connect (on_press_released);
                press.stopped.connect (on_press_stopped);
                root_button.add_controller (press);

                set_values ();
            } else {
                sensitive = false;
            }
        }

        void on_hover_enter () {
            card_box.add_css_class ("action-card-hover");
        }

        void on_hover_leave () {
            card_box.remove_css_class ("action-card-hover");
        }

        void on_press_pressed () {
            card_box.add_css_class ("action-card-active");
        }

        void on_press_released () {
            card_box.remove_css_class ("action-card-active");
        }

        void on_press_stopped () {
            card_box.remove_css_class ("action-card-active");
        }

        [GtkCallback]
        void on_clicked () {
            if (collection_view != null && collection_view.root_view != null) {
                debug ("[TEST] AlbumMicro clicked: album_id=%s", album_info.id);
                collection_view.root_view.add_view (new AlbumView (album_info.id));
            }
        }

    void set_values () {
        if (album_info == null) {
            return;
        }

        album_title.label = album_info.title;
        debug ("[AlbumMicro] %s cover_uri=%s", album_info.title, album_info.cover_uri ?? "null");

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
