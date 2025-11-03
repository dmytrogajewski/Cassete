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

[GtkTemplate (ui = "/space/rirusha/Cassette/ui/action-card-custom.ui")]
public class Cassette.ActionCardCustom : Reactable {

    public signal void clicked ();

    protected override string css_class_name_hover {
        owned get {
            return "action-card-hover";
        }
    }

    protected override string css_class_name_active {
        owned get {
            return "action-card-active";
        }
    }

    protected override string css_class_name_playing_default {
        owned get {
            return "";
        }
    }

    protected override string css_class_name_playing_hover {
        owned get {
            return "";
        }
    }

    protected override string css_class_name_playing_active {
        owned get {
            return "";
        }
    }

    construct {
        var gs = new Gtk.GestureClick ();
        gs.released.connect ((n, x, y) => {
            if (contains (x, y)) {
                clicked ();
            }
        });
        add_controller (gs);
    }
}

