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
    public class LikeButton : CustomButton, Initable {

        protected string content_id { get; set; }
        public Tape.ContentType object_content_type { get; construct; }

        bool is_liked {
            get {
                return icon_name == "like-symbolic";
            }
            set {
                if (value) {
                    if (!is_liked && should_change_likes_count && likes_count != -1) {
                        likes_count++;
                    }

                    icon_name = "like-symbolic";
                    real_button.tooltip_text = _("Remove like");
                } else {
                    if (is_liked && should_change_likes_count && likes_count != -1) {
                        likes_count--;
                    }

                    icon_name = "not-like-symbolic";
                    real_button.tooltip_text = _("Set like");
                }

                should_change_likes_count = true;
            }
        }

        bool should_change_likes_count = false;

        int _likes_count = -1;
        public int likes_count {
            get {
                return _likes_count;
            }
            set {
                _likes_count = value;

                if (show_label) {
                    if (_likes_count > 0) {
                        label = prettify_num (_likes_count);
                    } else {
                        label = "";
                    }
                }
            }
        }

        public bool show_label { get; construct; default = true; }

        public LikeButton (Tape.ContentType object_content_type) {
            Object (object_content_type: object_content_type);
        }

        public LikeButton.without_label (Tape.ContentType object_content_type) {
            Object (object_content_type: object_content_type, show_label: false);
        }

        construct {
            valign = Gtk.Align.CENTER;
            halign = Gtk.Align.CENTER;

            // Tooltip provides accessible name for screen readers
            real_button.tooltip_text = _("Like");

            real_button.clicked.connect (like_dislike);

            var yam_helper = Application.tape_client.yam_helper;
            yam_helper.track_likes_start_change.connect (liked_start_change);
            yam_helper.track_likes_end_change.connect (liked_changed);
            yam_helper.track_dislikes_start_change.connect ((track_id) => {
                if (track_id == content_id) {
                    real_button.sensitive = false;
                }
            });
            yam_helper.track_dislikes_end_change.connect ((track_id) => {
                if (track_id == content_id) {
                    real_button.sensitive = true;
                }
            });

            // TODO: Connect to application state changes when available
            // application.application_state_changed.connect (application_state_changed);
        }

        public void init_content (string content_id) {
            this.content_id = content_id;
            check_liked ();

            // TODO: application_state_changed (application.application_state, application.application_state);
        }

        void check_liked () {
            if (content_id != null) {
                // TODO: Fix when HashModel properties are exposed in VAPI
                // var likes_handler = Application.tape_client.yam_helper.likes_handler;
                // For now, assume not liked - this will be updated when VAPI is regenerated
                // switch (object_content_type) {
                //     case Tape.ContentType.TRACK:
                //         is_liked = likes_handler.liked_tracks.contains (content_id);
                //         break;
                //     case Tape.ContentType.PLAYLIST:
                //         is_liked = likes_handler.liked_playlists.contains (content_id);
                //         break;
                //     case Tape.ContentType.ALBUM:
                //         is_liked = likes_handler.liked_albums.contains (content_id);
                //         break;
                //     default:
                //         is_liked = false;
                //         break;
                // }
                is_liked = false;
            }
        }

        // TODO: Connect to application state changes when available
        // void application_state_changed (ApplicationState new_state, ApplicationState old_state) {
        //     switch (new_state) {
        //         case ApplicationState.ONLINE:
        //             real_button.sensitive = true;
        //             check_liked ();
        //             break;

        //         case ApplicationState.OFFLINE:
        //             real_button.sensitive = false;
        //             break;

        //         default:
        //             break;
        //     }
        // }

        public void liked_start_change (string track_id) {
            if (content_id == null) {
                return;
            }
            if (track_id == content_id) {
                real_button.sensitive = false;
            }
        }

        public void liked_changed (string track_id, bool is_liked) {
            if (content_id == null) {
                return;
            }

            if (track_id == content_id) {
                this.is_liked = is_liked;
                real_button.sensitive = true;
            }
        }

        async void like_dislike () {
            assert (content_id != null);

            real_button.sensitive = false;

            // TODO: Implement when API methods are available
            //  var yam_helper = Application.tape_client.yam_helper;
            //  if (is_liked) {
            //      yield yam_helper.unlike (object_content_type, content_id);
            //  } else {
            //      yield yam_helper.like (object_content_type, content_id);
            //  }

            real_button.sensitive = true;
        }
    }
}

