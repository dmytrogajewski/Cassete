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
using GLib;

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

        YaMAPI.Playlist? initial_playlist = null;

        public PlaylistView (string? uid, string kind) {
            Object (uid: uid, kind: kind);
            debug ("[TEST] PlaylistView constructed: uid=%s kind=%s", uid ?? "<null>", kind);
        }

        public PlaylistView.with_playlist (YaMAPI.Playlist playlist) {
            string? resolved_uid = playlist.uid;

            if (resolved_uid == null || resolved_uid == "") {
                if (playlist.owner != null && playlist.owner.uid != null && playlist.owner.uid != "") {
                    resolved_uid = Cassette.Application.tape_client.yam_helper.me.uid;
                } else {
                    resolved_uid = Cassette.Application.tape_client.yam_helper.me.uid;
                }
            }

            string resolved_kind = playlist.kind ?? "recent";

            Object (uid: resolved_uid, kind: resolved_kind);

            initial_playlist = playlist;
            debug ("[TEST] PlaylistView.with_playlist constructed: title=%s kind=%s tracks=%d", playlist.title ?? "<null>", resolved_kind, playlist.track_count);
        }

        construct {
            debug ("[TEST] PlaylistView construct start: uid=%s kind=%s initial_playlist=%s",
                   uid ?? "<null>", kind, initial_playlist != null ? "true" : "false");
            var yam_helper = Application.tape_client.yam_helper;

            visibility_switch.state_set.connect (on_switch_change);

            if (yam_helper.is_me (uid) && kind != "3") {
                visibility_switch.visible = true;
                remove_button.visible = true;
            }

            track_list = new TrackList (scrolled_window.vadjustment);
            main_box.append (track_list);

            play_mark_context.triggered_not_playing.connect (start_playing);

            if (kind != "3" || (uid != null && uid != yam_helper.me.oid)) {
                add_page_button.visible = true;
            }

            yam_helper.playlist_changed.connect (on_playlist_changed);

            block_widget (edit_button, BlockReason.NOT_IMPLEMENTED);
            block_widget (like_button, BlockReason.NOT_IMPLEMENTED);

            if (initial_playlist != null) {
                object_info = initial_playlist;
                set_values ();
                cover_image.init_content ((HasCover) object_info);
                cover_image.load_image.begin ();
                show_ready ();
                debug ("[TEST] PlaylistView initial playlist applied: uid=%s kind=%s", uid ?? "<null>", kind);
            }
        }

        [GtkCallback]
        void on_back_button_clicked () {
            if (root_view != null) {
                debug ("[TEST] PlaylistView back button clicked");
                root_view.backward ();
            }
        }

        [GtkCallback]
        void on_remove_button_clicked () {
            var dialog = new Adw.AlertDialog (
                _("Delete playlist?"),
                _("Playlist '%s' will be permanently deleted.").printf (((YaMAPI.Playlist) object_info).title)
            );
            debug ("[TEST] PlaylistView remove button clicked: playlist=%s", ((YaMAPI.Playlist) object_info).title ?? "<null>");

            // Translators: cancel of deleting playlist
            dialog.add_response ("cancel", _("Cancel"));
            dialog.add_response ("delete", _("Delete"));

            dialog.set_response_appearance ("delete", Adw.ResponseAppearance.DESTRUCTIVE);

            dialog.default_response = "cancel";
            dialog.close_response = "cancel";

            dialog.response.connect (on_delete_dialog_response);

            var app = (Application?) GLib.Application.get_default ();
            var window = app?.active_window as Window;
            dialog.present (window);
        }

        void on_delete_dialog_response (Adw.AlertDialog dialog, string response) {
            if (response == "delete") {
                debug ("[TEST] PlaylistView delete confirmed");
                playlist_delete_async.begin (on_playlist_delete_async_complete);
            } else {
                debug ("[TEST] PlaylistView delete cancelled");
            }
        }

        void on_playlist_delete_async_complete (Object? obj, AsyncResult res) {
            if (playlist_delete_async.end (res)) {
                debug ("[TEST] PlaylistView delete completed");
                if (root_view != null) {
                    root_view.backward ();
                }

                var app = (Application?) GLib.Application.get_default ();
                var window = app?.active_window as Window;
                window?.show_message (_("Playlist '%s' was deleted").printf (
                    ((YaMAPI.Playlist) object_info).title
                ));
            }
        }

        [GtkCallback]
        void on_save_button_clicked () {
            start_saving (true);
            debug ("[TEST] PlaylistView save button clicked");
        }

        [GtkCallback]
        void on_delete_button_clicked () {
            uncache_playlist (true);
            debug ("[TEST] PlaylistView delete from cache clicked");
        }

        [GtkCallback]
        void on_add_page_button_clicked () {
            var playlist_info = object_info as YaMAPI.Playlist;
            var app = (Application?) GLib.Application.get_default ();
            var window = app?.active_window as Window;

            if (playlist_info == null) {
                window?.show_message (_("Playlist data is not loaded yet"));
                debug ("[TEST] PlaylistView add page ignored: playlist_info is null");
                return;
            }

            string playlist_uid = playlist_info.uid ?? uid ?? "";
            string playlist_kind = playlist_info.kind ?? kind;

            if (playlist_uid == "" || playlist_kind == "") {
                window?.show_message (_("Unable to add playlist to custom pages"));
                debug ("[TEST] PlaylistView add page failed: uid or kind missing");
                return;
            }

            var page_info = new PageInfo ();
            page_info.id = @"playlist:%s:%s".printf (playlist_uid, playlist_kind);
            page_info.title = playlist_info.title ?? _("Playlist");
            page_info.icon_name = "audio-x-generic-symbolic";
            page_info.view_type_name = typeof (PlaylistView).name ();
            page_info.args = { playlist_uid, playlist_kind };

            CustomPagesStore.upsert (page_info);
            window?.show_message (_("Playlist added to custom pages"));
            debug ("[TEST] PlaylistView add page completed: id=%s", page_info.id);
        }

        [GtkCallback]
        void on_play_button_clicked () {
            play_mark_context.trigger ();
            debug ("[TEST] PlaylistView play button clicked");
        }

        [GtkCallback]
        void on_abort_button_clicked () {
            abort_saving ();
            debug ("[TEST] PlaylistView abort saving clicked");
        }

        void on_playlist_changed (YaMAPI.Playlist new_playlist) {
            if (new_playlist.oid == ((YaMAPI.Playlist) object_info).oid) {
                object_info = new_playlist;
                set_values ();
                debug ("[TEST] PlaylistView playlist changed signal handled: oid=%s", new_playlist.oid);
            }
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
            var playlist_info = PlaylistGuards.ensure_playlist_info (object_info);

            if (playlist_info == null) {
                return;
            }
            var yam_helper = Application.tape_client.yam_helper;

            if (playlist_info.owner.uid == yam_helper.me.oid && playlist_info.kind != "3") {
                edit_button.visible = true;
            }

            visibility_switch.state_set.disconnect (on_switch_change);
            visibility_switch.active = playlist_info.is_public;
            visibility_switch.state_set.connect (on_switch_change);
            debug ("[TEST] PlaylistView visibility updated: is_public=%s", playlist_info.is_public.to_string ());

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

                playlist_status.label = format_string.printf (
                    playlist_info.owner.name, get_when (playlist_info.modified));
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
            debug ("[TEST] PlaylistView set_values applied: tracks=%d is_public=%s", playlist_info.track_count, playlist_info.is_public.to_string ());

            like_button.init_content (playlist_info.oid);
            save_stack.init_content (playlist_info.oid);
            play_mark_context.init_content (playlist_info.oid);
            playlist_options_button.playlist_info = playlist_info;

            show_ready ();
        }

        public bool on_switch_change (Gtk.Switch sw, bool is_active) {
            on_switch_change_async.begin (is_active, on_switch_change_async_complete);
            debug ("[TEST] PlaylistView visibility toggle clicked: new_state=%s", is_active.to_string ());
            return false;
        }

        void on_switch_change_async_complete (Object? obj, AsyncResult res) {
            YaMAPI.Playlist? playlist_info = on_switch_change_async.end (res);

            if (playlist_info == null) {
                var app = (Application?) GLib.Application.get_default ();
                var window = app?.active_window as Window;
                window?.show_message (_("Can't change visibility of playlist"));
                debug ("[TEST] PlaylistView visibility change failed");
                return;
            }

            visibility_switch.state_set.disconnect (on_switch_change);
            var app = (Application?) GLib.Application.get_default ();
            var window = app?.active_window as Window;
            if (playlist_info.is_public) {
                window?.show_message (_("Playlist '%s' is public now").printf (playlist_info.title));
                visibility_switch.active = true;
                debug ("[TEST] PlaylistView visibility set to public");
            } else {
                window?.show_message (_("Playlist '%s' is private now").printf (playlist_info.title));
                visibility_switch.active = false;
                debug ("[TEST] PlaylistView visibility set to private");
            }
            visibility_switch.state_set.connect (on_switch_change);
        }

        async YaMAPI.Playlist? on_switch_change_async (bool is_active) {
            YaMAPI.Playlist? playlist_info = null;

            var yam_helper = Application.tape_client.yam_helper;
            try {
                playlist_info = yield yam_helper.change_playlist_visibility (
                    ((YaMAPI.Playlist) object_info).kind, is_active);
            } catch (Error e) {
                warning ("Failed to change playlist visibility: %s", e.message);
                debug ("[TEST] PlaylistView visibility change exception: %s", e.message);
            }

            debug ("[TEST] PlaylistView visibility change async completed: playlist=%s", playlist_info != null ? playlist_info.title : "<null>");
            return playlist_info;
        }

        public async override void first_show () {
            if (initial_playlist != null) {
                check_cache ();
                return;
            }

            yield base.first_show ();
            debug ("[TEST] PlaylistView first_show without preload");
        }

        public async override int try_load_from_web () {
            int code = 0;

            if (initial_playlist != null) {
                return -1;
            }

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
            if (initial_playlist != null) {
                return false;
            }

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
