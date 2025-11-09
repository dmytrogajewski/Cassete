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
    public class PageInfo : Object {
        public string id { get; set; default = ""; }
        public string title { get; set; default = ""; }
        public string icon_name { get; set; default = ""; }
        public string view_type_name { get; set; default = ""; }
        public string?[] args { get; set; default = {}; }
    }

    [GtkTemplate (ui = "/space/rirusha/Cassette/ui/custom-page-preferences.ui")]
    public class CustomPagePreferences : Adw.PreferencesRow {
        [GtkChild]
        unowned Gtk.Entry page_title_entry;
        [GtkChild]
        unowned Gtk.Entry page_icon_name_entry;

        PageInfo page_info;

        public string page_id {
            get {
                return page_info.id;
            }
        }

        public string page_title {
            get {
                return page_info.title;
            }
        }

        public string page_icon_name {
            get {
                return page_info.icon_name;
            }
        }

        public string view_type_name {
            get {
                return page_info.view_type_name;
            }
        }

        public string?[] args {
            get {
                return page_info.args;
            }
        }

        public signal void deleted (CustomPagePreferences sender);
        public signal void updated (CustomPagePreferences sender, PageInfo info);

        public CustomPagePreferences (PageInfo page_info) {
            this.page_info = page_info;
        }

        construct {
            page_title_entry.text = page_title;
            page_icon_name_entry.text = page_icon_name;
        }

        [GtkCallback]
        void on_page_save_button_clicked () {
            string new_title = page_title_entry.text.strip ();
            string new_icon_name = page_icon_name_entry.text.strip ();

            if (new_title.length == 0) {
                show_feedback (_("Page title can't be empty"));
                page_title_entry.text = page_title;
                return;
            }

            bool changed = (new_title != page_title) || (new_icon_name != page_icon_name);

            if (!changed) {
                show_feedback (_("No changes to save"));
                return;
            }

            page_info.title = new_title;
            page_info.icon_name = new_icon_name;

            updated (this, page_info);
        }

        [GtkCallback]
        void on_page_remove_button_clicked () {
            deleted (this);
        }

        public PageInfo to_page_info () {
            return page_info;
        }

        void show_feedback (string message) {
            var app = (Application?) GLib.Application.get_default ();
            if (app == null) {
                debug ("[TEST] CustomPagePreferences feedback skipped: %s", message);
                return;
            }

            var window = app.active_window as Window;
            if (window != null) {
                window.show_message (message);
            } else {
                debug ("[TEST] CustomPagePreferences feedback: %s", message);
            }
        }
    }
}
