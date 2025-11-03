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

[GtkTemplate (ui = "/space/rirusha/Cassette/ui/playlist-create-button.ui")]
public class Cassette.PlaylistCreateButton : Adw.Bin {
    [GtkChild]
    unowned Gtk.Button real_button;

    public PlaylistCreateButton () {
        Object ();
    }

    construct {
        real_button.clicked.connect (create_playlist_button_clicked_async);
        var app = (Application?) GLib.Application.get_default () as Application;
        if (app != null) {
            app.application_state_changed.connect (application_state_changed);
            application_state_changed (app.application_state, app.application_state);
        }
    }

    void application_state_changed (ApplicationState new_state, ApplicationState old_state) {
        switch (new_state) {
            case ApplicationState.ONLINE:
                sensitive = true;
                break;

            case ApplicationState.OFFLINE:
                sensitive = false;
                break;

            default:
                break;
        }
    }

    async void create_playlist_button_clicked_async () {
        sensitive = false;

        try {
            var yam_helper = Application.tape_client.yam_helper;
            var new_playlist = yield yam_helper.create_playlist ();
            if (new_playlist != null) {
                var app = (Application?) GLib.Application.get_default ();
                var window = app?.active_window as Window;
                window?.show_message (_("Playlist '%s' created").printf (new_playlist.title));
            }
        } catch (Error e) {
            warning ("Failed to create playlist: %s", e.message);
            var app = (Application?) GLib.Application.get_default ();
            var window = app?.active_window as Window;
            window?.show_message (_("Failed to create playlist: %s").printf (e.message));
        }
        
        sensitive = true;
    }
}

