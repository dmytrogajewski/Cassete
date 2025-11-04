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

[GtkTemplate (ui = "/space/rirusha/Cassette/ui/track-base-content.ui")]
public class Cassette.TrackBase: TrackRow {

    [GtkChild]
    unowned TrackInfoPanel info_panel;
    [GtkChild]
    unowned Gtk.Label duration_label;
    [GtkChild]
    unowned TrackOptionsButton track_options_button;

    public HasTracks yam_object { get; construct; }

    protected override PlayMarkTrack play_mark_track {
        owned get {
            return info_panel.get_play_mark_track ();
        }
    }

    public TrackBase (YaMAPI.Track track_info, HasTracks yam_object) {
        Object (track_info: track_info, yam_object: yam_object);
    }

    construct {
        play_mark_track.triggered_not_playing.connect (form_queue);

        play_mark_track.notify["is-current-playing"].connect (() => {
            is_current_playing = play_mark_track.is_current_playing;

            if (play_mark_track.is_current_playing) {
                info_panel.show_play_button ();

            } else {
                info_panel.show_cover ();
            }
        });

        var motion_controller = new Gtk.EventControllerMotion ();
        add_controller (motion_controller);

        info_panel.track_info = track_info;

        if (track_info.available) {
            duration_label.label = ms2str (track_info.duration_ms, true);
            motion_controller.enter.connect ((mc, x, y) => {
                info_panel.show_play_button ();
            });
            motion_controller.leave.connect ((mc) => {
                if (!play_mark_track.is_current_playing) {
                    info_panel.show_cover ();
                }
            });

        } else {
            add_css_class ("not-available");

            info_panel.sensitive = false;
            duration_label.label = "";
            track_options_button.sensitive = false;

            this.tooltip_text = _("Track is not available");
        }

        play_mark_track.init_content (track_info.id);
        track_options_button.track_info = track_info;
    }

    void form_queue () {
        var player = Application.tape_client.player;
        var track_list = yam_object.get_filtered_track_list (
            Application.app_settings.get_boolean ("explicit-visible"),
            Application.app_settings.get_boolean ("child-visible"),
            { track_info.id }
        );

        int track_index = track_list.index_of (track_info);
        // If track not found by index_of (shouldn't happen, but safeguard),
        // find it by ID to ensure we have a valid index
        if (track_index == -1) {
            for (int i = 0; i < track_list.size; i++) {
                if (track_list[i].id == track_info.id) {
                    track_index = i;
                    break;
                }
            }
            // If still not found, default to 0 (play first track)
            if (track_index == -1 && track_list.size > 0) {
                track_index = 0;
            }
        }

        player.start_track_list (
            track_list,
            get_context_type (yam_object),
            yam_object.oid,
            track_index,
            get_context_description (yam_object)
        );
    }
}

