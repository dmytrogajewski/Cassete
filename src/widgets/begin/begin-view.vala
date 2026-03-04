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

using Tape;
using WebKit;

namespace Cassette {

    [GtkTemplate (ui = "/space/rirusha/Cassette/ui/begin-view.ui")]
    public class BeginView : AbstractLoadablePage {
        [GtkChild]
        unowned Adw.NavigationView navigation_view;
        
        Gtk.Box main_box;
        Gtk.Button button_local_mode;
        Gtk.Button button_refresh;
        Adw.ToolbarView toolbar_view_auth;

        private WebView webview = new WebView ();

        public signal void local_choosed ();
        public signal void online_complete ();

        public BeginView (bool with_header_bar) {
            Object (with_header_bar: with_header_bar);
        }

        construct {
            // Set nav_view from template; base class set child to default nav_view, so update child
            nav_view = navigation_view;
            child = nav_view;

            // Create main_box with usage mode UI
            main_box = new Gtk.Box (Gtk.Orientation.VERTICAL, 12) {
                margin_top = 8,
                margin_bottom = 8,
                margin_start = 8,
                margin_end = 8,
                valign = Gtk.Align.CENTER
            };

            var title_box = new Gtk.Box (Gtk.Orientation.VERTICAL, 6) {
                valign = Gtk.Align.CENTER,
                margin_start = 12,
                margin_end = 12
            };

            var title_label = new Gtk.Label (_("Choose usage mode")) {
                css_classes = {"title-1"},
                wrap = true
            };
            title_box.append (title_label);

            var desc_label = new Gtk.Label (_("If you select the \"Online mode\", you can access local music by enabling the display of the corresponding pages in the pages preferences, as well as log in later when selecting \"Local mode\"")) {
                css_classes = {"dim-label"},
                vexpand = true,
                wrap = true
            };
            title_box.append (desc_label);
            main_box.append (title_box);

            var clamp = new Adw.Clamp () {
                maximum_size = 300,
                margin_top = 8,
                margin_bottom = 8,
                margin_start = 8,
                margin_end = 8
            };

            var button_box = new Gtk.Box (Gtk.Orientation.VERTICAL, 6) {
                valign = Gtk.Align.CENTER
            };

            var button_online_mode = new Gtk.Button () {
                css_classes = {"pill"},
                label = _("Online mode")
            };
            button_box.append (button_online_mode);

            button_local_mode = new Gtk.Button () {
                css_classes = {"pill"},
                label = _("Local mode")
            };
            button_box.append (button_local_mode);

            var button_bad_close = new Gtk.Button () {
                css_classes = {"destructive-action", "pill"},
                margin_top = 24,
                label = _("Close")
            };
            button_box.append (button_bad_close);

            clamp.child = button_box;
            main_box.append (clamp);

            // Create usage mode page
            var usage_mode_header = new Adw.HeaderBar () {
                show_end_title_buttons = false
            };
            var usage_mode_toolbar = new Adw.ToolbarView ();
            usage_mode_toolbar.add_top_bar (usage_mode_header);
            usage_mode_toolbar.content = main_box;

            var usage_mode_page = new Adw.NavigationPage (usage_mode_toolbar, _("Usage mode"));
            navigation_view.add (usage_mode_page);

            // Create auth page
            toolbar_view_auth = new Adw.ToolbarView ();
            var auth_header = new Adw.HeaderBar () {
                show_end_title_buttons = false
            };
            button_refresh = new Gtk.Button () {
                icon_name = "view-refresh-symbolic"
            };
            auth_header.pack_start (button_refresh);
            toolbar_view_auth.add_top_bar (auth_header);
            toolbar_view_auth.content = webview;

            var auth_page = new Adw.NavigationPage.with_tag (toolbar_view_auth, _("Authorization"), "auth-page");
            navigation_view.add (auth_page);

            var action_group = new GLib.SimpleActionGroup ();

            var bad_close_action = new GLib.SimpleAction ("bad-close", null);
            bad_close_action.activate.connect (on_bad_close_action_activate);
            action_group.add_action (bad_close_action);

            var login_action = new GLib.SimpleAction ("online", null);
            login_action.activate.connect (online);
            action_group.add_action (login_action);

            var local_action = new GLib.SimpleAction ("local", null);
            local_action.activate.connect (local);
            action_group.add_action (local_action);

            insert_action_group ("auth", action_group);
            
            // Connect button signals
            button_online_mode.action_name = "auth.online";
            button_local_mode.action_name = "auth.local";
            button_bad_close.action_name = "auth.bad-close";
            button_refresh.clicked.connect (refresh);

            webview.load_changed.connect (on_webview_load_changed);

            var network_session = webview.get_network_session ();
            var cookie_manager = network_session.get_cookie_manager ();
            var storager = Application.tape_client.cachier.storager;

            cookie_manager.set_persistent_storage (storager.cookies_file.peek_path (), CookiePersistentStorage.SQLITE);

            // Кнопка не блокируется, если выполнять не добавлять в Idle
            Idle.add_once (() => {
                block_widget (button_local_mode, BlockReason.NOT_IMPLEMENTED);
            });

            if (Config.IS_DEVEL) {
                add_css_class ("devel");
            }
        }

        void refresh () {
            start_loading ();

            webview.reload ();
        }

        void online () {
            navigation_view.push_by_tag ("auth-page");

            start_loading ();

            webview.load_uri (
                "https://oauth.yandex.ru/authorize?response_type=token&client_id=23cabbbdc6cd418abb4b39c32c41195d" // vala-lint=line-length
            );
        }

        void local () {
            assert_not_reached ();

            //  choosed_local ();
            //  close ();
        }

        void on_bad_close_action_activate () {
            var app = (Application?) GLib.Application.get_default ();
            app?.quit ();
        }

        void on_webview_load_changed (LoadEvent event) {
            if (("https://music.yandex." in webview.uri) && event != LoadEvent.STARTED) {
                online_complete ();
            } else {
                warning ("Redirected to %s", webview.uri);
            }

            if (event == LoadEvent.FINISHED && is_loading) {
                stop_loading ();
            }
        }
    }
}
