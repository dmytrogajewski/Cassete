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
using Tape.YaMAPI;
using Gee;
using GLib;

[GtkTemplate (ui = "/space/rirusha/Cassette/ui/search-view.ui")]
public class Cassette.SearchView : BaseView {
    [GtkChild]
    unowned Gtk.Box main_box;
    [GtkChild]
    unowned Gtk.ScrolledWindow scrolled_window;
    [GtkChild]
    unowned Adw.StatusPage empty_state_page;
    [GtkChild]
    unowned Adw.StatusPage no_results_page;

    public override bool can_refresh { get; default = true; }

    TrackList track_list;

    public string search_query { get; set; default = ""; }

    public SearchView () {
        Object ();
    }

    construct {
        track_list = new TrackList.simple ();
        main_box.append (track_list);

        // Connect to search query changes
        notify.connect (on_search_view_notify);
    }

    void on_search_view_notify (ParamSpec pspec) {
        if (pspec.name == "search-query") {
            update_search_results.begin ();
        }
    }

    async void update_search_results () {
        // Hide all status pages initially
        empty_state_page.visible = false;
        no_results_page.visible = false;
        scrolled_window.visible = true;

        if (search_query == "" || search_query.length < 2) {
            track_list.clear_all ();
            // Show empty state when query is too short or empty
            scrolled_window.visible = false;
            empty_state_page.visible = true;
            show_ready ();
            debug ("[TEST] SearchView query too short: '%s'", search_query);
            return;
        }

        debug ("[TEST] SearchView executing query: '%s'", search_query);

        // Perform API search
        var yam_helper = Application.tape_client.yam_helper;
        try {
            var search_results = yield yam_helper.client.search_tracks (search_query, 0, 50);

            debug ("[TEST] SearchView result count: %d", search_results != null ? search_results.tracks.size : 0);

            if (search_results != null && search_results.tracks.size > 0) {
                track_list.set_tracks_base (search_results.tracks, search_results);
                scrolled_window.visible = true;
                no_results_page.visible = false;
                debug ("[TEST] SearchView populated results");
            } else {
                // No results found
                track_list.clear_all ();
                scrolled_window.visible = false;
                no_results_page.visible = true;
                debug ("[TEST] SearchView no results");
            }
        } catch (Error e) {
            warning ("Search failed: %s", e.message);
            track_list.clear_all ();
            // Show no results on error too
            scrolled_window.visible = false;
            no_results_page.visible = true;
            debug ("[TEST] SearchView error: %s", e.message);
        }

        show_ready ();
        debug ("[TEST] SearchView update completed");
    }

    void set_values () {
        track_list.clear_all ();
        // Show empty state initially
        scrolled_window.visible = false;
        empty_state_page.visible = true;
        no_results_page.visible = false;
        show_ready ();
        debug ("[TEST] SearchView initialized");
    }

    public async override void first_show () {
        yield refresh ();
    }

    public async override int try_load_from_web () {
        // Search is performed dynamically when search_query changes
        // This method just initializes the view
        set_values ();
        return -1;
    }

    public async override bool try_load_from_cache () {
        // For now, don't cache search results - always fetch fresh
        return false;
    }
}
