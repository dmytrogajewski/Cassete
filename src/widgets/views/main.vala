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
    
    // Waves section (discoveries) - now horizontal scrollable, not FlowBox
    Gtk.Box? waves_box = null;
    Gtk.ScrolledWindow? waves_scrolled = null;
    
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
        tabs_notebook.append_page (tab_content_box, new Gtk.Label (_("Для вас")));
        // Add Trends tab later if needed
        main_box.append (tabs_notebook);

        // Create quick access section (Liked, History) - as a list
        var quick_access_section = new Adw.PreferencesGroup ();
        quick_access_section.title = ""; // No title, shown as list items
        
        quick_access_list = new Gtk.Box (Gtk.Orientation.VERTICAL, 8);
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

        // Create waves section (discoveries) - horizontal scrollable
        var waves_section = new Adw.PreferencesGroup ();
        waves_section.title = _("More Discoveries");
        
        waves_scrolled = new Gtk.ScrolledWindow ();
        waves_scrolled.height_request = 200;
        waves_scrolled.hscrollbar_policy = Gtk.PolicyType.AUTOMATIC;
        waves_scrolled.vscrollbar_policy = Gtk.PolicyType.NEVER;
        
        waves_box = new Gtk.Box (Gtk.Orientation.HORIZONTAL, 12);
        waves_box.margin_start = 12;
        waves_box.margin_end = 12;
        waves_box.margin_top = 12;
        waves_box.margin_bottom = 12;
        
        waves_scrolled.child = waves_box;
        waves_section.add (waves_scrolled);
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
        if (waves_box != null) {
            var children = waves_box.get_first_child ();
            while (children != null) {
                var next = children.get_next_sibling ();
                waves_box.remove (children);
                children = next;
            }
        }
        
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
            var liked_playlist = new YaMAPI.Playlist.liked ();
            var liked_micro = new PlaylistMicro (this, liked_playlist);
            quick_access_list.append (liked_micro);
            
            // History would go here if we have an endpoint
        } catch (Error e) {
            warning ("Failed to load quick access: %s", e.message);
        }

        // Load new releases
        try {
            var new_releases = yield client.landing_blocks_new_releases ();
            if (new_releases != null) {
                foreach (var album in new_releases.get_albums ()) {
                    if (album != null) {
                        var album_micro = new AlbumMicro (this, album);
                        new_releases_box.append (album_micro);
                    }
                }
            }
        } catch (Error e) {
            warning ("Failed to load new releases: %s", e.message);
        }

        // Load waves (discoveries) - horizontal scrollable
        try {
            var waves = yield client.landing_blocks_waves ();
            if (waves != null && waves.items != null) {
                foreach (var wave_item in waves.items) {
                    if (wave_item != null && wave_item.station_info != null) {
                        var action_card = new ActionCardStation (wave_item.station_info);
                        action_card.clicked.connect (() => {
                            if (root_view != null) {
                                root_view.add_view (new StationsView ());
                            }
                        });
                        waves_box.append (action_card);
                    }
                }
            }
        } catch (Error e) {
            warning ("Failed to load waves: %s", e.message);
        }

        // Load in-style
        try {
            var in_style = yield client.landing_blocks_in_style ();
            if (in_style != null && in_style.tabs != null) {
                foreach (var tab in in_style.tabs) {
                    if (tab.artist != null && tab.id != null) {
                        // Create tab button
                        var tab_button = new Gtk.ToggleButton ();
                        tab_button.label = tab.title ?? tab.artist.name;
                        tab_button.group = null; // Will be grouped by Gtk
                        tab_button.toggled.connect (() => {
                            if (tab_button.active && in_style_stack != null) {
                                in_style_stack.visible_child_name = tab.id;
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
                        
                        in_style_stack.add_named (albums_scrolled, tab.id);
                        in_style_boxes[tab.id] = albums_box;
                        
                        // Load albums for this tab
                        if (tab.items != null) {
                            foreach (var item in tab.items) {
                                if (item.album != null) {
                                    var album_micro = new AlbumMicro (this, item.album);
                                    albums_box.append (album_micro);
                                }
                            }
                        }
                    }
                }
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
