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

[GtkTemplate (ui = "/space/rirusha/Cassette/ui/main-view.ui")]
public class Cassette.MainView : BaseView {

    [GtkChild]
    unowned Adw.StatusPage status_page;
    [GtkChild]
    unowned Gtk.Button stations_view_button;
    [GtkChild]
    unowned Gtk.Button playlists_view_button;
    [GtkChild]
    unowned Gtk.Button liked_tracks_button;

    public MainView () {
        Object ();
    }

    construct {
        status_page.icon_name = "%s-symbolic".printf (Config.APP_ID_RELEVANT);

            stations_view_button.clicked.connect (() => {
                if (root_view != null) {
                    root_view.add_view (new StationsView ());
                }
            });

            playlists_view_button.clicked.connect (() => {
                if (root_view != null) {
                    root_view.add_view (new PlaylistsView ());
                }
            });

            liked_tracks_button.clicked.connect (() => {
                if (root_view != null) {
                    // Navigate to the liked playlist by opening PlaylistsView
                    // The liked playlist micro is in PlaylistsView
                    root_view.add_view (new PlaylistsView ());
                }
            });
    }

    void set_values () {
        set_focus_child (null);

        show_ready ();
    }

    public async override void first_show () {
        set_values ();
    }

    public async override bool try_load_from_cache () {
        return true;
    }

    public async override int try_load_from_web () {
        return -1;
    }

    public async override void refresh () {

    }
}

