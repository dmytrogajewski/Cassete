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
    [GtkTemplate (ui = "/space/rirusha/Cassette/ui/preferences-dialog.ui")]
    public class PreferencesDialog : Adw.PreferencesDialog {
        [GtkChild]
        unowned Adw.SwitchRow show_save_stack_switch;
        [GtkChild]
        unowned Adw.SwitchRow show_temp_save_stack_switch;
        [GtkChild]
        unowned Adw.SwitchRow child_visible_switch;
        [GtkChild]
        unowned Adw.SwitchRow explicit_visible_switch;
        [GtkChild]
        unowned Adw.SwitchRow show_replaced_mark_switch;
        [GtkChild]
        unowned Adw.SwitchRow available_visible_switch;
        [GtkChild]
        unowned Adw.SwitchRow add_tracks_to_start_switch;
        [GtkChild]
        unowned Adw.SwitchRow show_playing_track_notif_switch;
        [GtkChild]
        unowned Adw.SwitchRow show_main_switch;
        [GtkChild]
        unowned Adw.SwitchRow show_liked_switch;
        [GtkChild]
        unowned Adw.SwitchRow show_playlists_switch;
        [GtkChild]
        unowned Adw.SwitchRow can_cache_switch;
        [GtkChild]
        unowned CacheDeletionPreferences deletion_preferences;
        [GtkChild]
        unowned Adw.SwitchRow use_only_dialogs_switch;

        construct {
            deletion_preferences.pref_win = this;

            show_save_stack_switch.notify["active"].connect (on_show_save_stack_switch_changed);

            var tape_settings = Application.tape_client.settings;
            can_cache_switch.active = tape_settings.can_cache;

            can_cache_switch.notify["active"].connect (() => {
                if (!can_cache_switch.active) {
                    ask_about_deletion ();
                } else {
                    tape_settings.can_cache = true;
                }
            });

            Application.client_settings.bind (
                "add-tracks-to-start", add_tracks_to_start_switch, "active", GLib.SettingsBindFlags.DEFAULT
            );
            Application.app_settings.bind (
                "available-visible", available_visible_switch, "active", GLib.SettingsBindFlags.DEFAULT
            );
            Application.app_settings.bind (
                "show-playing-track-notif", show_playing_track_notif_switch, "active", GLib.SettingsBindFlags.DEFAULT
            );
            Application.app_settings.bind (
                "child-visible", child_visible_switch, "active", GLib.SettingsBindFlags.DEFAULT
            );
            Application.app_settings.bind (
                "explicit-visible", explicit_visible_switch, "active", GLib.SettingsBindFlags.DEFAULT
            );
            Application.app_settings.bind (
                "show-replaced-mark", show_replaced_mark_switch, "active", GLib.SettingsBindFlags.DEFAULT
            );
            Application.app_settings.bind (
                "show-save-stack", show_save_stack_switch, "active", GLib.SettingsBindFlags.DEFAULT
            );
            Application.app_settings.bind (
                "show-temp-save-mark", show_temp_save_stack_switch, "active", GLib.SettingsBindFlags.DEFAULT
            );
            // TODO: Uncomment when is_hq setting is available
            // Application.client_settings.bind (
            //     "is-hq", is_hq_switch, "active", GLib.SettingsBindFlags.DEFAULT
            // );
            // TODO: Uncomment when debug-mode setting is available
            // Application.client_settings.bind (
            //     "debug-mode", debug_mode_switch, "active", GLib.SettingsBindFlags.DEFAULT
            // );
            Application.app_settings.bind (
                "use-only-dialogs", use_only_dialogs_switch, "active", GLib.SettingsBindFlags.DEFAULT
            );

            Application.app_settings.bind (
                "show-main", show_main_switch, "active", GLib.SettingsBindFlags.DEFAULT
            );
            Application.app_settings.bind (
                "show-liked", show_liked_switch, "active", GLib.SettingsBindFlags.DEFAULT
            );
            Application.app_settings.bind (
                "show-playlists", show_playlists_switch, "active", GLib.SettingsBindFlags.DEFAULT
            );

            on_show_save_stack_switch_changed ();

            if (Config.IS_DEVEL) {
                add_css_class ("devel");
            }

            focus_widget = null;
        }

        void on_show_save_stack_switch_changed () {
            show_temp_save_stack_switch.sensitive = show_save_stack_switch.active;
        }

        void ask_about_deletion () {
            var dialog = new Adw.AlertDialog (
                _("Delete cache files?"),
                _("All cache will be deleted. This doesn't affect on saved playlists or albums")
            );

            // Translators: cancel of deleting playlist
            dialog.add_response ("cancel", _("Cancel"));
            dialog.add_response ("delete", _("Delete"));

            dialog.set_response_appearance ("delete", Adw.ResponseAppearance.DESTRUCTIVE);

            dialog.default_response = "cancel";
            dialog.close_response = "cancel";

            dialog.response.connect ((dialog, response) => {
                if (response == "delete") {
                    deletion_preferences.delete_files (true);
                    var tape_settings = Application.tape_client.settings;
                    tape_settings.can_cache = can_cache_switch.active;
                } else {
                    can_cache_switch.active = true;
                }
            });

            dialog.present (this);
        }
    }
}

