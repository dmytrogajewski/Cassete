/*
 * Copyright (C) 2023-2025 Vladimir Romanov <rirusha@altlinux.org>
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
using Tape.YaMAPI;
using GLib;

public sealed class Cassette.Application : Adw.Application {

    const ActionEntry[] ACTION_ENTRIES = {
        { "quit", quit },
        { "show-message", show_message, "s" },
        { "log-out", on_log_out_action },
        { "force-log-out", on_force_log_out_action },
        { "play-pause", on_play_pause_action },
        { "next", on_next_action },
        { "prev", on_prev_action },
        { "prev-force", on_prev_force_action },
        { "change-shuffle", on_change_shuffle_action },
        { "change-repeat", on_change_repeat_action },
        { "share-current-track", on_share_current_track_action},
        { "parse-url", on_parse_url_action },
        { "open-account", on_open_account_action },
        { "open-plus", on_open_plus_action },
        { "get-plus", on_get_plus_action },
        { "mute", on_mute_action },
    };

    const OptionEntry[] OPTION_ENTRIES = {
        { "version", 'v', 0, OptionArg.NONE, null, N_("Print version information and exit"), null },
        { null }
    };

    private static GLib.Settings? _app_settings;
    private static GLib.Settings? _client_settings;
    private static Tape.Settings? _tape_settings;
    private static Tape.Client? _tape_client;

    public static GLib.Settings app_settings {
        get {
            assert (_app_settings != null);
            return _app_settings;
        }
    }

    public static GLib.Settings client_settings {
        get {
            assert (_client_settings != null);
            return _client_settings;
        }
    }

    public static Tape.Settings tape_settings {
        get {
            assert (_tape_settings != null);
            return _tape_settings;
        }
    }

    public static Tape.Client tape_client {
        get {
            assert (_tape_client != null);
            return _tape_client;
        }
    }

    public ApplicationState application_state {
        get {
            return (ApplicationState) app_settings.get_enum ("application-state");
        }
        set {
            var old_state = application_state;
            if (old_state != value) {
                app_settings.set_enum ("application-state", value);
                application_state_changed (value, old_state);
            }
        }
    }

    public signal void application_state_changed (ApplicationState new_state, ApplicationState old_state);

    public Application () {
        Object (
            application_id: Config.APP_ID_RELEVANT,
            resource_base_path: @"/$(Config.APP_ID.replace (".", "/"))/",
            flags: ApplicationFlags.DEFAULT_FLAGS | ApplicationFlags.HANDLES_OPEN
        );
    }

    static construct {
        // Ensure custom widget types are registered before UI loading
        // This ensures GTK can find types referenced in Blueprint templates
        typeof (Cassette.HeaderedScrolledWindow).ensure ();
        typeof (Cassette.CacheIndicator).ensure ();
        typeof (Cassette.TrackCarousel).ensure ();
        typeof (Cassette.PrimaryMenuButton).ensure ();
        typeof (Cassette.PlayerBar).ensure ();
        typeof (Cassette.Sidebar).ensure ();
        typeof (Cassette.BaseView).ensure ();
        typeof (Cassette.MainView).ensure ();
        typeof (Cassette.StationsView).ensure ();
        typeof (Cassette.AlbumView).ensure ();
        typeof (Cassette.DevelView).ensure ();
        typeof (Cassette.SearchView).ensure ();
        typeof (Cassette.CollectionView).ensure ();
        typeof (Cassette.PlayMark).ensure ();
        typeof (Cassette.PlayMarkGlobal).ensure ();
        typeof (Cassette.PlayMarkTrack).ensure ();
        typeof (Cassette.VolumeButton).ensure ();
        typeof (Cassette.PlaylistMicro).ensure ();
        typeof (Cassette.AlbumMicro).ensure ();
        typeof (Cassette.LikedPlaylistMicro).ensure ();
        typeof (Cassette.PreferencesDialog).ensure ();
        typeof (Cassette.CustomPagesPreferences).ensure ();
        typeof (Cassette.CustomPagePreferences).ensure ();
        typeof (Cassette.CacheDeletionPreferences).ensure ();
    }

    construct {
        add_main_option_entries (OPTION_ENTRIES);
        set_option_context_parameter_string ("[YANDEX-MUSIC-URL]");

        add_action_entries (ACTION_ENTRIES, this);
        set_accels_for_action ("app.quit", { "<primary>q" });
        set_accels_for_action ("app.play-pause", { "space" });
        set_accels_for_action ("app.prev", { "<Alt>Left" });
        set_accels_for_action ("app.next", { "<Alt>Right" });
        set_accels_for_action ("app.change-shuffle", { "<Ctrl>s" });
        set_accels_for_action ("app.change-repeat", { "<Ctrl>r" });
        set_accels_for_action ("app.share-current-track", { "<Ctrl><Shift>c" });
        set_accels_for_action ("app.parse-url", { "<Ctrl><Shift>v" });
        set_accels_for_action ("app.mute", { "<Ctrl>m" });
        set_accels_for_action ("win.show-help-overlay", { "F1" });
    }

    protected override int handle_local_options (VariantDict options) {
        if (options.contains ("version")) {
            print ("%s %s\n", Config.APP_NAME, Config.VERSION);
            return 0;
        }

        return -1;
    }

    protected override void startup () {
        base.startup ();

        // Force dark theme like GNOME Terminal
        var style_manager = Adw.StyleManager.get_default ();
        style_manager.color_scheme = Adw.ColorScheme.FORCE_DARK;

        _app_settings = new GLib.Settings (@"$(Config.APP_ID).application");
        _client_settings = new GLib.Settings (@"$(Config.APP_ID).client");

        _tape_settings = new Tape.Settings (Config.APP_NAME, Config.APP_ID_RELEVANT);
        client_settings.bind ("repeat-mode", tape_settings, "repeat-mode", DEFAULT);
        client_settings.bind ("shuffle-mode", tape_settings, "shuffle-mode", DEFAULT);
        client_settings.bind ("volume", tape_settings, "volume", DEFAULT);
        client_settings.bind ("mute", tape_settings, "mute", DEFAULT);
        client_settings.bind ("add-tracks-to-start", tape_settings, "add-tracks-to-start", DEFAULT);
        client_settings.bind ("music-quality", tape_settings, "music-quality", DEFAULT);
        client_settings.bind ("can-cache", tape_settings, "can-cache", DEFAULT);

        _tape_client = new Tape.Client (tape_settings);

        // Initialize application state from settings
        // The state will be updated based on authentication and network status
        application_state = (ApplicationState) app_settings.get_enum ("application-state");

        debug ("[TEST] Application startup complete");
    }

    public override void activate () {
        base.activate ();

        if (active_window == null) {
            var win = new Window (this);

            win.present ();
        } else {
            active_window.present ();
        }
    }

    public void show_message (SimpleAction action, Variant? param) {
        var message = param.get_string ();

        if (active_window != null) {
            ((Cassette.Window) active_window).show_message (message);

            if (active_window.is_active) {
                return;
            }
        }

        var ntf = new Notification (_("Cassette"));
        ntf.set_body (message);
        send_notification (Config.APP_ID_RELEVANT, ntf);
    }

    void on_log_out_action () {
        var window = active_window as Window;
        if (window != null && window.auth != null) {
            debug ("[TEST] Log out action triggered");
            window.auth.log_out ();
        } else {
            debug ("[TEST] Log out action ignored: no auth widget");
        }
    }

    void on_force_log_out_action () {
        var window = active_window as Window;
        if (window != null && window.auth != null) {
            debug ("[TEST] Force log out action triggered");
            window.auth.force_log_out ();
        } else {
            debug ("[TEST] Force log out action ignored: no auth widget");
        }
    }

    void on_play_pause_action () {
        var window = active_window as Window;
        if (window != null) {
            var focus_widget = window.get_focus () as Gtk.Text;
            if (focus_widget != null) {
                // Fix situation where space can't be typed because play-pause action takes it
                focus_widget.insert_at_cursor (" ");
                return;
            }
        }

        var player = tape_client.player;
        player.play_pause ();
        debug ("[TEST] Play/Pause action toggled");
    }

    void on_change_shuffle_action () {
        debug ("[TEST] Shuffle action triggered");
        roll_shuffle_mode ();
    }

    void on_change_repeat_action () {
        debug ("[TEST] Repeat action triggered");
        roll_repeat_mode ();
    }

    void on_next_action () {
        var player = tape_client.player;
        if (player.can_go_next) {
            debug ("[TEST] Next track action triggered");
            player.next.begin ();
        } else {
            debug ("[TEST] Next track action ignored: can_go_next=false");
        }
    }

    void on_prev_action () {
        var player = tape_client.player;
        if (player.can_go_prev) {
            debug ("[TEST] Previous track action triggered");
            player.prev ();
        } else {
            debug ("[TEST] Previous track action ignored: can_go_prev=false");
        }
    }

    void on_prev_force_action () {
        var player = tape_client.player;
        if (player.can_go_prev) {
            debug ("[TEST] Previous track (force) action triggered");
            player.prev (true);
        } else {
            debug ("[TEST] Previous track (force) action ignored: can_go_prev=false");
        }
    }

    void on_share_current_track_action () {
        var player = tape_client.player;
        var current_track = player.mode.get_current_track_info ();

        if (current_track?.is_ugc == false) {
            debug ("[TEST] Share current track action triggered: track_id=%s", current_track.id);
            track_share (current_track);
        } else {
            var window = active_window as Window;
            window?.show_message (_("Current track can not be copied to the clipboard"));
            debug ("[TEST] Share current track action blocked: current track is UGC");
        }
    }

    void on_parse_url_action () {
        activate ();
        debug ("[TEST] Parse URL action triggered");

        Gdk.Display? display = Gdk.Display.get_default ();
        if (display == null) {
            debug ("[TEST] Parse URL action aborted: no display");
            return;
        }

        Gdk.Clipboard clipboard = display.get_clipboard ();
        clipboard.read_text_async.begin (null, (obj, res) => {
            try {
                string? uri = clipboard.read_text_async.end (res);
                if (uri != null) {
                    debug ("[TEST] Clipboard text read for parse: %s", uri);
                    parse_uri (uri);
                }
            } catch (Error e) {
                var window = active_window as Window;
                window?.show_message (_("Can't parse clipboard content"));
                debug ("[TEST] Parse URL action failed: %s", e.message);
            }
        });
    }

    void parse_uri (string uri) {
        string clear_uri;
        if (uri.has_prefix ("https://music.yandex.ru/")) {
            clear_uri = uri.replace ("https://music.yandex.ru/", "");
        } else if (uri.has_prefix ("yandexmusic://")) {
            clear_uri = uri.replace ("yandexmusic://", "");
        } else {
            warning (_("Can't parse clipboard content"));
            debug ("[TEST] Parse URL action failed: unsupported prefix in %s", uri);
            return;
        }

        string[] parts = clear_uri.split ("/");
        if (parts.length < 2) {
            warning (_("Can't parse clipboard content"));
            debug ("[TEST] Parse URL action failed: insufficient parts in %s", clear_uri);
            return;
        }

        var window = active_window as Window;
        if (window == null || window.current_view == null) {
            return;
        }

        // Handle users playlists
        if (parts[0] == "users") {
            if (parts.length < 3) {
                debug ("[TEST] Parse URL action failed: users path too short");
                return;
            }
            if (parts[2] == "playlists") {
                if (parts.length == 3) {
                    window.show_message (_("Users view not implemented yet"));
                    debug ("[TEST] Parse URL action blocked: users playlist list not implemented");
                    return;
                }
                string user_id = parts[1];
                string kind = parts[3];
                debug ("[TEST] Parse URL action opening playlist: user_id=%s kind=%s", user_id, kind);
                window.current_view.add_view (new PlaylistView (user_id, kind));
            }
        } else if (parts[0] == "album") {
            if (parts.length < 2) {
                debug ("[TEST] Parse URL action failed: album path too short");
                return;
            }
            string album_id = parts[1];
            debug ("[TEST] Parse URL action opening album: id=%s", album_id);
            window.current_view.add_view (new AlbumView (album_id));
        }
    }

    void on_open_account_action () {
        new Gtk.UriLauncher ("https://id.yandex.ru/").launch.begin (null, null);
        debug ("[TEST] Open account action triggered");
    }

    void on_open_plus_action () {
        new Gtk.UriLauncher ("https://plus.yandex.ru/").launch.begin (null, null);
        debug ("[TEST] Open plus action triggered");
    }

    void on_get_plus_action () {
        new Gtk.UriLauncher ("https://plus.yandex.ru/getplus/").launch.begin (null, null);
        debug ("[TEST] Get plus action triggered");
    }

    void on_mute_action () {
        var player = tape_client.player;
        player.mute = !player.mute;
        debug ("[TEST] Mute action toggled: mute=%s", player.mute.to_string ());
    }
}
