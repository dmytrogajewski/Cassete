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
        unowned VolumeButton volume_button;

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
            
            player.stopped.connect (() => {
                slider.set_value (0.0d);
            });

            player.ready_play_next.connect ((repeat) => {
                update_current_track_controls (player.mode.get_current_track_info ());
            });

            player.ready_play_prev.connect (() => {
                update_current_track_controls (player.mode.get_current_track_info ());
            });

            bind_property ("current-track-info", track_options_button, "track-info", BindingFlags.DEFAULT);

            slider.change_value.connect ((scroll_type, new_value) => {
                player.seek ((int) (new_value * 1000));
                on_playback_callback (new_value);
            });

            player.playback_callback.connect (on_playback_callback);

            player.bind_property ("can-go-prev", prev_track_button, "sensitive", BindingFlags.DEFAULT);
            player.bind_property ("can-go-next", next_track_button, "sensitive", BindingFlags.DEFAULT);

            player.bind_property ("current-track-loading", this, "sensitive", BindingFlags.DEFAULT | BindingFlags.INVERT_BOOLEAN);

            player.mode_inited.connect (on_player_mode_inited);

            player.notify["mode"].connect (() => {
                // Close WaveSettings sidebar when player mode changes
                if (window.window_sidebar.sidebar_child != null && window.window_sidebar.child_id.has_suffix (":wave")) {
                    window.window_sidebar.close ();
                }

                sensitive = false;
            });

            var playerbar_actions = new SimpleActionGroup ();

            SimpleAction prev_action = new SimpleAction ("prev", null);
            prev_action.activate.connect (() => {
                player.prev (false);
            });
            playerbar_actions.add_action (prev_action);

            SimpleAction next_action = new SimpleAction ("next", null);
            next_action.activate.connect (() => {
                player.next.begin ();
            });
            playerbar_actions.add_action (next_action);

            insert_action_group ("playerbar", playerbar_actions);

            track_detailed_button.clicked.connect (() => {
                if (track_detailed_button.has_css_class ("flat")) {
                    if (current_track_info != null) {
                        window.window_sidebar.show_track_info (current_track_info);
                    }
                } else {
                    window.window_sidebar.close ();
                }
            });

            queue_show_button.clicked.connect (() => {
                if (window.window_sidebar.sidebar_child != null && window.window_sidebar.child_id == "queue") {
                    window.window_sidebar.close ();
                } else {
                    if (player.mode is PlayerTrackList) {
                        window.window_sidebar.show_queue ();
                    }
                }
            });

            flow_settings_button.clicked.connect (() => {
                if (window.window_sidebar.sidebar_child != null && window.window_sidebar.child_id.has_suffix (":wave")) {
                    window.window_sidebar.close ();
                } else {
                    if (player.mode is PlayerFlow && player.mode.context_id == "user:onyourwave") {
                        window.window_sidebar.show_wave_settings ();
                    }
                }
            });

            player.notify["repeat-mode"].connect (on_repeat_mode_changed);
            on_repeat_mode_changed ();
            player.notify["shuffle-mode"].connect (on_shuffle_mode_changed);
            on_shuffle_mode_changed ();

            Idle.add_once (() => {
                window.window_sidebar.notify["child-id"].connect (() => {
                    if (current_track_info != null) {
                        if (window.window_sidebar.child_id == current_track_info.id) {
                            track_detailed_button.remove_css_class ("flat");
                            return;
                        }
                    }
                    track_detailed_button.add_css_class ("flat");
                });

                window.window_sidebar.notify["is-shown"].connect (() => {
                    if (window.window_sidebar.is_shown == false) {
                        queue_show_button.add_css_class ("flat");
                        track_detailed_button.add_css_class ("flat");
                        flow_settings_button.add_css_class ("flat");
                    }
                });

                window.window_sidebar.child_changed.connect ((new_child) => {
                    // Check if PlayerQueue is shown (when migrated)
                    if (new_child != null && new_child.child_id == "queue") {
                        queue_show_button.remove_css_class ("flat");
                    } else {
                        queue_show_button.add_css_class ("flat");
                    }
                });

                window.window_sidebar.child_changed.connect ((new_child) => {
                    // Check if WaveSettings is shown (when migrated)
                    // WaveSettings uses child_id = "null:wave" in the old implementation
                    if (new_child != null && (new_child.child_id == "wave-settings" || new_child.child_id.has_suffix (":wave"))) {
                        flow_settings_button.remove_css_class ("flat");
                    } else {
                        flow_settings_button.add_css_class ("flat");
                    }
                });
            });

            block_widget (flow_settings_button, BlockReason.NOT_IMPLEMENTED);
            block_widget (fullscreen_button, BlockReason.NOT_IMPLEMENTED);
        }

        void on_playback_callback (double pos) {
            current_time_mark.label = sec2str ((int) pos, true);
            slider.set_value (pos);
        }

        void on_player_mode_inited () {
            var player = Application.tape_client.player;
            current_track_info = player.mode.get_current_track_info ();

            update_current_track_controls (current_track_info);

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
                clear ();
                return;
            }

            current_track_info = new_track;

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
        }

        void to_track_list () {
            shuffle_button.visible = true;
            flow_settings_button.visible = false;
            queue_show_button.visible = true;
        }

        void clear () {
            current_track_info = null;

            sensitive = false;

            dislike_button.visible = true;
            queue_show_button.visible = false;
            total_time_mark.label = "";

            window.hide_player_bar ();

            save_stack.clear ();
        }

        void on_shuffle_mode_changed () {
            var player = Application.tape_client.player;
            switch (player.shuffle_mode) {
                case Tape.ShuffleMode.ON:
                    shuffle_button.remove_css_class ("flat");
                    break;

                case Tape.ShuffleMode.OFF:
                    shuffle_button.add_css_class ("flat");
                    break;
            }
        }

        void on_repeat_mode_changed () {
            var player = Application.tape_client.player;
            switch (player.repeat_mode) {
                case Tape.RepeatMode.QUEUE:
                    repeat_button.set_icon_name ("media-playlist-repeat-symbolic");
                    repeat_button.remove_css_class ("flat");
                    break;

                case Tape.RepeatMode.ONE:
                    repeat_button.set_icon_name ("media-playlist-repeat-song-symbolic");
                    repeat_button.remove_css_class ("flat");
                    break;

                case Tape.RepeatMode.OFF:
                    repeat_button.set_icon_name ("media-playlist-repeat-symbolic");
                    repeat_button.add_css_class ("flat");
                    break;
            }
        }
    }

