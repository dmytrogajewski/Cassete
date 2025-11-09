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

public sealed class Cassette.PlayMarkTrack : PlayMarkDefault {

    construct {
        react_as_track = true;
    }

    protected override bool is_playing_now () {
        var player = Application.tape_client.player;
        var current_track = player.mode.get_current_track_info ();

        if (current_track != null) {
            if (current_track.id == content_id) {
                return true;
            }
        }

        return false;
    }
}
