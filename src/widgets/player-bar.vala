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
using GLib;

[GtkTemplate (ui = "/space/rirusha/Cassette/ui/player-bar.ui")]
public class Cassette.PlayerBar : Adw.Bin {

        [GtkChild]
        unowned Gtk.Label current_time_mark;
        [GtkChild]
        unowned Gtk.Label total_time_mark;
        [GtkChild]
        unowned Gtk.Scale slider;
        [GtkChild]
        unowned Gtk.Button flow_settings_button;
        [GtkChild]
        unowned Gtk.Button prev_track_button;
        [GtkChild]
        unowned Gtk.Button next_track_button;
        [GtkChild]
        unowned Gtk.Button track_detailed_button;
        [GtkChild]
        unowned DislikeButton dislike_button;
        [GtkChild]
        unowned LikeButton like_button;
        [GtkChild]
        unowned Gtk.Button queue_show_button;
        [GtkChild]
        unowned SaveStack save_stack;
        [GtkChild]
        unowned Gtk.Button shuffle_button;
        [GtkChild]
        unowned Gtk.Button repeat_button;
        [GtkChild]
        unowned Gtk.Button fullscreen_button;
        [GtkChild]
        unowned TrackOptionsButton track_options_button;
        [GtkChild]
        unowned Gtk.Label hq_indicator;

        public Window window { get; construct set; }

        public YaMAPI.Track? current_track_info { get; private set; default = null; }

        public PlayerBar (Window window) {
            Object (window: window);
        }

        construct {
            // Set accessible names using tooltips for screen readers
            prev_track_button.tooltip_text = _("Play previous track");
            next_track_button.tooltip_text = _("Play next track");
            repeat_button.tooltip_text = _("Change repeat mode");
            shuffle_button.tooltip_text = _("Change shuffle mode");
            flow_settings_button.tooltip_text = _("Show wave settings");
            queue_show_button.tooltip_text = _("Show playback queue");
            track_detailed_button.tooltip_text = _("Show track info");
            fullscreen_button.tooltip_text = _("Toggle fullscreen");
            slider.tooltip_text = _("Playback position");
            // Labels use their text content as accessible text automatically

            var player = Application.tape_client.player;

            player.stopped.connect (on_player_stopped);

            player.ready_play_next.connect (on_ready_play_next);

            player.ready_play_prev.connect (on_ready_play_prev);

            bind_property ("current-track-info", track_options_button, "track-info", BindingFlags.DEFAULT);

            player.playback_callback.connect (on_playback_callback);

            player.bind_property ("can-go-prev", prev_track_button, "sensitive", BindingFlags.DEFAULT);
            player.bind_property ("can-go-next", next_track_button, "sensitive", BindingFlags.DEFAULT);

            player.bind_property ("current-track-loading", this, "sensitive",
                                  BindingFlags.DEFAULT | BindingFlags.INVERT_BOOLEAN);

            player.mode_inited.connect (on_player_mode_inited);

            player.notify.connect (on_player_mode_notify);

            var playerbar_actions = new SimpleActionGroup ();

            SimpleAction prev_action = new SimpleAction ("prev", null);
            prev_action.activate.connect (on_prev_action_activate);
            playerbar_actions.add_action (prev_action);

            SimpleAction next_action = new SimpleAction ("next", null);
            next_action.activate.connect (on_next_action_activate);
            playerbar_actions.add_action (next_action);

        insert_action_group ("playerbar", playerbar_actions);

            player.notify.connect (on_player_notify);
            on_repeat_mode_changed ();
            on_shuffle_mode_changed ();

            // Update HQ indicator based on music quality setting
            var tape_settings = Application.tape_client.settings;
            update_hq_indicator (tape_settings.music_quality);
            tape_settings.notify.connect (on_tape_settings_notify);

            Idle.add_once (() => {
                window.window_sidebar.notify.connect (on_sidebar_notify);

                window.window_sidebar.child_changed.connect (on_sidebar_child_changed);
            });

            block_widget (flow_settings_button, BlockReason.NOT_IMPLEMENTED);
            block_widget (fullscreen_button, BlockReason.NOT_IMPLEMENTED);
        }

        void on_player_mode_notify (ParamSpec pspec) {
            if (pspec.name == "mode") {
                // Close WaveSettings sidebar when player mode changes
                if (window.window_sidebar.sidebar_child != null &&
                    window.window_sidebar.child_id.has_suffix (":wave")) {
                    window.window_sidebar.close ();
                }

                sensitive = false;
            }
        }

        void on_player_notify (ParamSpec pspec) {
            if (pspec.name == "repeat-mode") {
                on_repeat_mode_changed ();
            } else if (pspec.name == "shuffle-mode") {
                on_shuffle_mode_changed ();
            }
        }

        void on_tape_settings_notify (ParamSpec pspec) {
            if (pspec.name == "music-quality") {
                var tape_settings = Application.tape_client.settings;
                update_hq_indicator (tape_settings.music_quality);
            }
        }

        void on_sidebar_notify (ParamSpec pspec) {
            if (pspec.name == "child-id") {
                if (current_track_info != null) {
                    if (window.window_sidebar.child_id == current_track_info.id) {
                        track_detailed_button.remove_css_class ("flat");
                        return;
                    }
                }
                track_detailed_button.add_css_class ("flat");
            } else if (pspec.name == "is-shown") {
                if (window.window_sidebar.is_shown == false) {
                    queue_show_button.add_css_class ("flat");
                    track_detailed_button.add_css_class ("flat");
                    flow_settings_button.add_css_class ("flat");
                }
            }
        }

        void on_sidebar_child_changed (SidebarChildBin? new_child) {
            // Check if PlayerQueue is shown (when migrated)
            if (new_child != null && new_child.child_id == "queue") {
                queue_show_button.remove_css_class ("flat");
                return;
            }
            queue_show_button.add_css_class ("flat");

            // Check if WaveSettings is shown (when migrated)
            // WaveSettings uses child_id = "null:wave" in the old implementation
            if (new_child != null &&
                (new_child.child_id == "wave-settings" ||
                 new_child.child_id.has_suffix (":wave"))) {
                flow_settings_button.remove_css_class ("flat");
            } else {
                flow_settings_button.add_css_class ("flat");
            }
        }

        void on_player_stopped () {
            slider.set_value (0.0d);
        }

        void on_ready_play_next () {
            var player = Application.tape_client.player;
            update_current_track_controls (player.mode.get_current_track_info ());
        }

        void on_ready_play_prev () {
            var player = Application.tape_client.player;
            update_current_track_controls (player.mode.get_current_track_info ());
        }

        [GtkCallback]
        bool on_slider_change_value (Gtk.ScrollType scroll_type, double new_value) {
            var player = Application.tape_client.player;
            debug ("[TEST] PlayerBar slider moved: value=%f", new_value);
            player.seek ((int) (new_value * 1000));
            on_playback_callback (new_value);
            return false;
        }

        void on_prev_action_activate () {
            var player = Application.tape_client.player;
            debug ("[TEST] PlayerBar previous action activated");
            player.prev (false);
        }

        void on_next_action_activate () {
            var player = Application.tape_client.player;
            debug ("[TEST] PlayerBar next action activated");
            player.next.begin ();
        }

        [GtkCallback]
        void on_track_detailed_button_clicked () {
            if (track_detailed_button.has_css_class ("flat")) {
                if (current_track_info != null) {
                    debug ("[TEST] PlayerBar track details requested: track_id=%s", current_track_info.id);
                    window.window_sidebar.show_track_info (current_track_info);
                }
            } else {
                debug ("[TEST] PlayerBar track details toggled off");
                window.window_sidebar.close ();
            }
        }

        [GtkCallback]
        void on_queue_show_button_clicked () {
            var player = Application.tape_client.player;
            if (window.window_sidebar.sidebar_child != null && window.window_sidebar.child_id == "queue") {
                debug ("[TEST] PlayerBar queue panel toggled off");
                window.window_sidebar.close ();
            } else {
                if (player.mode is PlayerTrackList) {
                    debug ("[TEST] PlayerBar queue panel requested");
                    window.window_sidebar.show_queue ();
                } else {
                    debug ("[TEST] PlayerBar queue panel unavailable: mode=%s", player.mode.get_type ().name ());
                }
            }
        }

        [GtkCallback]
        void on_flow_settings_button_clicked () {
            var player = Application.tape_client.player;
            if (window.window_sidebar.sidebar_child != null &&
                window.window_sidebar.child_id.has_suffix (":wave")) {
                debug ("[TEST] PlayerBar wave settings toggled off");
                window.window_sidebar.close ();
            } else {
                if (player.mode is PlayerFlow &&
                    player.mode.context_id == "user:onyourwave") {
                    debug ("[TEST] PlayerBar wave settings requested");
                    window.window_sidebar.show_wave_settings ();
                } else {
                    debug ("[TEST] PlayerBar wave settings unavailable: mode=%s context=%s",
                           player.mode.get_type ().name (),
                           player.mode.context_id ?? "null");
                }
            }
        }

        void on_playback_callback (double pos) {
            current_time_mark.label = sec2str ((int) pos, true);
            slider.set_value (pos);
        }

        void on_player_mode_inited () {
            var player = Application.tape_client.player;
            current_track_info = player.mode.get_current_track_info ();

            update_current_track_controls (current_track_info);
            debug ("[TEST] PlayerBar mode initialized: mode=%s track_id=%s",
                   player.mode.get_type ().name (),
                   current_track_info != null ? current_track_info.id : "<null>");

            if (player.mode is PlayerFlow) {
                to_flow ();

            } else if (player.mode is PlayerTrackList) {
                to_track_list ();

            } else {
                clear ();
            }
        }

        void update_current_track_controls (YaMAPI.Track? new_track) {
            if (new_track == null) {
                debug ("[TEST] PlayerBar update controls: no track");
                clear ();
                return;
            }

            current_track_info = new_track;
            debug ("[TEST] PlayerBar update controls: track_id=%s title=%s",
                   current_track_info.id,
                   current_track_info.title ?? "<null>");

            if (current_track_info.id == window.window_sidebar.child_id) {
                track_detailed_button.remove_css_class ("flat");
            } else {
                track_detailed_button.add_css_class ("flat");
            }

            var adjustment = slider.get_adjustment ();
            adjustment.set_upper (ms2sec (current_track_info.duration_ms));

            if (current_track_info.is_ugc) {
                // UGC tracks cannot be shared
                var app = (Application) GLib.Application.get_default ();
                var share_action = app.lookup_action ("share-current-track") as SimpleAction;
                if (share_action != null) {
                    share_action.set_enabled (false);
                }
                dislike_button.visible = false;
            } else {
                var app = (Application) GLib.Application.get_default ();
                var share_action = app.lookup_action ("share-current-track") as SimpleAction;
                if (share_action != null) {
                    share_action.set_enabled (true);
                }
                dislike_button.visible = true;
            }

            total_time_mark.label = ms2str (current_track_info.duration_ms, true);

            like_button.init_content (current_track_info.id);
            dislike_button.init_content (current_track_info.id);
            save_stack.init_content (current_track_info.id);

            window.show_player_bar ();
        }

        void to_flow () {
            var player = Application.tape_client.player;
            shuffle_button.visible = false;
            queue_show_button.visible = false;
            flow_settings_button.visible = player.mode.context_id == "user:onyourwave";
            debug ("[TEST] PlayerBar switched to flow mode: wave_button_visible=%s",
                   flow_settings_button.visible.to_string ());
        }

        void to_track_list () {
            shuffle_button.visible = true;
            flow_settings_button.visible = false;
            queue_show_button.visible = true;
            debug ("[TEST] PlayerBar switched to track list mode");
        }

        void clear () {
            current_track_info = null;

            sensitive = false;

            dislike_button.visible = true;
            queue_show_button.visible = false;
            total_time_mark.label = "";

            window.hide_player_bar ();

            save_stack.clear ();
            debug ("[TEST] PlayerBar cleared");
        }

        void on_shuffle_mode_changed () {
            var player = Application.tape_client.player;
            switch (player.shuffle_mode) {
                case Tape.ShuffleMode.ON:
                    shuffle_button.remove_css_class ("flat");
                    debug ("[TEST] PlayerBar shuffle mode: ON");
                    break;

                case Tape.ShuffleMode.OFF:
                    shuffle_button.add_css_class ("flat");
                    debug ("[TEST] PlayerBar shuffle mode: OFF");
                    break;
            }
        }

        void on_repeat_mode_changed () {
            var player = Application.tape_client.player;
            switch (player.repeat_mode) {
                case Tape.RepeatMode.QUEUE:
                    repeat_button.set_icon_name ("media-playlist-repeat-symbolic");
                    repeat_button.remove_css_class ("flat");
                    debug ("[TEST] PlayerBar repeat mode: QUEUE");
                    break;

                case Tape.RepeatMode.ONE:
                    repeat_button.set_icon_name ("media-playlist-repeat-song-symbolic");
                    repeat_button.remove_css_class ("flat");
                    debug ("[TEST] PlayerBar repeat mode: ONE");
                    break;

                case Tape.RepeatMode.OFF:
                    repeat_button.set_icon_name ("media-playlist-repeat-symbolic");
                    repeat_button.add_css_class ("flat");
                    debug ("[TEST] PlayerBar repeat mode: OFF");
                    break;
            }
        }

        void update_hq_indicator (Tape.MusicQuality quality) {
            // Show HQ indicator when quality is NQ (normal) or LOSSLESS
            hq_indicator.visible = quality != Tape.MusicQuality.LQ;
        }
    }
