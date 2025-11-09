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

[GtkTemplate (ui = "/space/rirusha/Cassette/ui/cover-image.ui")]
public sealed class Cassette.CoverImage : Gtk.Frame {

    [GtkChild]
    unowned Gtk.Image placeholder_image;
    [GtkChild]
    unowned Gtk.Stack stack;

    public int cover_size { get; set; default = CoverSize.BIG; }

    public HasCover yam_object { get; private set; }

    /**
     * Easy way to set both width and height of the cover widget.
     */
    public int image_widget_size { get; set; }

    construct {
        notify.connect (on_cover_image_notify);

        // Ensure initial state is set correctly
        if (cover_size == 0) {
            cover_size = CoverSize.BIG;
        }
    }

    void on_cover_image_notify (ParamSpec pspec) {
        if (pspec.name == "cover-size") {
            update_cover_size ();
        }
    }

    void update_cover_size () {
        // Handle initial state or invalid values gracefully
        if (cover_size == 0) {
            cover_size = CoverSize.BIG;
            return;
        }

        switch (cover_size) {
            case CoverSize.SMALL:
                placeholder_image.icon_size = Gtk.IconSize.NORMAL;
                image_widget_size = 60;
                add_css_class ("small-border-radius");
                break;

            case CoverSize.BIG:
                placeholder_image.icon_size = Gtk.IconSize.LARGE;
                image_widget_size = 200;
                remove_css_class ("small-border-radius");
                break;

            default:
                // Unknown value, default to BIG
                cover_size = CoverSize.BIG;
                break;
        }
    }

    public void init_content (HasCover yam_object) {
        this.yam_object = yam_object;
        add_css_class ("card");
    }

    public void clear () {
        yam_object = null;
        remove_css_class ("card");
    }

    public async void load_image () {
        assert (yam_object != null);

        Gdk.Pixbuf? pixbuf_buffer = null;

        debug ("[CoverImage] load_image start: type=%s size=%d", yam_object.get_type ().name (), (int) cover_size);
        var image_bytes = yield Cachier.get_image (yam_object, (int) cover_size);
        if (image_bytes != null) {
            debug ("[CoverImage] cache hit: %zu bytes", image_bytes.get_size ());
        } else {
            debug ("[CoverImage] cache miss, trying fallback network load");
        }
        // Fallback: try to load directly from network if cache missed
        if (image_bytes == null) {
            try {
                var uris = yam_object.get_cover_items_by_size ((int) cover_size);
                debug ("[CoverImage] got %d cover uris", uris.size);
                foreach (var uri in uris) {
                    if (uri == null) continue;
                    string full_uri = uri;
                    if (!full_uri.has_prefix ("http://") && !full_uri.has_prefix ("https://")) {
                        full_uri = "https://" + full_uri;
                    }
                    debug ("[CoverImage] fetching %s", full_uri);
                    image_bytes = yield Application.tape_client.yam_helper.load_image_data (full_uri);
                    if (image_bytes != null) {
                        debug ("[CoverImage] network fetch ok: %zu bytes", image_bytes.get_size ());
                        break;
                    }
                }
            } catch (Error e) {
                warning ("CoverImage fallback load failed: %s", e.message);
            }
        }
        if (image_bytes != null) {
            try {
                var loader = new Gdk.PixbufLoader ();
                loader.write_bytes (image_bytes);
                loader.close ();
                pixbuf_buffer = loader.get_pixbuf ();
            } catch (Error e) {
                warning ("Failed to create pixbuf from image bytes: %s", e.message);
            }
        }

        if (pixbuf_buffer != null) {
            var real_image = new Gtk.Image ();
            real_image.set_from_paintable (Gdk.Texture.for_pixbuf (pixbuf_buffer));

            bind_property (
                "image-widget-size",
                real_image,
                "width-request",
                GLib.BindingFlags.SYNC_CREATE
            );
            bind_property (
                "image-widget-size",
                real_image,
                "height-request",
                GLib.BindingFlags.SYNC_CREATE
            );
            bind_property (
                "image-widget-size",
                real_image,
                "pixel-size",
                GLib.BindingFlags.SYNC_CREATE
            );

            stack.add_child (real_image);

            stack.visible_child = real_image;
        } else {
            debug ("[CoverImage] no pixbuf, leaving placeholder");
        }
    }
}
