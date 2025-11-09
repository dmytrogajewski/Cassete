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
    [GtkTemplate (ui = "/space/rirusha/Cassette/ui/album-view.ui")]
    public class AlbumView : BaseView {
        [GtkChild]
        unowned Gtk.ScrolledWindow scrolled_window;
        [GtkChild]
        unowned CoverImage cover_image;
        [GtkChild]
        unowned Gtk.Label duration_label;
        [GtkChild]
        unowned Gtk.Label album_name_label;
        [GtkChild]
        unowned Gtk.Label album_artist_label;
        [GtkChild]
        unowned Gtk.Label album_year_label;
        [GtkChild]
        unowned Gtk.Label album_status;
        [GtkChild]
        unowned PlayMarkContext play_mark_context;
        [GtkChild]
        unowned LikeButton like_button;
        [GtkChild]
        unowned Gtk.Box main_box;

        public override bool can_refresh { get; default = true; }

        YaMAPI.Album? album_info = null;
        TrackList track_list;

        public string album_id { get; construct set; }

        public AlbumView (string album_id) {
            Object (album_id: album_id);
        }

        construct {
            track_list = new TrackList (scrolled_window.vadjustment);
            main_box.append (track_list);

            play_mark_context.triggered_not_playing.connect (start_playing);
        }

        [GtkCallback]
        void on_back_button_clicked () {
            if (root_view != null) {
                debug ("[TEST] AlbumView back button clicked");
                root_view.backward ();
            }
        }

        [GtkCallback]
        void on_play_button_clicked () {
            play_mark_context.trigger ();
            debug ("[TEST] AlbumView play button clicked");
        }

        void start_playing () {
            var player = Application.tape_client.player;
            var track_list = get_album_track_list ();
            debug ("[TEST] AlbumView start playing: tracks=%d", track_list.size);

            player.start_track_list (
                track_list,
                "album",
                album_info != null ? album_info.oid : null,
                player.shuffle_mode == Tape.ShuffleMode.ON ? Random.int_range (0, track_list.size) : 0,
                album_info != null ? album_info.title : null
            );
        }

        Gee.ArrayList<YaMAPI.Track> get_album_track_list () {
            var out_track_list = new Gee.ArrayList<YaMAPI.Track> ();

            if (album_info == null) {
                return out_track_list;
            }

            foreach (var volume in album_info.volumes) {
                foreach (var track in volume) {
                    if (track.available &&
                        ((!track.is_explicit || Application.app_settings.get_boolean ("explicit-visible")) &&
                         (!track.is_suitable_for_children || Application.app_settings.get_boolean ("child-visible")))) {
                        out_track_list.add (track);
                    }
                }
            }

            return out_track_list;
        }

        void set_values () {
            if (album_info == null) {
                debug ("[TEST] AlbumView set_values called with null album");
                return;
            }

            album_name_label.label = album_info.title;

            if (album_info.artists.size > 0) {
                var artist_names = new string[album_info.artists.size];
                for (int i = 0; i < artist_names.length; i++) {
                    artist_names[i] = album_info.artists[i].name;
                }
                album_artist_label.label = string.joinv (", ", artist_names);
            } else {
                album_artist_label.label = _("Unknown Artist");
            }

            if (album_info.year > 0) {
                album_year_label.label = album_info.year.to_string ();
            } else {
                album_year_label.label = "";
            }

            duration_label.label = ms2str (album_info.duration_ms, false);

            if (album_info.description != null) {
                album_status.label = album_info.description;
                album_status.visible = true;
            } else {
                album_status.visible = false;
            }

            var ptrack_list = get_album_track_list ();
            if (!track_list.compare_tracks (ptrack_list)) {
                // Create a temporary HasTracks wrapper for Album
                // Note: Album doesn't implement HasTracks, so we create a minimal wrapper
                // This is a workaround until Album implements HasTracks interface
                var track_heap = new YaMAPI.TrackHeap ();
                track_heap.tracks = ptrack_list;
                track_list.set_tracks_base (ptrack_list, track_heap);
            }

            if (album_info.track_count > 0) {
                // play_button.sensitive = true; // This line is removed as per the edit hint
            } else {
                // play_button.sensitive = false; // This line is removed as per the edit hint
            }

            like_button.init_content (album_info.oid);
            play_mark_context.init_content (album_info.oid);

            show_ready ();
            debug ("[TEST] AlbumView set_values applied: track_count=%d title=%s",
                   album_info.track_count,
                   album_info.title ?? "<null>");
        }

        public async override int try_load_from_web () {
            int code = 0;

            var yam_helper = Application.tape_client.yam_helper;
            try {
                album_info = yield yam_helper.get_album_info (album_id);
            } catch (GLib.Error e) {
                if (e is ApiBase.BadStatusCodeError) {
                    var bad_status = (ApiBase.BadStatusCodeError) e;
                    code = bad_status.code;
                    debug ("[TEST] AlbumView load failed: status=%d", code);
                } else {
                    warning ("API error: %s", e.message);
                    debug ("[TEST] AlbumView load failed: error=%s", e.message);
                }
            }

            if (album_info != null) {
                set_values ();

                cover_image.init_content ((HasCover) album_info);
                cover_image.load_image.begin ();
                debug ("[TEST] AlbumView load succeeded: album_id=%s", album_id);
                return -1;
            }
            debug ("[TEST] AlbumView load returned null");
            return code;
        }

        public async override bool try_load_from_cache () {
            var storager = Application.tape_client.cachier.storager;

            album_info = (YaMAPI.Album) (yield storager.load_object (typeof (YaMAPI.Album), album_id));

            if (album_info != null) {
                set_values ();

                cover_image.init_content ((HasCover) album_info);
                cover_image.load_image.begin ();
            debug ("[TEST] AlbumView loaded from cache: album_id=%s", album_id);
                return true;
            }
        debug ("[TEST] AlbumView cache miss: album_id=%s", album_id);
            return false;
        }
    }
}
