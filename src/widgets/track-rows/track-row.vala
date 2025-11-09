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

public abstract class Cassette.TrackRow: Reactable {

    public YaMAPI.Track track_info { get; construct; }

    public abstract HasTracks? yam_object { get; construct; }

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

    protected void form_queue () {
        if (yam_object == null) {
            warning ("[TRACK_ROW] form_queue: yam_object is null, cannot form queue");
            return;
        }

        var player = Application.tape_client.player;
        var track_list = yam_object.get_filtered_track_list (
            Application.app_settings.get_boolean ("explicit-visible"),
            Application.app_settings.get_boolean ("child-visible"),
            { track_info.id }
        );

        int track_index = track_list.index_of (track_info);

        if (track_index == -1) {
            for (int i = 0; i < track_list.size; i++) {
                if (track_list[i].id == track_info.id) {
                    track_index = i;
                    break;
                }
            }

            if (track_index == -1 && track_list.size > 0) {
                warning ("[TRACK_ROW] form_queue: Track not found in list; falling back to index 0");
                track_index = 0;
            }
        }

        var context_type = get_context_type (yam_object);
        var context_id = (yam_object.oid != null && yam_object.oid != "") ?
            yam_object.oid : null;

        debug (
            "[TRACK_ROW] form_queue: Track at index %d, start_track_list with context_type=%s, context_id=%s",
            track_index,
            context_type,
            context_id ?? "(null)");

        player.start_track_list (
            track_list,
            context_type,
            context_id,
            track_index,
            get_context_description (yam_object)
        );
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

        // Set accessible name for screen readers
        // Note: Using tooltip for accessibility as accessible-label property is not available
        tooltip_text = name;
    }

    static construct {
        set_css_name ("track-row");
    }
}

