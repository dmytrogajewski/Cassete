/*
 * Copyright (C) 2025 Vladimir Romanov <rirusha@altlinux.org>
 *
 * This program is free software: you can redistribute it and/or modify
 * it under the terms of the GNU General Public License as published by
 * the Free Software Foundation, either version 3 of the License, or
 * (at your option) any later version.
 *
 * This program is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the
 * GNU General Public License for more details.
 *
 * You should have received a copy of the GNU General Public License
 * along with this program. If not, see
 * <https://www.gnu.org/licenses/gpl-3.0-standalone.html>.
 *
 * SPDX-License-Identifier: GPL-3.0-or-later
 */

using Tape;
using GLib;

[GtkTemplate (ui = "/space/rirusha/Cassette/ui/auth.ui")]
public sealed class Cassette.Auth : Loadable {

    [GtkChild]
    unowned Gtk.Stack win_stack;
    [GtkChild]
    unowned Adw.StatusPage auth_status_page;
#if !WITH_WEBKIT
    [GtkChild]
    unowned Adw.ButtonRow webkit_login;
#endif
    [GtkChild]
    unowned Adw.PasswordEntryRow token_login;

    construct {
        auth_status_page.icon_name = Config.APP_ID_RELEVANT + "-symbolic";

#if WITH_WEBKIT
        auth_status_page.description = _("Choose a way to log in to the app. You can log in via your Yandex account or with your token."); // vala-lint=line-length
#else
        webkit_login.visible = false;
        auth_status_page.description = _("You need your Yandex music token to login.");
#endif

        debug ("[TEST] Auth construct: initiating auto login");
        try_auth.begin (null);

        if (Config.IS_DEVEL) {
            add_css_class ("devel");
        }
    }

    void clear_main () {
        if (win_stack.get_child_by_name ("main") != null) {
            win_stack.remove (win_stack.get_child_by_name ("main"));
        }
    }

    public void to_main () {
        clear_main ();
        var window = (Window?) get_root ();
        var main_content = new MainContent (window);
        win_stack.add_named (main_content, "main");
        win_stack.visible_child_name = "main";
        is_loading = false;
        debug ("[TEST] Auth transitioned to main content");
    }

    public void to_auth () {
        win_stack.visible_child_name = "auth";
        clear_main ();
        is_loading = false;
        debug ("[TEST] Auth transitioned to login form");
    }

    void to_cant_use (CantUseError e) {
        switch (e.code) {
            case CantUseError.NO_PLUS:
                win_stack.visible_child_name = "no-plus";
                break;
        }
        clear_main ();
        is_loading = false;
        debug ("[TEST] Auth transition to can't use screen: code=%s", e.code.to_string ());
    }

    [GtkCallback]
    void on_yandex_apply () {
#if WITH_WEBKIT
        var dialog = new WebkitAuthDialog (Cassette.Application.tape_client.cachier.storager.cookies_file);
        dialog.present (this);
        dialog.success.connect (on_auth_dialog_success);
        is_loading = true;
        debug ("[TEST] Auth WebKit dialog opened");
#endif
    }

    [GtkCallback]
    void on_token_apply () {
        is_loading = true;
        debug ("[TEST] Auth token submit clicked");
        try_auth.begin (token_login.text);
    }

    async void try_auth (string? token) {
        try {
            if (yield Cassette.Application.tape_client.init (token)) {
                debug ("[TEST] Auth success");
                to_main ();
            } else {
                if (token != null) {
                    activate_action_variant ("app.show-message", _("Failed to login. Probably wrong token"));
                }
                to_auth ();
                debug ("[TEST] Auth failed: init returned false");
            }
        } catch (ApiBase.BadStatusCodeError e) {
            activate_action_variant ("app.show-message", _("Bad status code: %i").printf (e.code));
            to_auth ();
            debug ("[TEST] Auth failed: bad status code %d", e.code);
        } catch (ApiBase.JsonError e) {
            activate_action_variant ("app.show-message", _("Invalid response from server: %s").printf (e.message));
            to_auth ();
            debug ("[TEST] Auth failed: JsonError %s", e.message);
        } catch (CantUseError e) {
            to_cant_use (e);
            debug ("[TEST] Auth failed: CantUseError code=%s", e.code.to_string ());
        } catch (ApiBase.SoupError e) {
            activate_action_variant ("app.show-message", _("Connection problems"));
            to_auth ();
            debug ("[TEST] Auth failed: SoupError %s", e.message);
        }
    }

    [GtkCallback]
    void on_open_link () {
        new Gtk.UriLauncher ("https://yandex-music.readthedocs.io/en/main/token.html").launch.begin (null, null);
        debug ("[TEST] Auth token help link opened");
    }

    [GtkCallback]
    void on_to_auth_clicked () {
        Tape.Storager.remove_file.begin (Application.tape_client.cachier.storager.cookies_file, to_auth);
        debug ("[TEST] Auth reset to login requested");
    }

    public void log_out () {
        var dialog = new Adw.AlertDialog (
            _("Log out?"),
            _("You will need to log in again to use the app")
        );

        dialog.add_response ("cancel", _("Cancel"));
        dialog.add_response ("logout", _("Log out"));

        dialog.set_response_appearance ("logout", Adw.ResponseAppearance.DESTRUCTIVE);

        dialog.default_response = "cancel";
        dialog.close_response = "cancel";

        var window = (Window?) get_root ();
        if (window == null) {
            return;
        }

        dialog.response.connect (on_logout_dialog_response);

        dialog.present (window);
        debug ("[TEST] Auth logout dialog opened");
    }

    public void force_log_out () {
        var storager = Application.tape_client.cachier.storager;
        storager.clear_user_data.begin (true, false, on_clear_user_data_complete);
        debug ("[TEST] Auth force logout initiated");
    }

    void on_auth_dialog_success () {
        try_auth.begin (null);
        debug ("[TEST] Auth WebKit dialog success");
    }

    void on_logout_dialog_response (Adw.AlertDialog dialog, string response) {
        if (response == "logout") {
            force_log_out ();
            debug ("[TEST] Auth logout confirmed");
        } else {
            debug ("[TEST] Auth logout cancelled");
        }
    }

    void on_clear_user_data_complete (Object? obj, AsyncResult res) {
        var storager = Application.tape_client.cachier.storager;
        storager.clear_user_data.end (res);
        ((Application) GLib.Application.get_default ()).quit ();
        debug ("[TEST] Auth user data cleared and application quit");
    }
}
