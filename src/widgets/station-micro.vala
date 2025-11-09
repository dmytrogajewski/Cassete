/*
 * Copyright (C) 2025
 * SPDX-License-Identifier: GPL-3.0-or-later
 */

using Tape;
using Tape.YaMAPI;

[GtkTemplate (ui = "/space/rirusha/Cassette/ui/station-micro.ui")]
public class Cassette.StationMicro : Adw.Bin {
    [GtkChild]
    unowned Gtk.Image station_image;
    [GtkChild]
    unowned Gtk.Label station_title;
    [GtkChild (name = "root_button")]
    unowned Gtk.Button root_button;
    [GtkChild]
    unowned Gtk.Box card_box;

    public BaseView? parent_view { get; set; }
    public YaMAPI.Rotor.StationInfo? station_info { get; construct; default = null; }

    public StationMicro (BaseView? parent_view, YaMAPI.Rotor.StationInfo? station_info) {
        Object (parent_view: parent_view, station_info: station_info);
    }

    public StationMicro.empty () {
        Object ();
    }

        construct {
            if (station_info != null) {
                // Hover/press highlight
                var hover = new Gtk.EventControllerMotion ();
                hover.enter.connect (on_hover_enter);
                hover.leave.connect (on_hover_leave);
                root_button.add_controller (hover);

                var press = new Gtk.GestureClick ();
                press.pressed.connect (on_press_pressed);
                press.released.connect (on_press_released);
                press.stopped.connect (on_press_stopped);
                root_button.add_controller (press);

                set_values ();
            } else {
                sensitive = false;
            }
        }

        void on_hover_enter () {
            card_box.add_css_class ("action-card-hover");
        }

        void on_hover_leave () {
            card_box.remove_css_class ("action-card-hover");
        }

        void on_press_pressed () {
            card_box.add_css_class ("action-card-active");
        }

        void on_press_released () {
            card_box.remove_css_class ("action-card-active");
        }

        void on_press_stopped () {
            card_box.remove_css_class ("action-card-active");
        }

        [GtkCallback]
        void on_clicked () {
            if (parent_view != null && parent_view.root_view != null) {
                parent_view.root_view.add_view (new StationsView ());
            }
        }

    void set_values () {
        if (station_info == null) return;

        station_title.label = station_info.name;

        // Load remote image if available
        if (station_info.full_image_url != null && station_info.full_image_url != "") {
            load_image_from_url.begin (station_info.full_image_url);
        } else {
            station_image.icon_name = station_info.icon.get_internal_icon_name (station_info.id.normal);
        }
    }

    async void load_image_from_url (string url) {
        try {
            string full_uri = url;
            if (!full_uri.has_prefix ("http://") && !full_uri.has_prefix ("https://")) {
                full_uri = "https://" + full_uri;
            }
            var bytes = yield Application.tape_client.yam_helper.load_image_data (full_uri);
            if (bytes != null) {
                try {
                    var loader = new Gdk.PixbufLoader ();
                    loader.write_bytes (bytes);
                    loader.close ();
                    var pixbuf = loader.get_pixbuf ();
                    if (pixbuf != null) {
                        station_image.set_from_paintable (Gdk.Texture.for_pixbuf (pixbuf));
                    }
                } catch (Error e) {
                    warning ("Failed to create texture from image bytes: %s", e.message);
                }
            }
        } catch (Error e) {
            warning ("Failed to load station image: %s", e.message);
        }
    }
}
