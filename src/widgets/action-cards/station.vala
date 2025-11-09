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
                // Make image/icon reasonably large for horizontal (shrinked) layout
                content_image.icon_size = Gtk.IconSize.LARGE;
                content_image.set_size_request (60, 60);
                // Ensure card has a sensible minimum width in shrinked layout
                set_size_request (220, -1);
            } else {
                if (!content_label.has_css_class ("title-2")) {
                    content_label.add_css_class ("title-2");
                    content_label.remove_css_class ("title-4");
                }
                // Keep icon large for vertical layout
                content_image.icon_size = Gtk.IconSize.LARGE;
                content_image.set_size_request (-1, -1);
                set_size_request (-1, -1);
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

        // Apply generic action-card styling
        add_css_class ("action-card");

        content_label.label = station_info.name;

        // Try to load image from full_image_url if available, otherwise use icon
        if (station_info.full_image_url != null && station_info.full_image_url != "") {
            load_image_from_url.begin ();
        } else {
            content_image.icon_name = station_info.icon.get_internal_icon_name (station_info.id.normal);
        }

        // Set accessible name for screen readers based on station name
        // Note: Using tooltip for accessibility as accessible-label property is not available
        tooltip_text = station_info.name;

        var gs = new Gtk.EventControllerMotion ();
        gs.enter.connect (on_motion_enter);
        gs.leave.connect (on_motion_leave);
        add_controller (gs);

        var yam_helper = Application.tape_client.yam_helper;
        if (yam_helper.me == null) {
            block_widget (this, BlockReason.NEED_AUTH);
        }

        var player = Application.tape_client.player;
        play_mark_context.triggered_not_playing.connect (on_play_mark_triggered);

        play_mark_context.notify.connect (on_play_mark_context_notify);

        clicked.connect (play_mark_context.trigger);
        play_mark_context.init_content (station_info.id.normal);
    }

    void on_motion_enter () {
        image_stack.visible_child_name = "play-mark";
    }

    void on_motion_leave () {
        if (!play_mark_context.is_current_playing) {
            image_stack.visible_child_name = "image";
        }
    }

    void on_play_mark_triggered () {
        var player = Application.tape_client.player;
        debug ("[TEST] Station card trigger: station_id=%s", station_info.id.normal);
        player.start_flow.begin (station_info.id.normal);
    }

    void on_play_mark_context_notify (ParamSpec pspec) {
        if (pspec.name == "is-current-playing") {
            is_current_playing = play_mark_context.is_current_playing;

            if (play_mark_context.is_current_playing) {
                image_stack.visible_child_name = "play-mark";
            } else {
                image_stack.visible_child_name = "image";
            }
        }
    }

    async void load_image_from_url () {
        if (station_info.full_image_url == null || station_info.full_image_url == "") {
            // Fallback to icon if URL is empty
            content_image.icon_name = station_info.icon.get_internal_icon_name (station_info.id.normal);
            return;
        }

        try {
            // Ensure URI has https:// scheme
            string full_uri = station_info.full_image_url;
            if (!full_uri.has_prefix ("http://") && !full_uri.has_prefix ("https://")) {
                full_uri = "https://" + full_uri;
            }

            // Fetch image using yam_helper
            var yam_helper = Application.tape_client.yam_helper;
            var image_bytes = yield yam_helper.load_image_data (full_uri);

            if (image_bytes != null) {
                try {
                    var loader = new Gdk.PixbufLoader ();
                    loader.write_bytes (image_bytes);
                    loader.close ();
                    var pixbuf = loader.get_pixbuf ();
                    if (pixbuf != null) {
                        content_image.set_from_paintable (Gdk.Texture.for_pixbuf (pixbuf));
                        // Ensure reasonable size in shrinked/normal layouts
                        if (is_shrinked) {
                            content_image.set_size_request (60, 60);
                        } else {
                            content_image.set_size_request (120, 120);
                        }
                        return;
                    }
                } catch (Error e) {
                    warning ("Failed to create pixbuf from image bytes: %s", e.message);
                }
            }
        } catch (Error e) {
            warning ("Failed to load image from URL %s: %s", station_info.full_image_url, e.message);
        }

        // Fallback to icon if image loading failed
        content_image.icon_name = station_info.icon.get_internal_icon_name (station_info.id.normal);
        if (is_shrinked) {
            content_image.set_size_request (60, 60);
        }
    }
}
