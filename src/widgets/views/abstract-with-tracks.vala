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
    public abstract class HasTracksView : BaseView {

        protected HasTracks object_info { get; set; }
        protected TrackList track_list { get; set; }

        ~HasTracksView () {
            track_list.clear_all ();
        }

        public virtual void start_playing () {
            var player = Application.tape_client.player;
            var track_list = object_info.get_filtered_track_list (
                Application.app_settings.get_boolean ("explicit-visible"),
                Application.app_settings.get_boolean ("child-visible")
            );

            player.start_track_list (
                track_list,
                get_context_type (object_info),
                object_info.oid,
                player.shuffle_mode == Tape.ShuffleMode.ON ? Random.int_range (0, track_list.size) : 0,
                get_context_description (object_info)
            );
        }
    }
}
