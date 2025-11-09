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
using Gee;

namespace Cassette {
    [GtkTemplate (ui = "/space/rirusha/Cassette/ui/custom-pages-preferences.ui")]
    public class CustomPagesPreferences : Adw.PreferencesGroup {

        ArrayList<CustomPagePreferences> rows = new ArrayList<CustomPagePreferences> ();

        construct {
            map.connect (on_map);
        }

        void on_map () {
            foreach (var row in rows) {
                remove (row);
            }
            rows.clear ();

            foreach (var page_info in CustomPagesStore.load ()) {
                add_page_row (page_info);
            }

            check_rows ();
        }

        void check_rows () {
            if (rows.size == 0) {
                visible = false;
            } else {
                visible = true;
            }
        }

        void add_page_row (PageInfo page_info) {
            var page_pref = new CustomPagePreferences (page_info);
            page_pref.deleted.connect (on_page_pref_deleted);
            page_pref.updated.connect (on_page_pref_updated);

            rows.add (page_pref);
            add (page_pref);
        }

        void on_page_pref_deleted (CustomPagePreferences sender) {
            if (CustomPagesStore.remove (sender.page_id)) {
                show_feedback (_("Custom page removed"));
            } else {
                show_feedback (_("Failed to remove custom page"));
            }

            rows.remove (sender);
            remove (sender);
            check_rows ();
        }

        void on_page_pref_updated (CustomPagePreferences sender, PageInfo info) {
            CustomPagesStore.upsert (info);
            show_feedback (_("Custom page updated"));
        }

        void show_feedback (string message) {
            var app = (Application?) GLib.Application.get_default ();
            var window = app?.active_window as Window;
            if (window != null) {
                window.show_message (message);
            } else {
                debug ("[TEST] CustomPagesPreferences feedback: %s", message);
            }
        }
    }
}
