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

[GtkTemplate (ui = "/space/rirusha/Cassette/ui/menu-dialog.ui")]
public class Cassette.MenuDialog : Adw.Dialog {

    [GtkChild]
    unowned ShrinkableBin shrinkable_bin;
    [GtkChild]
    unowned Adw.Clamp title_clamp;
    [GtkChild]
    unowned Gtk.ScrolledWindow scrolled_window;
    [GtkChild]
    unowned Adw.Clamp menu_clamp;

    public Gtk.Widget? menu_widget {
        get {
            return menu_clamp.child;
        }
        set {
            menu_clamp.child = value;
        }
    }

    public Gtk.Widget? title_widget {
        get {
            return title_clamp.child;
        }
        set {
            if (value is Gtk.Button) {
                value.add_css_class ("button-standart-padding");
                value.add_css_class ("flat");
                ((Gtk.Button) value).clicked.connect (on_title_button_clicked);
            } else {
                value.margin_bottom = 5;
                value.margin_top = 5;
                value.margin_start = 5;
                value.margin_end = 5;
            }

            title_clamp.child = value;
        }
    }

    construct {
        shrinkable_bin.notify.connect (on_shrinkable_bin_notify);
        update_scrolled ();
    }

    void on_shrinkable_bin_notify (ParamSpec pspec) {
        if (pspec.name == "root-window-is-shrinked") {
            update_scrolled ();
        }
    }

    void update_scrolled () {
        if (shrinkable_bin.root_window_is_shrinked) {
            scrolled_window.vscrollbar_policy = Gtk.PolicyType.NEVER;
            follows_content_size = false;
        } else {
            scrolled_window.vscrollbar_policy = Gtk.PolicyType.AUTOMATIC;
            follows_content_size = true;
        }
    }

    void on_title_button_clicked () {
        close ();
    }
}
