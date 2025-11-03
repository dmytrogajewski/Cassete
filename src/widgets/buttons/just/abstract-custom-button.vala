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

[GtkTemplate (ui = "/space/rirusha/Cassette/ui/custom-button.ui")]
public abstract class Cassette.CustomButton : Adw.Bin {

    [GtkChild]
    protected unowned Gtk.Button real_button;
    [GtkChild]
    unowned Adw.ButtonContent button_content;

    public string label {
        get {
            return button_content.label;
        }
        set {
            button_content.label = value;
        }
    }

    public string icon_name {
        get {
            return button_content.icon_name;
        }
        set {
            button_content.icon_name = value;
        }
    }

    /**
     * Easy way to set both width and height of the button.
     */
    public int size {
        construct {
            width_request = value;
            height_request = value;
        }
    }

    construct {
        bind_property ("css-classes", real_button, "css-classes", BindingFlags.DEFAULT);
    }
}

