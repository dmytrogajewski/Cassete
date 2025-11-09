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
using GLib;

namespace Cassette {
    [GtkTemplate (ui = "/space/rirusha/Cassette/ui/cache-deletion-preferences.ui")]
    public class CacheDeletionPreferences : Adw.PreferencesRow {
        [GtkChild]
        unowned Gtk.Stack temp_stack;
        [GtkChild]
        unowned Gtk.Spinner temp_spinner;
        [GtkChild]
        unowned Gtk.Label temp_size_label;
        [GtkChild]
        unowned Gtk.Label temp_type_label;
        [GtkChild]
        unowned Gtk.Stack perm_stack;
        [GtkChild]
        unowned Gtk.Spinner perm_spinner;
        [GtkChild]
        unowned Gtk.Label perm_size_label;
        [GtkChild]
        unowned Gtk.Label perm_type_label;

        public Adw.PreferencesDialog pref_win { get; set; }
        Adw.Window? loading_win = null;

        construct {
            map.connect (update_data);
        }

        void update_data () {
            temp_spinner.start ();
            var storager = Application.tape_client.cachier.storager;
            storager.get_temp_size.begin (on_get_temp_size_complete);

            perm_spinner.start ();
            storager.get_perm_size.begin (on_get_perm_size_complete);
            debug ("[TEST] CacheDeletionPreferences update_data triggered");
        }

        void ask_about_deletion (bool is_tmp) {
            var dialog = new Adw.AlertDialog (
                is_tmp ? _("Delete cache files?") :
                    _("Move saved files?"),
                is_tmp ? _("All cache will be deleted. This doesn't affect on saved playlists or albums") :
                    _("All saved playlists and albums will be moved to cache files. This could take a while.")
            );

            // Translators: cancel of deleting playlist
            dialog.add_response ("cancel", _("Cancel"));
            dialog.add_response ("delete", _("Delete"));

            dialog.set_response_appearance ("delete", Adw.ResponseAppearance.DESTRUCTIVE);

            dialog.default_response = "cancel";
            dialog.close_response = "cancel";

            // Capture is_tmp via closure
            bool is_tmp_capture = is_tmp;
            dialog.response.connect ((dialog, response) => on_deletion_dialog_response (dialog, response, is_tmp_capture));

            dialog.present (pref_win);
            debug ("[TEST] CacheDeletionPreferences deletion dialog opened: is_tmp=%s", is_tmp.to_string ());
        }

        public void delete_files (bool is_tmp) {
            var box = new Gtk.Box (Gtk.Orientation.VERTICAL, 16) {
                margin_top = 16,
                margin_bottom = 16,
                margin_start = 16,
                margin_end = 16
            };

            var root = pref_win.get_root () as Gtk.Window;
            loading_win = new Adw.Window () {
                resizable = false,
                transient_for = root,
                modal = true,
                content = box
            };

            box.append (new LoadingSpinner ());

            var label = new Gtk.Label (is_tmp? _("Deleting…") : _("Moving…"));
            label.add_css_class ("title-1");
            box.append (label);

            loading_win.present ();

            if (is_tmp) {
                var storager = Application.tape_client.cachier.storager;
                storager.delete_cache_dir.begin (on_delete_cache_dir_complete);
                debug ("[TEST] CacheDeletionPreferences deleting temp cache");
            } else {
                // Move permanent data to cache (clear_user_data with keep_content=true)
                var storager = Application.tape_client.cachier.storager;
                storager.clear_user_data.begin (true, true, on_clear_user_data_complete);
                debug ("[TEST] CacheDeletionPreferences moving saved content to cache");
            }
        }

        [GtkCallback]
        void on_temp_delete_button_clicked () {
            ask_about_deletion (true);
            debug ("[TEST] CacheDeletionPreferences temp delete button clicked");
        }

        [GtkCallback]
        void on_perm_delete_button_clicked () {
            ask_about_deletion (false);
            debug ("[TEST] CacheDeletionPreferences perm delete button clicked");
        }

        void on_get_temp_size_complete (Object? obj, AsyncResult res) {
            var storager = Application.tape_client.cachier.storager;
            HumanitySize humanity_size = storager.get_temp_size.end (res);

            temp_size_label.label = humanity_size.size;
            temp_type_label.label = humanity_size.unit;

            temp_stack.visible_child_name = "ready";
            temp_spinner.stop ();
            debug ("[TEST] CacheDeletionPreferences temp size loaded: %s %s",
                   humanity_size.size,
                   humanity_size.unit);
        }

        void on_get_perm_size_complete (Object? obj, AsyncResult res) {
            var storager = Application.tape_client.cachier.storager;
            HumanitySize humanity_size = storager.get_perm_size.end (res);

            perm_size_label.label = humanity_size.size;
            perm_type_label.label = humanity_size.unit;

            perm_stack.visible_child_name = "ready";
            perm_spinner.stop ();
            debug ("[TEST] CacheDeletionPreferences perm size loaded: %s %s",
                   humanity_size.size,
                   humanity_size.unit);
        }

        void on_deletion_dialog_response (Adw.AlertDialog dialog, string response, bool is_tmp) {
            if (response == "delete") {
                delete_files (is_tmp);
                debug ("[TEST] CacheDeletionPreferences deletion confirmed: is_tmp=%s", is_tmp.to_string ());
            } else {
                debug ("[TEST] CacheDeletionPreferences deletion cancelled: is_tmp=%s", is_tmp.to_string ());
            }
        }

        void on_delete_cache_dir_complete (Object? obj, AsyncResult res) {
            var storager = Application.tape_client.cachier.storager;
            storager.delete_cache_dir.end (res);
            loading_win.close ();
            loading_win = null;
            update_data ();
            debug ("[TEST] CacheDeletionPreferences temp cache deleted");
        }

        void on_clear_user_data_complete (Object? obj, AsyncResult res) {
            var storager = Application.tape_client.cachier.storager;
            storager.clear_user_data.end (res);
            loading_win.close ();
            loading_win = null;
            update_data ();
            debug ("[TEST] CacheDeletionPreferences saved content moved");
        }
    }
}
