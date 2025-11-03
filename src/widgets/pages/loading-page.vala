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

namespace Cassette {

    public class LoadingPage : Adw.NavigationPage {

        private Gtk.Spinner _loading_widget = new Gtk.Spinner () { 
            spinning = true,
            height_request = 32,
            width_request = 32
        };

        public bool with_header_bar { get; construct set; }

        public LoadingPage (bool with_header_bar) {
            Object (with_header_bar: with_header_bar);
        }

        construct {
            title = _("Loading…");
            can_pop = false;

            if (with_header_bar) {
                var header_bar = new Adw.HeaderBar () {
                    show_back_button = false,
                    show_end_title_buttons = false
                };

                var toolbar_view = new Adw.ToolbarView ();
                toolbar_view.add_top_bar (header_bar);
                
                var center_box = new Gtk.Box (Gtk.Orientation.VERTICAL, 0) {
                    halign = Gtk.Align.CENTER,
                    valign = Gtk.Align.CENTER,
                    hexpand = true,
                    vexpand = true
                };
                center_box.append (_loading_widget);
                toolbar_view.content = center_box;

                child = toolbar_view;

            } else {
                var center_box = new Gtk.Box (Gtk.Orientation.VERTICAL, 0) {
                    halign = Gtk.Align.CENTER,
                    valign = Gtk.Align.CENTER,
                    hexpand = true,
                    vexpand = true
                };
                center_box.append (_loading_widget);
                child = center_box;
            }
        }
    }
}

