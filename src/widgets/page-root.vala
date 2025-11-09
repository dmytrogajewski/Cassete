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

using GLib;

public class Cassette.PageRoot : AbstractLoadablePage {

    public bool can_back { get; private set; default = false; }
    public bool can_refresh { get; private set; default = true; }

    bool main_view_is_loaded = false;

    public Window window { get; construct; }
    public BaseView main_view { get; construct; }

    public Gtk.Widget current_widget {
        get {
            return nav_view.visible_page.child;
        }
    }

    public PageRoot (Window window, BaseView main_view) {
        Object (window: window, main_view: main_view, with_header_bar: false);
    }

    construct {
        nav_view.add (new Adw.NavigationPage.with_tag (main_view, "title", "main-view"));
        main_view.root_view = this;

        nav_view.notify.connect (on_nav_view_notify);
        notify.connect (on_page_root_notify);

        map.connect (on_map);
        unmap.connect (on_unmap);
    }

    void on_nav_view_notify (ParamSpec pspec) {
        if (pspec.name == "visible-page") {
            update_navigation_state ();
        }
    }

    void update_navigation_state () {
        if (current_widget == main_view) {
            can_back = false;
        }

        if (current_widget is BaseView) {
            can_refresh = ((BaseView) current_widget).can_refresh;
        }
    }

    void on_page_root_notify (ParamSpec pspec) {
        if (pspec.name == "is-loading") {
            can_back = !is_loading && can_back;
            can_refresh = !is_loading && can_refresh;
        }
    }

    void on_map () {
        if (!main_view_is_loaded) {
            load_view (main_view);
        }

        if (window != null) {
            window.current_view = this;
        }
    }

    void on_unmap () {
        if (main_view_is_loaded && !is_loading) {
            nav_view.pop_to_tag ("main-view");
        }
    }

    public void add_view (BaseView view) {
        debug ("[TEST] PageRoot add_view: view=%s", view.get_type ().name ());
        nav_view.push (new Adw.NavigationPage (view, "title"));
        view.root_view = this;
        load_view (view);
    }

    public void refresh () {
        debug ("[TEST] PageRoot refresh triggered");
        var current_child = current_widget as BaseView;
        if (current_child != null) {
            refresh_view (current_child);
            return;
        }

        var error_view = current_widget as CantShowView;
        if (error_view != null) {
            nav_view.pop ();
            add_view (error_view.base_view);
        }
    }

    public void backward () {
        debug ("[TEST] PageRoot backward triggered");
        nav_view.pop ();
    }

    void load_view (BaseView view) {
        debug ("[TEST] PageRoot load_view start: view=%s", view.get_type ().name ());
        start_loading ();

        view.show_ready.connect (show_view);
        view.first_show.begin ();
    }

    void refresh_view (BaseView view) {
        debug ("[TEST] PageRoot refresh_view start: view=%s", view.get_type ().name ());
        start_loading ();

        view.show_ready.connect (show_view);
        view.refresh.begin ();
    }

    void show_view (BaseView view) {
        stop_loading ();
        view.show_ready.disconnect (show_view);

        can_refresh = view.can_refresh;
        debug ("[TEST] PageRoot show_view: view=%s can_refresh=%s", view.get_type ().name (), can_refresh.to_string ());

        if (view == main_view) {
            main_view_is_loaded = true;

        } else {
            can_back = true;
        }
    }

    public void show_error (BaseView base_view, int code) {
        stop_loading ();
        base_view.show_ready.disconnect (show_view);
        nav_view.pop ();

        nav_view.push (new Adw.NavigationPage (
            new CantShowView (base_view, code),
            "title"
        ));

        can_refresh = true;
        debug ("[TEST] PageRoot show_error: view=%s code=%d", base_view.get_type ().name (), code);

        if (base_view == main_view) {
            can_back = false;

        } else {
            can_back = true;
        }
    }
}
