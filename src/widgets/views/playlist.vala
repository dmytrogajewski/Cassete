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
    [GtkTemplate (ui = "/space/rirusha/Cassette/ui/playlist-view.ui")]
    public class PlaylistView : CachiableView {
        [GtkChild]
        unowned SaveStack save_stack;
        [GtkChild]
        unowned Gtk.ScrolledWindow scrolled_window;
        [GtkChild]
        unowned CoverImage cover_image;
        [GtkChild]
        unowned Gtk.Label duration_label;
        [GtkChild]
        unowned Gtk.Label playlist_name_label;
        [GtkChild]
        unowned Gtk.Label playlist_desc_label;
        [GtkChild]
        unowned Gtk.Label playlist_status;
        [GtkChild]
        unowned Gtk.Button play_button;
        [GtkChild]
        unowned PlayMarkContext play_mark_context;
        [GtkChild]
        unowned LikeButton like_button;
        [GtkChild]
        unowned Gtk.Button save_button;
        [GtkChild]
        unowned Gtk.Button delete_button;
        [GtkChild]
        unowned Gtk.Button abort_button;
        [GtkChild]
        unowned Gtk.Button add_page_button;
        [GtkChild]
        unowned Gtk.Box main_box;
        [GtkChild]
        unowned PlaylistOptionsButton playlist_options_button;
        [GtkChild]
        unowned Gtk.Switch visibility_switch;
        [GtkChild]
        unowned Gtk.Button edit_button;
        [GtkChild]
        unowned Gtk.Button remove_button;

        public override bool can_refresh { get; default = true; }

        public string? uid { get; construct set; }
        public string kind { get; construct set; }

        public PlaylistView (string? uid, string kind) {
            Object (uid: uid, kind: kind);
        }

        construct {
            var yam_helper = Application.tape_client.yam_helper;

            visibility_switch.state_set.connect (on_switch_change);

            if (yam_helper.is_me (uid) && kind != "3") {
                visibility_switch.visible = true;
                remove_button.visible = true;

                remove_button.clicked.connect (() => {
                    var dialog = new Adw.AlertDialog (
                        _("Delete playlist?"),
                        _("Playlist '%s' will be permanently deleted.").printf (((YaMAPI.Playlist) object_info).title)
                    );

                    // Translators: cancel of deleting playlist
                    dialog.add_response ("cancel", _("Cancel"));
                    dialog.add_response ("delete", _("Delete"));

                    dialog.set_response_appearance ("delete", Adw.ResponseAppearance.DESTRUCTIVE);

                    dialog.default_response = "cancel";
                    dialog.close_response = "cancel";

                    dialog.response.connect ((dialog, response) => {
                        if (response == "delete") {
                            playlist_delete_async.begin ((obj, res) => {
                                if (playlist_delete_async.end (res)) {
                                    if (root_view != null) {
                                        root_view.backward ();
                                    }
                                    //
                                    // var app = (Application?) GLib.Application.get_default ();
                                    // var window = app?.active_window as Window;
                                    // window?.page_root.remove_page (object_info.oid);

                                    var app = (Application?) GLib.Application.get_default ();
                                    var window = app?.active_window as Window;
                                    window?.show_message (_("Playlist '%s' was deleted").printf (
                                        ((YaMAPI.Playlist) object_info).title
                                    ));
                                }
                            });
                        }
                    });

                    var app = (Application?) GLib.Application.get_default ();
                    var window = app?.active_window as Window;
                    dialog.present (window);
                });
            }

            track_list = new TrackList (scrolled_window.vadjustment);
            main_box.append (track_list);

            save_button.clicked.connect (() => {
                start_saving (true);
            });
            abort_button.clicked.connect (abort_saving);
            delete_button.clicked.connect (() => {
                uncache_playlist (true);
            });

            play_button.clicked.connect (play_mark_context.trigger);

            play_mark_context.triggered_not_playing.connect (start_playing);

            if (kind != "3" || (uid != null && uid != yam_helper.me.oid)) {
                add_page_button.visible = true;
                add_page_button.clicked.connect (() => {
                    var playlist_info = object_info as YaMAPI.Playlist;
                    //
                    // var app = (Application?) GLib.Application.get_default ();
                    // var window = app?.active_window as Window;
                    // if (window != null) {
                    //     window.page_root.add_custom_page ({
                    //         playlist_info.oid,
                    //         playlist_info.title,
                    //         "multimedia-player-symbolic",
                    //         typeof (PlaylistView).name (),
                    //         {uid, kind}
                    //     });
                    // }
                });
            }

            yam_helper.playlist_changed.connect ((new_playlist) => {
                if (new_playlist.oid == ((YaMAPI.Playlist) object_info).oid) {
                    object_info = new_playlist;
                    set_values ();
                }
            });

            block_widget (edit_button, BlockReason.NOT_IMPLEMENTED);
            block_widget (like_button, BlockReason.NOT_IMPLEMENTED);
        }

        public async bool playlist_delete_async () {
            bool success = false;

            var yam_helper = Application.tape_client.yam_helper;
            try {
                success = yield yam_helper.delete_playlist (kind);
                if (success) {
                    uncache_playlist (false);
                }
            } catch (Error e) {
                warning ("Failed to delete playlist: %s", e.message);
            }

            return success;
        }

        void set_values () {
            var playlist_info = object_info as YaMAPI.Playlist;
            var yam_helper = Application.tape_client.yam_helper;

            if (playlist_info.owner.uid == yam_helper.me.oid && playlist_info.kind != "3") {
                edit_button.visible = true;
            }

            visibility_switch.state_set.disconnect (on_switch_change);
            visibility_switch.active = playlist_info.is_public;
            visibility_switch.state_set.connect (on_switch_change);

            // Share action is handled by PlaylistOptionsButton, which is already set up

            playlist_name_label.label = playlist_info.title;

            if (playlist_info.description != null) {
                playlist_desc_label.label = playlist_info.description;
            }
            if (playlist_info.kind == "3") {
                like_button.visible = false;
            } else {
                like_button.likes_count = playlist_info.likes_count;

                if (playlist_info.uid == yam_helper.me.oid) {
                    like_button.visible = false;
                }
            }

            duration_label.label = ms2str (playlist_info.duration_ms, false);

            if (playlist_info.kind == "3") {
                if (playlist_info.owner.uid == yam_helper.me.oid) {
                    playlist_status.visible = false;
                } else {
                    playlist_status.label = _("Owner: %s").printf (playlist_info.owner.name);
                }
            } else {
                string format_string;
                if (playlist_info.owner.sex == "female") {
                    // Translators: %s is female person
                    format_string = C_ ("female person", "%s updated playlist %s");

                } else {
                    // Translators: %s is male person
                    format_string = C_ ("male person", "%s updated playlist %s");
                }

                playlist_status.label = format_string.printf (playlist_info.owner.name, get_when (playlist_info.modified));
            }

            var ptrack_list = playlist_info.get_track_list ();
            if (!track_list.compare_tracks (ptrack_list)) {
                track_list.set_tracks_default (ptrack_list, playlist_info);
            }

            if (playlist_info.track_count > 0) {
                play_button.sensitive = true;
            } else {
                play_button.sensitive = false;
            }

            like_button.init_content (playlist_info.oid);
            save_stack.init_content (playlist_info.oid);
            play_mark_context.init_content (playlist_info.oid);
            playlist_options_button.playlist_info = playlist_info;

            show_ready ();
        }

        public bool on_switch_change (Gtk.Switch sw, bool is_active) {
            on_switch_change_async.begin (is_active, (obj, res) => {
                YaMAPI.Playlist? playlist_info = on_switch_change_async.end (res);

                if (playlist_info == null) {
                    var app = (Application?) GLib.Application.get_default ();
                    var window = app?.active_window as Window;
                    window?.show_message (_("Can't change visibility of playlist"));
                    return;
                }

                visibility_switch.state_set.disconnect (on_switch_change);
                var app = (Application?) GLib.Application.get_default ();
                var window = app?.active_window as Window;
                if (playlist_info.is_public) {
                    window?.show_message (_("Playlist '%s' is public now").printf (playlist_info.title));
                    visibility_switch.active = true;
                } else {
                    window?.show_message (_("Playlist '%s' is private now").printf (playlist_info.title));
                    visibility_switch.active = false;
                }
                visibility_switch.state_set.connect (on_switch_change);
            });
            return false;
        }

        async YaMAPI.Playlist? on_switch_change_async (bool is_active) {
            YaMAPI.Playlist? playlist_info = null;

            var yam_helper = Application.tape_client.yam_helper;
            try {
                playlist_info = yield yam_helper.change_playlist_visibility (((YaMAPI.Playlist) object_info).kind, is_active);
            } catch (Error e) {
                warning ("Failed to change playlist visibility: %s", e.message);
            }

            return playlist_info;
        }

        public async override int try_load_from_web () {
            int code = 0;

            var yam_helper = Application.tape_client.yam_helper;
            try {
                object_info = yield yam_helper.get_playlist_info_old (uid, kind);
            } catch (ApiBase.BadStatusCodeError e) {
                code = e.code;
            } catch (Error e) {
                // Log other errors but don't fail
                warning ("API error: %s", e.message);
            }

            if (object_info != null) {
                set_values ();

                cover_image.init_content ((HasCover) this.object_info);
                cover_image.load_image.begin ();
                return -1;
            }
            return code;
        }

        public async override bool try_load_from_cache () {
            var yam_helper = Application.tape_client.yam_helper;
            var storager = Application.tape_client.cachier.storager;

            if (uid == null) {
                if (yam_helper.me.oid == null) {
                    return false;
                }
                uid = yam_helper.me.oid;
            }

            object_info = (YaMAPI.Playlist) (yield storager.load_object (typeof (YaMAPI.Playlist), @"$uid:$kind"));

            if (object_info != null) {
                set_values ();

                cover_image.init_content ((HasCover) this.object_info);
                cover_image.load_image.begin ();
                return true;
            }
            return false;
        }
    }
}

