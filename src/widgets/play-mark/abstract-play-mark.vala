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

public abstract class Cassette.PlayMark : Adw.Bin {

    Gtk.Image real_image = new Gtk.Image ();

    /**
     * Not the actual playback, but whether the player considers
     * this track to be current.
     */
    public bool is_current_playing { get; private set; default = false; }

    /**
     * Actual playback state.
     */
    protected bool is_playing { get; private set; default = false; }

    public Gtk.IconSize icon_size {
        get {
            return real_image.icon_size;
        }
        set {
            real_image.icon_size = value;
        }
    }

    construct {
        child = real_image;

        // Set accessible name based on playback state
        update_accessible_name ();
        notify["is-playing"].connect (() => {
            on_is_playing_notify ();
            update_accessible_name ();
        });
        on_is_playing_notify ();
    }

    void update_accessible_name () {
        // Use tooltip for accessible name as accessible-label may not be supported
        if (is_playing) {
            tooltip_text = _("Pause");
        } else {
            tooltip_text = _("Play");
        }
    }

    void on_is_playing_notify () {
        if (is_playing) {
            real_image.icon_name = "media-playback-pause-symbolic";
        } else {
            real_image.icon_name = "media-playback-start-symbolic";
        }
    }

    public void set_playing () {
        is_playing = true;
        is_current_playing = true;
    }

    public void set_paused () {
        is_playing = false;
        is_current_playing = true;
    }

    public void set_stopped () {
        is_playing = false;
        is_current_playing = false;
    }
}

