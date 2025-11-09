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

namespace Cassette {
    [GtkTemplate (ui = "/space/rirusha/Cassette/ui/track-default-content.ui")]
    public class TrackDefault : TrackRow {

        [GtkChild]
        unowned TrackInfoPanel info_panel;
        [GtkChild]
        unowned SaveStack save_stack;
        [GtkChild]
        unowned DislikeButton dislike_button;
        [GtkChild]
        unowned LikeButton like_button;
        [GtkChild]
        unowned Gtk.Label duration_label;
        [GtkChild]
        unowned TrackPlaylistOptionsButton track_playlist_options_button;

        public override HasTracks? yam_object { get; construct; }

        public bool show_dislike_button { get; construct; default = false; }

        protected override PlayMarkTrack play_mark_track {
            owned get {
                return info_panel.get_play_mark_track ();
            }
        }

        public TrackDefault (YaMAPI.Track track_info, HasTracks yam_object) {
            Object (track_info: track_info, yam_object: yam_object);
        }

        public TrackDefault.with_dislike_button (YaMAPI.Track track_info, HasTracks yam_object) {
            Object (track_info: track_info, yam_object: yam_object, show_dislike_button: true);
        }

        construct {
            if (show_dislike_button) {
                assert (!track_info.is_ugc);
                dislike_button.visible = true;
            }

            play_mark_track.triggered_not_playing.connect (form_queue);

            play_mark_track.notify.connect (on_play_mark_track_notify);

            var motion_controller = new Gtk.EventControllerMotion ();
            add_controller (motion_controller);

            info_panel.track_info = track_info;

            if (track_info.available) {
                duration_label.label = ms2str (track_info.duration_ms, true);
                motion_controller.enter.connect (on_motion_enter);
                motion_controller.leave.connect (on_motion_leave);

            } else {
                add_css_class ("not-available");

                info_panel.sensitive = false;
                duration_label.label = "";
                track_playlist_options_button.sensitive = false;

                this.tooltip_text = _("Track is not available");
            }

            like_button.init_content (track_info.id);
            dislike_button.init_content (track_info.id);
            play_mark_track.init_content (track_info.id);

            save_stack.init_content (track_info.id);

            track_playlist_options_button.track_info = track_info;
            track_playlist_options_button.playlist_info = (YaMAPI.Playlist) yam_object;
        }

        void on_play_mark_track_notify (ParamSpec pspec) {
            if (pspec.name == "is-current-playing") {
                is_current_playing = play_mark_track.is_current_playing;

                if (play_mark_track.is_current_playing) {
                    info_panel.show_play_button ();
                } else {
                    info_panel.show_cover ();
                }
            }
        }

        void on_motion_enter (Gtk.EventControllerMotion mc, double x, double y) {
            info_panel.show_play_button ();
        }

        void on_motion_leave (Gtk.EventControllerMotion mc) {
            if (!play_mark_track.is_current_playing) {
                info_panel.show_cover ();
            }
        }
    }
}
