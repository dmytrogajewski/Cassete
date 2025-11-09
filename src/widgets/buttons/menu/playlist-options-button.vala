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

public class Cassette.PlaylistOptionsButton : CustomMenuButton {

    public YaMAPI.Playlist playlist_info { get; set; }

    construct {
        // Tooltip provides accessible name for screen readers
        real_button.tooltip_text = _("Playlist options");

        var share_action = new GLib.SimpleAction ("share", null);
        share_action.activate.connect (() => {
            playlist_share (playlist_info);
        });
        actions.add_action (share_action);

        var add_to_queue_action = new GLib.SimpleAction ("add-to-queue", null);
        add_to_queue_action.activate.connect (() => {
            var player = Application.tape_client.player;
            var track_list = playlist_info.get_filtered_track_list (
                Application.app_settings.get_boolean ("explicit-visible"),
                Application.app_settings.get_boolean ("child-visible")
            );

            player.add_many (track_list);
        });
        actions.add_action (add_to_queue_action);

        var vibe_action = new GLib.SimpleAction ("my-vibe", null);
        vibe_action.activate.connect (() => {
            var player = Application.tape_client.player;
            player.start_flow.begin ("playlist:%s_%s".printf (playlist_info.uid, playlist_info.kind));
        });
        actions.add_action (vibe_action);
    }

    protected override string get_title_label () {
        return _("Playlist '%s'").printf (playlist_info.title);
    }

    protected override MenuItem[] get_popover_menu_items () {
        return {
            {_("My Vibe by playlist"), "actions.my-vibe", 0},
            {_("Add to queue"), "actions.add-to-queue", 1},
            {_("Share"), "actions.share", 1}
        };
    }

    protected override Gtk.Widget[] get_dialog_menu_widgets () {
        return {
            new ActionCardStation (new YaMAPI.Rotor.StationInfo () {
                id = new YaMAPI.Rotor.Id () {
                    type_ = "playlist",
                    tag = "%s_%s".printf (playlist_info.uid, playlist_info.kind)
                },
                name = _("My Vibe by playlist"),
                icon = new YaMAPI.Icon ()
            }) {
                is_shrinked = true
            }
        };
    }

    protected override MenuItem[] get_dialog_menu_items () {
        return {
            {_("Add to queue"), "actions.add-to-queue", 1},
            {_("Share"), "actions.share", 1}
        };
    }
}
