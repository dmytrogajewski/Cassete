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

[GtkTemplate (ui = "/space/rirusha/Cassette/ui/narrow-toggle-button.ui")]
public class Cassette.NarrowToggleButton: Gtk.ToggleButton {

    [GtkChild]
    unowned Gtk.Image button_image;
    [GtkChild]
    unowned Gtk.Label button_label;

    public new string icon_name {
        owned get {
            return button_image.icon_name;
        }
        construct set {
            button_image.icon_name = value;

            if (value != null && value != "") {
                button_image.visible = true;

            } else {
                button_image.visible = false;
            }
        }
    }

    public new string label {
        get {
            return button_label.label;
        }
        construct set {
            button_label.label = value;
        }
    }
}
