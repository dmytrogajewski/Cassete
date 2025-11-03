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

public abstract class Cassette.TrackRow: Reactable {

    public YaMAPI.Track track_info { get; construct; }

    protected abstract PlayMarkTrack play_mark_track { owned get; }

    protected override string css_class_name_hover {
        owned get {
            return "hover";
        }
    }

    protected override string css_class_name_active {
        owned get {
            return "active";
        }
    }

    protected override string css_class_name_playing_default {
        owned get {
            return "playing";
        }
    }

    protected override string css_class_name_playing_hover {
        owned get {
            return "playing-hover";
        }
    }

    protected override string css_class_name_playing_active {
        owned get {
            return "playing-active";
        }
    }

    public void trigger () {
        if (track_info.available) {
            play_mark_track.trigger ();
        }
    }

    construct {
        update_accessible_name ();
    }

    void update_accessible_name () {
        if (track_info == null) {
            return;
        }

        string title = track_info.title_with_version ?? _("Unknown Track");
        string artists = track_info.get_artists_names ();

        string name;
        if (artists.length > 0) {
            name = @"$title - $artists";
        } else {
            name = title;
        }

        // Set accessible label for screen readers
        // In GTK4, this is done via the accessible-label property
        set_property ("accessible-label", name);
    }

    static construct {
        set_css_name ("track-row");
    }
}

