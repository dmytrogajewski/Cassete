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
using Gee;

[GtkTemplate (ui = "/space/rirusha/Cassette/ui/player-queue.ui")]
public class Cassette.PlayerQueue : SidebarChildBin {

    [GtkChild]
    unowned Gtk.ScrolledWindow scrolled_window;

    TrackList track_list;

    construct {
        child_id = "queue";

        track_list = new TrackList (scrolled_window.vadjustment) {
            margin_top = 12,
            margin_bottom = 12,
            margin_start = 12,
            margin_end = 12
        };
        scrolled_window.child = track_list;

        var player = Application.tape_client.player;
        player.queue_changed.connect (update_queue);
        update_queue (
            player.mode.queue,
            player.mode.context_type,
            player.mode.context_id,
            player.mode.current_index,
            player.mode.context_description
        );
    }

    public void update_queue (
        ArrayList<YaMAPI.Track> queue,
        string context_type,
        string? context_id,
        int current_index,
        string? context_description
    ) {
        track_list.set_tracks_as_queue (queue);
        Idle.add (() => {
            track_list.move_to (current_index, queue.size);
            return Source.REMOVE;
        });

        switch (context_type) {
            case "playlist":
                subtitle = _("Playlist \"%s\"").printf (context_description ?? "");
                break;

            case "album":
                subtitle = _("Album \"%s\"").printf (context_description ?? "");
                break;

            case "search":
                subtitle = _("By search results \"%s\"").printf (context_description ?? "");
                break;

            default:
                subtitle = _("Track list");
                break;
        }
    }
}
