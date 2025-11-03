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

public sealed class Cassette.PlayMarkContext : PlayMarkDefault {

    public string context_type { get; construct set; }

    protected override bool is_playing_now () {
        assert (context_type != null);

        var player = Application.tape_client.player;
        return player.mode.context_id == content_id && player.mode.context_type == context_type;
    }
}

