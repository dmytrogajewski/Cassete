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
using Gee;

namespace Cassette {
    public class DislikeButton : CustomButton, Initable {

        protected string content_id { get; set; }
        public Tape.ContentType object_content_type { get; construct; default = Tape.ContentType.TRACK; }

        public bool is_disliked {
            get {
                return !real_button.has_css_class ("dim-label");
            }
            set {
                if (value) {
                    real_button.remove_css_class ("dim-label");
                    real_button.tooltip_text = _("Remove dislike");
                } else {
                    real_button.add_css_class ("dim-label");
                    real_button.tooltip_text = _("Set dislike");
                }
            }
        }

        public DislikeButton () {
            Object (object_content_type: Tape.ContentType.TRACK);
        }

        construct {
            valign = Gtk.Align.CENTER;
            halign = Gtk.Align.CENTER;

            // Tooltip provides accessible name for screen readers
            real_button.tooltip_text = _("Dislike");

            real_button.icon_name = "disliked-symbolic";
            real_button.add_css_class ("dim-label");
            real_button.clicked.connect (like_dislike);

            var yam_helper = Application.tape_client.yam_helper;
            yam_helper.track_dislikes_start_change.connect (disliked_start_change);
            yam_helper.track_dislikes_end_change.connect (disliked_changed);
            yam_helper.track_likes_start_change.connect ((track_id) => {
                if (track_id == content_id) {
                    real_button.sensitive = false;
                }
            });
            yam_helper.track_likes_end_change.connect ((track_id) => {
                if (track_id == content_id) {
                    real_button.sensitive = true;
                }
            });

            // TODO: Connect to application state changes when available
            // application.application_state_changed.connect (application_state_changed);
        }

        public void init_content (string content_id) {
            this.content_id = content_id;
            check_disliked ();

            // TODO: application_state_changed (application.application_state, application.application_state);
        }

        void check_disliked () {
            if (content_id != null) {
                // TODO: Fix when HashModel properties are exposed in VAPI
                // var likes_handler = Application.tape_client.yam_helper.likes_handler;
                // Only tracks can be disliked in current API
                // if (object_content_type == Tape.ContentType.TRACK) {
                //     is_disliked = likes_handler.disliked_tracks.contains (content_id);
                // } else {
                //     is_disliked = false;
                // }
                is_disliked = false;
            }
        }

        // TODO: Connect to application state changes when available
        // void application_state_changed (ApplicationState new_state, ApplicationState old_state) {
        //     switch (new_state) {
        //         case ApplicationState.ONLINE:
        //             real_button.sensitive = true;
        //             check_disliked ();
        //             break;

        //         case ApplicationState.OFFLINE:
        //             real_button.sensitive = false;
        //             break;

        //         default:
        //             break;
        //     }
        // }

        public void disliked_start_change (string track_id) {
            if (content_id == null) {
                return;
            }
            if (track_id == content_id) {
                real_button.sensitive = false;
            }
        }

        public void disliked_changed (string track_id, bool is_disliked) {
            if (content_id == null) {
                return;
            }

            if (track_id == content_id) {
                this.is_disliked = is_disliked;
                real_button.sensitive = true;

                var player = Application.tape_client.player;
                if (is_disliked && player.mode.get_current_track_info ().id == track_id) {
                    player.next.begin ();
                }
            }
        }

        async void like_dislike () {
            assert (content_id != null);

            real_button.sensitive = false;

            // TODO: Implement when API methods are available
            //  var yam_helper = Application.tape_client.yam_helper;
            //  if (is_disliked) {
            //      yield yam_helper.undislike (object_content_type, content_id);
            //  } else {
            //      yield yam_helper.dislike (object_content_type, content_id);
            //  }

            real_button.sensitive = true;
        }
    }
}

