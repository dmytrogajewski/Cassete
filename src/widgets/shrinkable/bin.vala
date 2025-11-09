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

/**
 * Connection for resize handling with adaptive UI.
 * Allows connection with window resize for different shrink edge width.
 */
public class Cassette.ShrinkableBin : Adw.Bin {

    /**
     * Size changed signal.
     *
     * @param width     new width of window
     * @param height    new height of window
     */
    public signal void resized (int width, int height);

    /**
     * Width value that triggers ``is_shrinked`` changes
     */
    public int shrink_edge_width { get; set; default = -1; }

    public bool root_window_is_shrinked { get; private set; default = false; }

    /**
     * Whether widget should be shrinked or not
     */
    public bool is_shrinked { get; private set; default = false; }

    bool first_resize = true;
    ulong? window_handler = null;
    ulong? app_window_handler = null;
    Window? connected_window = null;
    Application? connected_app = null;

    construct {
        var app = (Application?) GLib.Application.get_default ();
        if (app != null && app.active_window != null) {
            connect_to_window ((Window) app.active_window);
        }

        if (app != null) {
            connected_app = app;
            app_window_handler = app.notify.connect (on_app_notify);
        }
    }

    void on_app_notify (ParamSpec pspec) {
        if (pspec.name == "active-window") {
            on_active_window_changed ();
        }
    }

    void on_active_window_changed () {
        var app = (Application?) GLib.Application.get_default ();
        var window = app?.active_window as Window;
        if (window != null) {
            connect_to_window (window);
        }
    }

    void connect_to_window (Window window) {
        // Disconnect from previous window if connected
        if (connected_window != null && window_handler != null) {
            ulong handler = window_handler;
            SignalHandler.disconnect (connected_window, handler);
            window_handler = null;
            connected_window = null;
        }

        // Track window size changes via width/height properties
        connected_window = window;
        window_handler = window.notify.connect (on_window_notify);
        check_window_size ();
    }

    void on_window_notify (ParamSpec pspec) {
        if (pspec.name == "default-width" || pspec.name == "default-height") {
            check_window_size ();
        }
    }

    void check_window_size () {
        var app = (Application?) GLib.Application.get_default ();
        var window = app?.active_window as Window;
        if (window == null) {
            return;
        }

        int width = window.default_width;
        int height = window.default_height;

        if (shrink_edge_width != -1) {
            bool should_be_shrinked = width < shrink_edge_width;

            if (should_be_shrinked != root_window_is_shrinked || first_resize) {
                root_window_is_shrinked = should_be_shrinked;
                is_shrinked = should_be_shrinked;
            }
        }

        first_resize = false;
        resized (width, height);
    }

    protected override void dispose () {
        if (window_handler != null && connected_window != null) {
            ulong handler = window_handler;
            SignalHandler.disconnect (connected_window, handler);
            window_handler = null;
            connected_window = null;
        }

        if (app_window_handler != null && connected_app != null) {
            ulong handler = app_window_handler;
            SignalHandler.disconnect (connected_app, handler);
            app_window_handler = null;
            connected_app = null;
        }

        base.dispose ();
    }
}
