/*
 * Copyright (C) 2023-2025 Vladimir Romanov <rirusha@altlinux.org>
 * 
 * This program is free software: you can redistribute it and/or modify
 * it under the terms of the GNU General Public License as published by
 * the Free Software Foundation, either version 3 of the License, or
 * (at your option) any later version.
 * 
 * This program is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the
 * GNU General Public License for more details.
 * 
 * You should have received a copy of the GNU General Public License
 * along with this program. If not, see
 * <https://www.gnu.org/licenses/gpl-3.0-standalone.html>.
 * 
 * SPDX-License-Identifier: GPL-3.0-or-later
 */

using Tape;

[GtkTemplate (ui = "/space/rirusha/Cassette/ui/window.ui")]
public sealed class Cassette.Window : Adw.ApplicationWindow {

    const ActionEntry[] ACTION_ENTRIES = {
        { "close-sidebar", on_close_sidebar_action },
        //  { "show-disliked-tracks", on_show_disliked_tracks_action },
        { "preferences", show_preferences },
        { "about", show_about },
        { "show-auth", show_auth },
        { "show-help-overlay", show_help_overlay },
    };

    [GtkChild]
    unowned Sidebar sidebar;
    [GtkChild]
    unowned Adw.ToastOverlay toast_overlay;
    [GtkChild]
    public unowned Auth auth;
    [GtkChild]
    unowned Adw.ToolbarView player_bar_toolbar;
    [GtkChild]
    unowned PlayerBar player_bar;

    public PageRoot? current_view { get; set; }

    public Window (Cassette.Application app) {
        Object (application: app);
    }

    construct {
        add_action_entries (ACTION_ENTRIES, this);

        Cassette.Application.app_settings.bind ("window-width", this, "default-width", SettingsBindFlags.DEFAULT);
        Cassette.Application.app_settings.bind ("window-height", this, "default-height", SettingsBindFlags.DEFAULT);
        Cassette.Application.app_settings.bind ("window-maximized", this, "maximized", SettingsBindFlags.DEFAULT);

        if (Config.IS_DEVEL) {
            add_css_class ("devel");
        }

        // Initialize PlayerBar with this window (it's already in the UI template)
        if (player_bar != null) {
            player_bar.window = this;
        }
    }

    public void show_message (string message) {
        toast_overlay.add_toast (new Adw.Toast (message));
    }

    void show_auth () {
        auth.to_auth ();
    }

    void show_preferences () {
        var pref_win = new PreferencesDialog ();
        pref_win.present (this);
    }

    void show_about () {
        build_about ().present (this);
    }

    void show_help_overlay () {
        var shortcuts = new ShortcutsWindow ();
        shortcuts.present (this);
    }

    public void show_player_bar () {
        player_bar_toolbar.reveal_bottom_bars = true;
        player_bar.visible = true;
    }

    public void hide_player_bar () {
        player_bar_toolbar.reveal_bottom_bars = false;
        player_bar.visible = false;
    }

    void on_close_sidebar_action () {
        sidebar.close ();
    }

    public Sidebar window_sidebar {
        get {
            return sidebar;
        }
    }
}
