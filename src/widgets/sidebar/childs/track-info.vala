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

[GtkTemplate (ui = "/space/rirusha/Cassette/ui/track-info.ui")]
public class Cassette.TrackInfo : SidebarChildBin {

    [GtkChild]
    unowned Gtk.Label track_name_value;
    [GtkChild]
    unowned Gtk.Label track_version_value;
    [GtkChild]
    unowned Gtk.Box track_version_row;
    [GtkChild]
    unowned Gtk.Label track_artists_value;
    [GtkChild]
    unowned Gtk.Label album_name_value;
    [GtkChild]
    unowned Gtk.Label album_year_value;
    [GtkChild]
    unowned Gtk.Box album_year_row;
    [GtkChild]
    unowned Gtk.Label track_duration_value;
    [GtkChild]
    unowned Gtk.Label album_genre_value;
    [GtkChild]
    unowned Gtk.Box album_genre_row;
    [GtkChild]
    unowned Gtk.Box track_info_box;

    public YaMAPI.Track track_info { get; construct set; }
    YaMAPI.Album? album_info = null;

    public TrackInfo (YaMAPI.Track track_info) {
        Object (track_info: track_info);
    }

    construct {
        title = _("Track Information");
        child_id = track_info.id;
        subtitle = track_info.title_with_version;

        update_track_info ();
    }

    void update_track_info () {
        // Track name
        track_name_value.label = track_info.title ?? "";

        // Track version
        if (track_info.version != null && track_info.version != "") {
            track_version_value.label = track_info.version;
            track_version_row.visible = true;
        } else {
            track_version_row.visible = false;
        }

        // Artists
        track_artists_value.label = track_info.get_artists_names ();

        // Album name
        if (!track_info.albums.is_empty) {
            album_name_value.label = track_info.albums[0].title ?? "";
            album_info = track_info.albums[0];
        } else {
            album_name_value.label = track_info.get_album_title ();
            album_info = null;
        }

        // Album year
        if (album_info != null && album_info.year > 0) {
            album_year_value.label = album_info.year.to_string ();
            album_year_row.visible = true;
        } else {
            album_year_row.visible = false;
        }

        // Duration
        track_duration_value.label = ms2str (track_info.duration_ms, true);

        // Genre
        if (album_info != null && album_info.genre != null && album_info.genre != "") {
            album_genre_value.label = album_info.genre;
            album_genre_row.visible = true;
        } else {
            album_genre_row.visible = false;
        }
    }

}

