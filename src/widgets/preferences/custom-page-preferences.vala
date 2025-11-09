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

namespace Cassette {
    //
    // For now, this is a placeholder that matches the old structure
    public struct PageInfo {
        public string id;
        public string title;
        public string icon_name;
        public string view_type_name;
        public string?[] args;
    }

    [GtkTemplate (ui = "/space/rirusha/Cassette/ui/custom-page-preferences.ui")]
    public class CustomPagePreferences : Adw.PreferencesRow {
        [GtkChild]
        unowned Gtk.Entry page_title_entry;
        [GtkChild]
        unowned Gtk.Entry page_icon_name_entry;

        public string page_id { get; construct; }
        public string page_title { get; construct; }
        public string page_icon_name { get; construct; }

        public signal void deleted (CustomPagePreferences sender);

        public CustomPagePreferences (PageInfo page_info) {
            Object (page_id: page_info.id, page_title: page_info.title, page_icon_name: page_info.icon_name);
        }

        construct {
            page_title_entry.text = page_title;
            page_icon_name_entry.text = page_icon_name;
        }

        [GtkCallback]
        void on_page_save_button_clicked () {
            // TODO: Implement page save functionality
            // if (page_title != page_title_entry.text || page_icon_name != page_icon_name_entry.text) {
            //     var app = (Application?) GLib.Application.get_default ();
            //     var window = app?.active_window as Window;
            //     if (window != null) {
            //         // window.page_root.update_page (page_id, page_title_entry.text, page_icon_name_entry.text);
            //     }
            // }
        }

        [GtkCallback]
        void on_page_remove_button_clicked () {
            deleted (this);
            // TODO: Implement page removal functionality
            // var app = (Application?) GLib.Application.get_default ();
            // var window = app?.active_window as Window;
            // if (window != null) {
            //     // window.page_root.remove_page (page_id);
            // }
        }
    }
}
