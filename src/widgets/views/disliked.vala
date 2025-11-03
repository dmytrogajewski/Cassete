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

    [GtkTemplate (ui = "/space/rirusha/Cassette/ui/disliked-tracks-view.ui")]
    public class DislikedTracksView : HasTracksView {
        [GtkChild]
        unowned Gtk.Box main_box;
        [GtkChild]
        unowned Gtk.ScrolledWindow scrolled_window;

        public override bool can_refresh { get; default = true; }

        YaMAPI.TrackHeap? _track_list = null;

        public string? uid { get; construct set; }
        public string kind { get; construct set; }

        public DislikedTracksView () {
            Object ();
        }

        construct {
            track_list = new TrackList (scrolled_window.vadjustment);
            main_box.append (track_list);
        }

        void set_values () {
            track_list.set_tracks_disliked (_track_list.tracks, _track_list);

            show_ready ();
        }

        public async override int try_load_from_web () {
            var yam_helper = Application.tape_client.yam_helper;
            try {
                _track_list = yield yam_helper.get_disliked_tracks ();
            } catch (ApiBase.BadStatusCodeError e) {
                // Ignore bad status codes - API may be temporarily unavailable
            } catch (Error e) {
                // Log other errors but don't fail
                warning ("API error: %s", e.message);
            }

            if (_track_list != null) {
                set_values ();
                return -1;
            }
            
            return 0;
        }

        public async override bool try_load_from_cache () {
            return false;
        }
    }
}

