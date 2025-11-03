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

public sealed class Cassette.PlayMarkGlobal : PlayMark {

    construct {
        var player = Application.tape_client.player;
        
        player.played.connect (() => {
            set_playing ();
        });

        player.paused.connect (() => {
            set_paused ();
        });

        player.track_stopped.connect (() => {
            set_stopped ();
        });
    }
}

