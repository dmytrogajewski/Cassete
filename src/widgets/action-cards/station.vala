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

[GtkTemplate (ui = "/space/rirusha/Cassette/ui/action-card-station.ui")]
public class Cassette.ActionCardStation : ActionCardCustom {

    [GtkChild]
    unowned Gtk.Box content_box;
    [GtkChild]
    unowned Gtk.Stack image_stack;
    [GtkChild]
    unowned PlayMarkContext play_mark_context;
    [GtkChild]
    unowned Gtk.Image content_image;
    [GtkChild]
    unowned Gtk.Label content_label;

    protected override string css_class_name_playing_default {
        owned get {
            return "station-card-playing";
        }
    }

    protected override string css_class_name_playing_hover {
        owned get {
            return "station-card-playing-hover";
        }
    }

    protected override string css_class_name_playing_active {
        owned get {
            return "station-card-playing-active";
        }
    }

    Gtk.Orientation orientation {
        get {
            return content_box.orientation;
        }
        set {
            content_box.orientation = value;
        }
    }

    bool _is_shrinked = false;
    public bool is_shrinked {
        get {
            return _is_shrinked;
        }
        set {
            _is_shrinked = value;

            orientation = value ? Gtk.Orientation.HORIZONTAL : Gtk.Orientation.VERTICAL;
            content_box.halign = value? Gtk.Align.START : Gtk.Align.CENTER;

            if (value) {
                if (content_label.has_css_class ("title-2")) {
                    content_label.remove_css_class ("title-2");
                    content_label.add_css_class ("title-4");
                }
                // Make icon smaller for horizontal (shrinked) layout
                content_image.icon_size = Gtk.IconSize.NORMAL;
            } else {
                if (!content_label.has_css_class ("title-2")) {
                    content_label.add_css_class ("title-2");
                    content_label.remove_css_class ("title-4");
                }
                // Keep icon large for vertical layout
                content_image.icon_size = Gtk.IconSize.LARGE;
            }
        }
    }

    public YaMAPI.Rotor.StationInfo station_info { get; construct; }

    public ActionCardStation (
        YaMAPI.Rotor.StationInfo station_info
    ) {
        Object (
            station_info: station_info
        );
    }

    public ActionCardStation.shrinked (
        YaMAPI.Rotor.StationInfo station_info
    ) {
        Object (
            station_info: station_info,
            is_shrinked: true
        );
    }

    construct {
        hexpand = false;
        vexpand = false;

        content_label.label = station_info.name;
        content_image.icon_name = station_info.icon.get_internal_icon_name (station_info.id.normal);

        // Set accessible name for screen readers based on station name
        set_property ("accessible-label", station_info.name);

        var gs = new Gtk.EventControllerMotion ();
        gs.enter.connect (() => {
            image_stack.visible_child_name = "play-mark";
        });
        gs.leave.connect (() => {
            if (!play_mark_context.is_current_playing) {
                image_stack.visible_child_name = "image";
            }
        });
        add_controller (gs);

        var yam_helper = Application.tape_client.yam_helper;
        if (yam_helper.me == null) {
            block_widget (this, BlockReason.NEED_AUTH);
        }

        var player = Application.tape_client.player;
        play_mark_context.triggered_not_playing.connect (() => {
            player.start_flow.begin (station_info.id.normal);
        });

        play_mark_context.notify["is-current-playing"].connect (() => {
            is_current_playing = play_mark_context.is_current_playing;

            if (play_mark_context.is_current_playing) {
                image_stack.visible_child_name = "play-mark";
            } else {
                image_stack.visible_child_name = "image";
            }
        });

        clicked.connect (play_mark_context.trigger);
        play_mark_context.init_content (station_info.id.normal);
    }
}

