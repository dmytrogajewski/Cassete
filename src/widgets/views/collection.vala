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

[GtkTemplate (ui = "/space/rirusha/Cassette/ui/collection-view.ui")]
public class Cassette.CollectionView : BaseView {
    [GtkChild]
    unowned HeaderedScrolledWindow scrolled_window;
    [GtkChild]
    unowned Gtk.Box main_box;
    [GtkChild]
    unowned Gtk.Button back_button;

    public override bool can_refresh { get; default = true; }

    TrackList? liked_tracks_list = null;
    Gtk.FlowBox? liked_albums_flow_box = null;
    Gtk.FlowBox? liked_playlists_flow_box = null;

    public CollectionView () {
        Object ();
    }

    construct {
        back_button.clicked.connect (() => {
            if (root_view != null) {
                root_view.backward ();
            }
        });

        // Create sections for liked tracks, albums, and playlists
        // Liked tracks section
        var liked_tracks_section = new Adw.PreferencesGroup ();
        liked_tracks_section.title = _("Liked Tracks");
        liked_tracks_section.description = _("Your favorite tracks");
        
        var liked_tracks_scrolled = new Gtk.ScrolledWindow ();
        liked_tracks_scrolled.height_request = 300;
        liked_tracks_scrolled.hscrollbar_policy = Gtk.PolicyType.NEVER;
        
        liked_tracks_list = new TrackList.simple ();
        liked_tracks_scrolled.child = liked_tracks_list;
        liked_tracks_section.add (liked_tracks_scrolled);
        main_box.append (liked_tracks_section);

        // Liked albums section
        var liked_albums_section = new Adw.PreferencesGroup ();
        liked_albums_section.title = _("Liked Albums");
        liked_albums_section.description = _("Albums you've liked");
        
        liked_albums_flow_box = new Gtk.FlowBox ();
        liked_albums_flow_box.selection_mode = Gtk.SelectionMode.NONE;
        liked_albums_flow_box.max_children_per_line = 4;
        liked_albums_flow_box.min_children_per_line = 1;
        liked_albums_flow_box.homogeneous = true;
        liked_albums_section.add (liked_albums_flow_box);
        main_box.append (liked_albums_section);

        // Liked playlists section
        var liked_playlists_section = new Adw.PreferencesGroup ();
        liked_playlists_section.title = _("Liked Playlists");
        liked_playlists_section.description = _("Playlists you've liked");
        
        liked_playlists_flow_box = new Gtk.FlowBox ();
        liked_playlists_flow_box.selection_mode = Gtk.SelectionMode.NONE;
        liked_playlists_flow_box.max_children_per_line = 4;
        liked_playlists_flow_box.min_children_per_line = 1;
        liked_playlists_flow_box.homogeneous = true;
        liked_playlists_section.add (liked_playlists_flow_box);
        main_box.append (liked_playlists_section);
    }

    void set_values (
        YaMAPI.TrackHeap? liked_tracks,
        Gee.ArrayList<YaMAPI.Album>? liked_albums,
        Gee.ArrayList<YaMAPI.LikedPlaylist>? liked_playlists
    ) {
        debug ("CollectionView.set_values: tracks=%d, albums=%d, playlists=%d",
            liked_tracks != null ? liked_tracks.tracks.size : 0,
            liked_albums != null ? liked_albums.size : 0,
            liked_playlists != null ? liked_playlists.size : 0);

        // Set liked tracks
        if (liked_tracks != null && liked_tracks.tracks.size > 0) {
            liked_tracks_list.set_tracks_base (liked_tracks.tracks, liked_tracks);
        } else {
            liked_tracks_list.clear_all ();
        }

        // Set liked albums
        // Clear existing first
        while (liked_albums_flow_box.get_first_child () != null) {
            liked_albums_flow_box.remove (liked_albums_flow_box.get_first_child ());
        }
        if (liked_albums != null && liked_albums.size > 0) {
            // Add album cards
            foreach (var album in liked_albums) {
                var album_micro = new AlbumMicro (this, album);
                liked_albums_flow_box.append (album_micro);
            }
        }

        // Set liked playlists
        // Clear existing first
        while (liked_playlists_flow_box.get_first_child () != null) {
            liked_playlists_flow_box.remove (liked_playlists_flow_box.get_first_child ());
        }
        if (liked_playlists != null && liked_playlists.size > 0) {
            // Add playlist cards
            foreach (var playlist in liked_playlists) {
                var playlist_micro = new LikedPlaylistMicro (this, playlist);
                liked_playlists_flow_box.append (playlist_micro);
            }
        }

        show_ready ();
    }

    public async override void first_show () {
        yield refresh ();
    }

    public async override int try_load_from_web () {
        var yam_helper = Application.tape_client.yam_helper;
        
        YaMAPI.TrackHeap? liked_tracks = null;
        Gee.ArrayList<YaMAPI.Album>? liked_albums = null;
        Gee.ArrayList<YaMAPI.LikedPlaylist>? liked_playlists = null;

        try {
            // Fetch collection data using new API endpoints
            debug ("CollectionView: Fetching liked tracks...");
            liked_tracks = yield yam_helper.get_collection_liked_tracks (50);
            if (liked_tracks != null) {
                debug ("CollectionView: Liked tracks result: %d tracks", liked_tracks.tracks.size);
            } else {
                debug ("CollectionView: Liked tracks result: null");
            }
            
            debug ("CollectionView: Fetching liked albums...");
            liked_albums = yield yam_helper.get_collection_liked_albums (8);
            if (liked_albums != null) {
                debug ("CollectionView: Liked albums result: %d albums", liked_albums.size);
            } else {
                debug ("CollectionView: Liked albums result: null");
            }
            
            debug ("CollectionView: Fetching liked playlists...");
            liked_playlists = yield yam_helper.get_collection_liked_playlists (8);
            if (liked_playlists != null) {
                debug ("CollectionView: Liked playlists result: %d playlists", liked_playlists.size);
            } else {
                debug ("CollectionView: Liked playlists result: null");
            }
        } catch (ApiBase.BadStatusCodeError e) {
            // Ignore bad status codes - show empty state
            warning ("API returned bad status code for collection: %d", e.code);
        } catch (Error e) {
            warning ("Failed to load collection: %s", e.message);
        }

        // Always show the view, even if some data is missing
        set_values (liked_tracks, liked_albums, liked_playlists);
        return -1;
    }

    public async override bool try_load_from_cache () {
        // For now, don't cache collection - always fetch fresh
        return false;
    }
}

