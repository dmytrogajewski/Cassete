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

[GtkTemplate (ui = "/space/rirusha/Cassette/ui/main-view.ui")]
public class Cassette.MainView : BaseView {

    [GtkChild]
    unowned HeaderedScrolledWindow scrolled_window;
    [GtkChild]
    unowned Gtk.Overlay main_overlay;
    [GtkChild]
    unowned Gtk.Box main_box;

    public override bool can_refresh { get; default = true; }

    // My Wave section
    VibeCanvas? vibe_canvas = null;
    Gtk.Button? my_wave_play_button = null;
    Gtk.Button? my_wave_settings_button = null;
    
    // Tabs
    Gtk.Notebook? tabs_notebook = null;
    Gtk.Box? tab_content_box = null;
    
    // Quick access sections (now a list, not FlowBox)
    Gtk.Box? quick_access_list = null;
    
    // New releases section
    Gtk.Box? new_releases_box = null;
    Gtk.ScrolledWindow? new_releases_scrolled = null;
    
    // Waves section (discoveries) - tabbed with horizontal scrollable lists
    Gtk.Box? waves_tabs_box = null;
    Gtk.Stack? waves_stack = null;
    Gee.HashMap<string, Gtk.Box> waves_boxes = new Gee.HashMap<string, Gtk.Box> ();
    
    // In-style section
    Gtk.Stack? in_style_stack = null;
    Gee.HashMap<string, Gtk.Box> in_style_boxes = new Gee.HashMap<string, Gtk.Box> ();
    Gtk.Box? in_style_tabs_box = null;

    public MainView () {
        Object ();
    }

    construct {
        // Create My Wave section at the top
        var my_wave_section = new Adw.PreferencesGroup ();
        my_wave_section.title = ""; // No title for My Wave
        
        var my_wave_container = new Gtk.Box (Gtk.Orientation.VERTICAL, 12);
        my_wave_container.margin_top = 24;
        my_wave_container.margin_bottom = 24;
        my_wave_container.set_hexpand (true);
        my_wave_container.halign = Gtk.Align.FILL;
        
        // Animated vibe canvas with overlay for controls
        var vibe_overlay = new Gtk.Overlay ();
        vibe_overlay.set_hexpand (true);
        vibe_overlay.set_vexpand (false); // fixed-height hero; container fills width
        vibe_overlay.height_request = 520; // fixed hero height
        vibe_overlay.halign = Gtk.Align.FILL;
        vibe_overlay.valign = Gtk.Align.CENTER;
        
        vibe_canvas = new VibeCanvas ();
        vibe_canvas.set_hexpand (true);
        vibe_canvas.set_vexpand (true);
        
        vibe_overlay.set_child (vibe_canvas);
        
        // Play button overlay - centered on the canvas
        var controls_box = new Gtk.Box (Gtk.Orientation.HORIZONTAL, 12);
        controls_box.halign = Gtk.Align.CENTER;
        controls_box.valign = Gtk.Align.CENTER;
        controls_box.add_css_class ("linked");
        
        my_wave_play_button = new Gtk.Button ();
        my_wave_play_button.label = _("Моя волна");
        my_wave_play_button.add_css_class ("suggested-action");
        my_wave_play_button.clicked.connect (on_my_wave_play);
        
        my_wave_settings_button = new Gtk.Button ();
        my_wave_settings_button.label = _("Настроить");
        my_wave_settings_button.clicked.connect (on_my_wave_settings);
        
        controls_box.append (my_wave_play_button);
        controls_box.append (my_wave_settings_button);
        
        vibe_overlay.add_overlay (controls_box);
        my_wave_container.append (vibe_overlay);
        my_wave_section.add (my_wave_container);
        main_box.append (my_wave_section);
        
        // Create tabs
        tabs_notebook = new Gtk.Notebook ();
        tabs_notebook.show_tabs = true;
        tabs_notebook.show_border = false;
        
        tab_content_box = new Gtk.Box (Gtk.Orientation.VERTICAL, 32);
        tabs_notebook.append_page (tab_content_box, new Gtk.Label (_("For you")));
        // Add Trends tab later if needed
        main_box.append (tabs_notebook);

        // Create quick access section (Liked, History) - as a list
        var quick_access_section = new Adw.PreferencesGroup ();
        quick_access_section.title = ""; // No title, shown as list items
        
        quick_access_list = new Gtk.Box (Gtk.Orientation.HORIZONTAL, 16);
        quick_access_list.margin_start = 12;
        quick_access_list.margin_end = 12;
        quick_access_list.margin_top = 16;
        quick_access_list.margin_bottom = 8;
        quick_access_section.add (quick_access_list);
        tab_content_box.append (quick_access_section);

        // Create new releases section
        var new_releases_section = new Adw.PreferencesGroup ();
        new_releases_section.title = _("New Releases");
        
        new_releases_scrolled = new Gtk.ScrolledWindow ();
        new_releases_scrolled.height_request = 280;
        new_releases_scrolled.hscrollbar_policy = Gtk.PolicyType.AUTOMATIC;
        new_releases_scrolled.vscrollbar_policy = Gtk.PolicyType.NEVER;
        
        new_releases_box = new Gtk.Box (Gtk.Orientation.HORIZONTAL, 12);
        new_releases_box.margin_start = 12;
        new_releases_box.margin_end = 12;
        new_releases_box.margin_top = 12;
        new_releases_box.margin_bottom = 12;
        
        new_releases_scrolled.child = new_releases_box;
        new_releases_section.add (new_releases_scrolled);
        tab_content_box.append (new_releases_section);

        // Create waves section (discoveries) - tabbed with horizontal scrollable lists
        var waves_section = new Adw.PreferencesGroup ();
        waves_section.title = _("More Discoveries");
        
        waves_tabs_box = new Gtk.Box (Gtk.Orientation.HORIZONTAL, 8);
        waves_tabs_box.margin_bottom = 12;
        
        waves_stack = new Gtk.Stack ();
        waves_stack.transition_type = Gtk.StackTransitionType.CROSSFADE;
        
        var waves_container = new Gtk.Box (Gtk.Orientation.VERTICAL, 8);
        waves_container.append (waves_tabs_box);
        waves_container.append (waves_stack);
        
        waves_section.add (waves_container);
        tab_content_box.append (waves_section);

        // Create in-style section
        var in_style_section = new Adw.PreferencesGroup ();
        in_style_section.title = _("In Style");
        
        in_style_tabs_box = new Gtk.Box (Gtk.Orientation.HORIZONTAL, 8);
        in_style_tabs_box.margin_bottom = 12;
        
        in_style_stack = new Gtk.Stack ();
        in_style_stack.transition_type = Gtk.StackTransitionType.CROSSFADE;
        
        var in_style_container = new Gtk.Box (Gtk.Orientation.VERTICAL, 8);
        in_style_container.append (in_style_tabs_box);
        in_style_container.append (in_style_stack);
        
        in_style_section.add (in_style_container);
        tab_content_box.append (in_style_section);
    }

    void clear_sections () {
        // Clear quick access
        if (quick_access_list != null) {
            var children = quick_access_list.get_first_child ();
            while (children != null) {
                var next = children.get_next_sibling ();
                quick_access_list.remove (children);
                children = next;
            }
        }
        
        // Clear new releases
        if (new_releases_box != null) {
            var children = new_releases_box.get_first_child ();
            while (children != null) {
                var next = children.get_next_sibling ();
                new_releases_box.remove (children);
                children = next;
            }
        }
        
        // Clear waves
        if (waves_tabs_box != null) {
            var children = waves_tabs_box.get_first_child ();
            while (children != null) {
                var next = children.get_next_sibling ();
                waves_tabs_box.remove (children);
                children = next;
            }
        }
        if (waves_stack != null) {
            var children = waves_stack.get_first_child ();
            while (children != null) {
                var next = children.get_next_sibling ();
                waves_stack.remove (children);
                children = next;
            }
        }
        waves_boxes.clear ();
        
        // Clear in-style
        if (in_style_stack != null) {
            var children = in_style_stack.get_first_child ();
            while (children != null) {
                var next = children.get_next_sibling ();
                in_style_stack.remove (children);
                children = next;
            }
        }
        
        if (in_style_tabs_box != null) {
            var children = in_style_tabs_box.get_first_child ();
            while (children != null) {
                var next = children.get_next_sibling ();
                in_style_tabs_box.remove (children);
                children = next;
            }
        }
        
        in_style_boxes.clear ();
    }

    async void set_values_async () {
        clear_sections ();
        
        var yam_helper = Application.tape_client.yam_helper;
        var client = yam_helper.client;

        // Load quick access (Liked and History) - as list items
        try {
            // Load full liked playlist to get track count and proper cover
            YaMAPI.Playlist? liked_full = null;
            try {
                liked_full = yield client.users_playlists_playlist ("3", false, yam_helper.me.uid);
            } catch (Error e) {
                debug ("Failed to load full liked playlist: %s", e.message);
            }
            var liked_playlist = liked_full ?? new YaMAPI.Playlist.liked ();
            
            string liked_subtitle = liked_playlist.track_count > 0 ? liked_playlist.track_count.to_string () : "";
            var liked_title_text = liked_playlist.title ?? _("Liked");
            var liked_card = new ActionCardWide (liked_playlist, liked_title_text, liked_subtitle);
            liked_card.hexpand = true;
            liked_card.halign = Gtk.Align.FILL;
            // Ensure labels are populated regardless of construct order
            liked_card.update_title_label (liked_title_text);
            liked_card.update_subtitle_label (liked_subtitle);
            liked_card.clicked.connect (() => {
                if (root_view != null) {
                    root_view.add_view (new PlaylistView (liked_playlist.uid, liked_playlist.kind));
                }
            });
            quick_access_list.append (liked_card);
            
            // Load History playlist
            try {
                var history_playlist = yield client.landing_block_premiere_recent_tracks ();
                if (history_playlist != null) {
                    var history_title_text = _("History");
                    var history_sub_text = history_playlist.description;
                    var history_card = new ActionCardWide (history_playlist, history_title_text, history_sub_text);
                    history_card.hexpand = true;
                    history_card.halign = Gtk.Align.FILL;
                    history_card.update_title_label (history_title_text);
                    history_card.update_subtitle_label (history_sub_text);
                    history_card.clicked.connect (() => {
                        if (root_view != null) {
                            root_view.add_view (new PlaylistView (history_playlist.uid, history_playlist.kind));
                        }
                    });
                    quick_access_list.append (history_card);
                }
            } catch (Error e) {
                debug ("Failed to load history playlist: %s", e.message);
            }
        } catch (Error e) {
            warning ("Failed to load quick access: %s", e.message);
        }

        // Load new releases
        try {
            var new_releases = yield client.landing_blocks_new_releases ();
            if (new_releases != null) {
                foreach (var album in new_releases.get_albums ()) {
                    if (album != null) {
                        debug ("[MainView] NewRelease album title=%s cover_uri=%s", album.title, album.cover_uri ?? "null");
                        var album_micro = new AlbumMicro (this, album);
                        new_releases_box.append (album_micro);
                    }
                }
            }
        } catch (Error e) {
            warning ("Failed to load new releases: %s", e.message);
        }

        // Load waves (discoveries) - tabbed with horizontal scrollable lists
        try {
            var waves = yield client.landing_blocks_waves ();
            debug ("Loaded waves: %d groups, %d items", waves?.groups?.size ?? 0, waves?.items?.size ?? 0);
            if (waves != null && waves.groups != null && waves.groups.size > 0) {
                foreach (var group in waves.groups) {
                    if (group.items.size == 0) continue;
                    
                    // Create tab button for this group
                    var tab_button = new Gtk.ToggleButton ();
                    tab_button.label = group.title;
                    tab_button.group = null; // Will be grouped by Gtk
                    
                    // Create scrollable box for this group
                    var scrolled = new Gtk.ScrolledWindow ();
                    scrolled.height_request = 200;
                    scrolled.hscrollbar_policy = Gtk.PolicyType.AUTOMATIC;
                    scrolled.vscrollbar_policy = Gtk.PolicyType.NEVER;
                    
                    var box = new Gtk.Box (Gtk.Orientation.HORIZONTAL, 12);
                    box.margin_start = 12;
                    box.margin_end = 12;
                    box.margin_top = 12;
                    box.margin_bottom = 12;
                    
                    scrolled.child = box;
                    
                    // Store box reference
                    waves_boxes[group.id] = box;
                    
                    // Add items to box using station tiles (same visuals as albums)
                    foreach (var wave_item in group.items) {
                        if (wave_item != null && wave_item.station_info != null) {
                            var station_tile = new StationMicro (this, wave_item.station_info);
                            box.append (station_tile);
                        }
                    }
                    
                    // Add to stack
                    waves_stack.add_named (scrolled, group.id);
                    
                    // Connect tab button
                    tab_button.toggled.connect (() => {
                        if (tab_button.active && waves_stack != null) {
                            waves_stack.visible_child_name = group.id;
                        }
                    });
                    
                    // Select first tab
                    if (waves_tabs_box.get_first_child () == null) {
                        tab_button.active = true;
                    }
                    
                    waves_tabs_box.append (tab_button);
                }
            }
        } catch (Error e) {
            warning ("Failed to load waves: %s", e.message);
        }

        // Load in-style
        try {
            var in_style = yield client.landing_blocks_in_style ();
            if (in_style != null && in_style.tabs != null) {
                debug ("Loaded in-style with %d tabs", in_style.tabs.size);
                foreach (var tab in in_style.tabs) {
                        if (tab.title != null) {
                            // Create tab button
                            var tab_button = new Gtk.ToggleButton ();
                            tab_button.label = tab.title;
                            tab_button.group = null; // Will be grouped by Gtk
                            tab_button.toggled.connect (() => {
                                if (tab_button.active && in_style_stack != null) {
                                    in_style_stack.visible_child_name = tab.id.to_string ();
                                }
                            });
                            
                            // Check if this is the first tab
                            if (in_style_tabs_box.get_first_child () == null) {
                                tab_button.active = true; // First tab active
                            }
                            
                            in_style_tabs_box.append (tab_button);
                            
                            // Create albums box for this tab
                            var albums_box = new Gtk.Box (Gtk.Orientation.HORIZONTAL, 12);
                            albums_box.margin_start = 12;
                            albums_box.margin_end = 12;
                            albums_box.margin_top = 12;
                            albums_box.margin_bottom = 12;
                            
                            var albums_scrolled = new Gtk.ScrolledWindow ();
                            albums_scrolled.height_request = 280;
                            albums_scrolled.hscrollbar_policy = Gtk.PolicyType.AUTOMATIC;
                            albums_scrolled.vscrollbar_policy = Gtk.PolicyType.NEVER;
                            albums_scrolled.child = albums_box;
                            
                            in_style_stack.add_named (albums_scrolled, tab.id.to_string ());
                            in_style_boxes[tab.id.to_string ()] = albums_box;
                            
                            // Load albums for this tab
                            if (tab.items != null) {
                                foreach (var item in tab.items) {
                                    if (item.album != null) {
                                        debug ("[MainView] InStyle tab=%s album title=%s cover_uri=%s", tab.title, item.album.title, item.album.cover_uri ?? "null");
                                        var album_micro = new AlbumMicro (this, item.album);
                                        albums_box.append (album_micro);
                                    }
                                }
                            }
                        }
                }
            } else {
                debug ("in-style is null or tabs is null");
            }
        } catch (Error e) {
            warning ("Failed to load in-style: %s", e.message);
        }

        show_ready ();
    }

    void set_values () {
        set_values_async.begin ();
    }

    public async override void first_show () {
        set_values ();
    }

    public async override bool try_load_from_cache () {
        return true;
    }

    public async override int try_load_from_web () {
        set_values ();
        return -1;
    }

    public async override void refresh () {
        set_values ();
    }
    
    void on_my_wave_play () {
        // Start My Wave station
        var player = Application.tape_client.player;
        var station_id = YaMAPI.Rotor.StationType.ON_YOUR_WAVE;
        
        player.start_flow.begin (station_id, new ArrayList<YaMAPI.Track> (), (obj, res) => {
            try {
                player.start_flow.end (res);
            } catch (Error e) {
                warning ("Failed to start My Wave: %s", e.message);
            }
        });
    }
    
    void on_my_wave_settings () {
        // Open wave settings
        if (root_view != null) {
            root_view.add_view (new StationsView ());
        }
    }
}
