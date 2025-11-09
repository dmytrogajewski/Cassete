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

// Why this exist?
// Look: https://t.me/CassetteGNOME_Discussion/10666
public abstract class Cassette.Reactable : Gtk.Frame {

    protected abstract string css_class_name_hover { owned get; }

    protected abstract string css_class_name_active { owned get; }

    protected abstract string css_class_name_playing_default { owned get; }

    protected abstract string css_class_name_playing_hover { owned get; }

    protected abstract string css_class_name_playing_active { owned get; }

    bool _is_current_playing = false;
    public bool is_current_playing {
        get {
            return _is_current_playing;
        }
        set {
            _is_current_playing = value;

            if (value) {
                add_css_class (css_class_name_playing_default);

            } else {
                remove_css_class (css_class_name_playing_default);
                remove_css_class (css_class_name_playing_hover);
                remove_css_class (css_class_name_playing_active);
            }
        }
    }

    construct {
        var gs_hover = new Gtk.EventControllerMotion ();
        gs_hover.enter.connect (on_hover_enter);
        gs_hover.leave.connect (on_hover_leave);
        add_controller (gs_hover);

        var gs_active = new Gtk.GestureClick ();
        gs_active.pressed.connect (on_active_pressed);
        gs_active.stopped.connect (on_active_stopped);
        gs_active.released.connect (on_active_released);
        add_controller (gs_active);

        var gs_playing_hover = new Gtk.EventControllerMotion ();
        gs_playing_hover.enter.connect (on_playing_hover_enter);
        gs_playing_hover.leave.connect (on_playing_hover_leave);
        add_controller (gs_playing_hover);

        var gs_playing_active = new Gtk.GestureClick ();
        gs_playing_active.pressed.connect (on_playing_active_pressed);
        gs_playing_active.stopped.connect (on_playing_active_stopped);
        gs_playing_active.released.connect (on_playing_active_released);
        add_controller (gs_playing_active);
    }

    void on_hover_enter () {
        add_css_class (css_class_name_hover);
    }

    void on_hover_leave () {
        remove_css_class (css_class_name_hover);
    }

    void on_active_pressed () {
        add_css_class (css_class_name_active);
    }

    void on_active_stopped () {
        remove_css_class (css_class_name_active);
    }

    void on_active_released () {
        remove_css_class (css_class_name_active);
    }

    void on_playing_hover_enter () {
        if (is_current_playing) {
            add_css_class (css_class_name_playing_hover);
        }
    }

    void on_playing_hover_leave () {
        if (is_current_playing) {
            remove_css_class (css_class_name_playing_hover);
        }
    }

    void on_playing_active_pressed () {
        if (is_current_playing) {
            add_css_class (css_class_name_playing_active);
        }
    }

    void on_playing_active_stopped () {
        if (is_current_playing) {
            remove_css_class (css_class_name_playing_active);
        }
    }

    void on_playing_active_released () {
        if (is_current_playing) {
            remove_css_class (css_class_name_playing_active);
        }
    }
}
