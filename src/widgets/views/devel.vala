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

[GtkTemplate (ui = "/space/rirusha/Cassette/ui/devel-view.ui")]
public class Cassette.DevelView : BaseView {

    [GtkChild]
    unowned Gtk.ToggleButton hide_player_bar_button;
    [GtkChild]
    unowned Gtk.Button stations_view_button;
    [GtkChild]
    unowned Gtk.ScrolledWindow scrolled_window;

    construct {
        stations_view_button.clicked.connect (() => {
            if (root_view != null) {
                root_view.add_view (new StationsView ());
            }
        });

        // Wire to window when available
        hide_player_bar_button.toggled.connect (() => {
            if (root_view != null && root_view.window != null) {
                var window = root_view.window;
                if (hide_player_bar_button.active) {
                    window.hide_player_bar ();
                } else {
                    window.show_player_bar ();
                }
            }
        });

        scrolled_window.vadjustment.value_changed.connect (() => {
            scrolled_window.vadjustment.value = 0.0;
        });
    }

    void set_values () {
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

