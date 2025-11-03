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
        // TODO: Connect to application state changes when available
    }

    async void create_playlist_button_clicked_async () {
        sensitive = false;

        // TODO: Implement when create_playlist is available in API
        // yield Application.tape_client.yam_helper.create_playlist ();
        
        sensitive = true;
    }
}

