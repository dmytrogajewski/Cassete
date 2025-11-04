/*
 * Copyright (C) 2025
 * SPDX-License-Identifier: GPL-3.0-or-later
 */

using Tape;
using Tape.YaMAPI;

[GtkTemplate (ui = "/space/rirusha/Cassette/ui/action-card-wide.ui")]
public class Cassette.ActionCardWide : ActionCardCustom {

    [GtkChild]
    unowned Gtk.Box content_box;
    [GtkChild]
    unowned CoverImage cover_image;
    [GtkChild]
    unowned Gtk.Label title_label;
    [GtkChild]
    unowned Gtk.Label subtitle_label;

    public string title { get; set; default = ""; }
    public string? subtitle { get; set; default = null; }
    public HasCover? cover_object { get; construct; default = null; }

    public ActionCardWide (HasCover? cover_object, string title, string? subtitle = null) {
        Object (cover_object: cover_object, title: title, subtitle: subtitle);
    }

    construct {
        // Base visual class for Reactable hover/active
        add_css_class ("action-card");

        title_label.label = title;
        title_label.halign = Gtk.Align.START;

        if (subtitle != null && subtitle != "") {
            subtitle_label.label = subtitle;
            subtitle_label.visible = true;
        } else {
            subtitle_label.visible = false;
        }

        if (cover_object != null) {
            cover_image.cover_size = (int) CoverSize.SMALL;
            cover_image.image_widget_size = 72;
            cover_image.init_content (cover_object);
            cover_image.load_image.begin ();
        }
    }

    public void update_subtitle_label (string? value) {
        subtitle = value;
        if (subtitle != null && subtitle != "") {
            subtitle_label.label = subtitle;
            subtitle_label.visible = true;
        } else {
            subtitle_label.visible = false;
        }
    }

    public void update_title_label (string value) {
        title = value;
        title_label.label = title ?? "";
        title_label.visible = title != null && title != "";
    }
}


