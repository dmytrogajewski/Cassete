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
            map.connect (() => {
                foreach (var row in rows) {
                    remove (row);
                }
                rows.clear ();

                //
                // var app = (Application?) GLib.Application.get_default ();
                // var window = app?.active_window as Window;
                // if (window != null && window.page_root.custom_pages != null) {
                //     foreach (var page_info in window.page_root.custom_pages) {
                //         var page_pref = new CustomPagePreferences (page_info);
                //         page_pref.deleted.connect ((sender) => {
                //             rows.remove (sender);
                //             remove (sender);

                //             check_rows ();
                //         });

                //         rows.add (page_pref);
                //         add (page_pref);
                //     }
                // }

                check_rows ();
            });
        }

        void check_rows () {
            if (rows.size == 0) {
                visible = false;
            } else {
                visible = true;
            }
        }
    }
}

