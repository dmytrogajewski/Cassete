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
using GLib;

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
        [GtkChild]
        unowned Adw.SwitchRow is_hq_switch;

        bool is_updating_hq_switch = false;

        construct {
            deletion_preferences.pref_win = this;

            show_save_stack_switch.notify.connect (on_show_save_stack_switch_notify);

            var tape_settings = Application.tape_client.settings;
            can_cache_switch.active = tape_settings.can_cache;

            can_cache_switch.notify.connect (on_can_cache_switch_notify);
            debug ("[TEST] Preferences dialog constructed");

            // Update switch when music_quality changes externally (from Settings binding)
            tape_settings.notify.connect (on_tape_settings_notify);

            // Connect switch to update music quality setting
            is_hq_switch.notify.connect (on_hq_switch_notify);

            // Initialize high quality switch based on current music quality setting
            // High quality = NQ or LOSSLESS, Low quality = LQ
            // Use Idle to ensure Settings binding has synced first, but guard the dialog lifetime
            weak PreferencesDialog weak_self = this;
            Idle.add_once (() => {
                var self = weak_self;
                if (self == null) {
                    return;
                }

                self.update_hq_switch_from_settings ();
            });

            // Explicitly initialize switches from Settings before binding
            // This ensures switches show correct saved values instead of defaulting to off
            add_tracks_to_start_switch.active = Application.client_settings.get_boolean ("add-tracks-to-start");
            available_visible_switch.active = Application.app_settings.get_boolean ("available-visible");
            show_playing_track_notif_switch.active = Application.app_settings.get_boolean ("show-playing-track-notif");
            child_visible_switch.active = Application.app_settings.get_boolean ("child-visible");
            explicit_visible_switch.active = Application.app_settings.get_boolean ("explicit-visible");
            show_replaced_mark_switch.active = Application.app_settings.get_boolean ("show-replaced-mark");
            show_save_stack_switch.active = Application.app_settings.get_boolean ("show-save-stack");
            show_temp_save_stack_switch.active = Application.app_settings.get_boolean ("show-temp-save-mark");
            use_only_dialogs_switch.active = Application.app_settings.get_boolean ("use-only-dialogs");
            show_main_switch.active = Application.app_settings.get_boolean ("show-main");
            show_liked_switch.active = Application.app_settings.get_boolean ("show-liked");
            show_playlists_switch.active = Application.app_settings.get_boolean ("show-playlists");

            // Now bind for bidirectional sync (changes will persist automatically)
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
            // Note: Music quality is now controlled via music-quality enum setting
            // (see Application.tape_client.settings.music_quality)
            // Debug mode is not available as a setting
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
            update_hq_switch_from_settings ();

            if (Config.IS_DEVEL) {
                add_css_class ("devel");
            }

            focus_widget = null;
        }

        void on_show_save_stack_switch_notify (ParamSpec pspec) {
            if (pspec.name == "active") {
                on_show_save_stack_switch_changed ();
            }
        }

        void on_can_cache_switch_notify (ParamSpec pspec) {
            if (pspec.name == "active") {
                if (!can_cache_switch.active) {
                    ask_about_deletion ();
                } else {
                    var tape_settings = Application.tape_client.settings;
                    tape_settings.can_cache = true;
                    debug ("[TEST] Preferences toggle: can_cache enabled");
                }
            }
        }

        void on_tape_settings_notify (ParamSpec pspec) {
            if (pspec.name == "music-quality") {
                on_music_quality_changed ();
            }
        }

        void on_hq_switch_notify (ParamSpec pspec) {
            if (pspec.name == "active") {
                debug ("[TEST] Preferences toggle: HQ switch changed to %s", is_hq_switch.active.to_string ());
                on_hq_switch_changed ();
            }
        }

        void on_show_save_stack_switch_changed () {
            show_temp_save_stack_switch.sensitive = show_save_stack_switch.active;
            debug ("[TEST] Preferences toggle: show_save_stack=%s", show_save_stack_switch.active.to_string ());
        }

        void on_hq_switch_changed () {
            if (is_updating_hq_switch) {
                return;
            }

            is_updating_hq_switch = true;

            var target_quality = is_hq_switch.active ?
                Tape.MusicQuality.NQ :
                Tape.MusicQuality.LQ;

            Application.client_settings.set_enum (
                "music-quality",
                (int) target_quality
            );

            // Ensure immediate in-session update before bindings propagate back
            var tape_settings = Application.tape_client.settings;
            tape_settings.music_quality = target_quality;

            if (target_quality == Tape.MusicQuality.LQ) {
                debug ("[TEST] Preferences toggle: HQ disabled");
            } else {
                debug ("[TEST] Preferences toggle: HQ enabled");
            }

            is_updating_hq_switch = false;
        }

        void update_hq_switch_from_settings () {
            var stored_quality = (Tape.MusicQuality) Application.client_settings.get_enum ("music-quality");
            var tape_settings = Application.tape_client.settings;

            is_updating_hq_switch = true;
            if (tape_settings.music_quality != stored_quality) {
                tape_settings.music_quality = stored_quality;
            }

            is_hq_switch.active = stored_quality != Tape.MusicQuality.LQ;
            is_updating_hq_switch = false;
            debug ("[TEST] Preferences HQ switch synced from settings: active=%s (quality=%s)",
                is_hq_switch.active.to_string (),
                stored_quality.to_string ());
        }

        void on_music_quality_changed () {
            if (is_updating_hq_switch) {
                return;
            }

            update_hq_switch_from_settings ();
            var tape_settings = Application.tape_client.settings;
            debug ("[TEST] Preferences music quality changed: quality=%s", tape_settings.music_quality.to_string ());
        }

        void ask_about_deletion () {
            var dialog = new Adw.AlertDialog (
                _("Delete cache files?"),
                _("All cache will be deleted. This doesn't affect on saved playlists or albums")
            );
            debug ("[TEST] Preferences cache deletion dialog opened");

            // Translators: cancel of deleting playlist
            dialog.add_response ("cancel", _("Cancel"));
            dialog.add_response ("delete", _("Delete"));

            dialog.set_response_appearance ("delete", Adw.ResponseAppearance.DESTRUCTIVE);

            dialog.default_response = "cancel";
            dialog.close_response = "cancel";

            dialog.response.connect (on_delete_dialog_response);

            dialog.present (this);
        }

        void on_delete_dialog_response (Adw.AlertDialog dialog, string response) {
            if (response == "delete") {
                deletion_preferences.delete_files (true);
                var tape_settings = Application.tape_client.settings;
                tape_settings.can_cache = can_cache_switch.active;
                debug ("[TEST] Preferences cache deletion confirmed");
            } else {
                can_cache_switch.active = true;
                debug ("[TEST] Preferences cache deletion cancelled");
            }
        }
    }
}

