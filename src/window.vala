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
using GLib;

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
    unowned Adw.HeaderBar headerbar;
    [GtkChild]
    unowned Adw.WindowTitle window_title;
    [GtkChild]
    unowned Gtk.ToggleButton search_toggle_button;

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

    Gtk.SearchEntry search_entry;
    SearchView? current_search_view = null;

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

        // Sync window title with WindowTitle widget
        notify.connect (on_window_notify);
        if (window_title != null) {
            window_title.title = title;
        }

        // Create search entry for dynamic title-widget replacement
        search_entry = new Gtk.SearchEntry ();
        search_entry.placeholder_text = _("Search…");
        search_entry.width_chars = 30;
        search_entry.max_width_chars = 50;

        // Connect search entry text changes to update search view
        search_entry.search_changed.connect (on_search_changed);
        search_entry.activate.connect (on_search_activate);
    }

    void on_window_notify (ParamSpec pspec) {
        if (pspec.name == "title" && window_title != null) {
            window_title.title = title;
        }
    }

    public void show_message (string message) {
        toast_overlay.add_toast (new Adw.Toast (message));
    }

    void show_auth () {
        debug ("[TEST] Window show_auth invoked");
        auth.to_auth ();
    }

    void show_preferences () {
        debug ("[TEST] Preferences dialog opened");
        var pref_win = new PreferencesDialog ();
        pref_win.present (this);
    }

    void show_about () {
        debug ("[TEST] About dialog opened");
        build_about ().present (this);
    }

    void show_help_overlay () {
        debug ("[TEST] Help overlay opened");
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

    [GtkCallback]
    void on_search_toggled () {
        bool is_active = search_toggle_button.active;
        debug ("[TEST] Search toggle changed: active=%s", is_active.to_string ());

        if (is_active) {
            // Navigate to search view
            if (current_view != null) {
                if (current_search_view == null) {
                    current_search_view = new SearchView ();
                }
                current_view.add_view (current_search_view);
            }

            // Show search entry in header
            headerbar.title_widget = search_entry;
            search_entry.visible = true;
            search_entry.grab_focus ();
            search_entry.select_region (0, -1);
        } else {
            // Hide search entry and restore title
            headerbar.title_widget = window_title;
            search_entry.text = "";

            // Navigate back if we're on search view
            if (current_view != null && current_search_view != null) {
                var current_widget = current_view.current_widget;
                if (current_widget is SearchView) {
                    current_view.backward ();
                }
            }
        }
    }

    void on_search_changed () {
        debug ("[TEST] Search entry changed: %s", search_entry.text);
        if (current_search_view != null) {
            current_search_view.search_query = search_entry.text;
        } else {
            debug ("[TEST] Search entry change ignored: current_search_view is null");
        }
    }

    void on_search_activate () {
        // Search is updated automatically via search_changed signal
    }

    public Sidebar window_sidebar {
        get {
            return sidebar;
        }
    }
}
