/*
 * Copyright (C) 2025 Vladimir Romanov <rirusha@altlinux.org>
 *
 * This program is free software: you can redistribute it and/or modify
 * it under the terms of the GNU General Public License as published by
 * the Free Software Foundation, either version 3 of the License, or
 * (at your option) any later version.
 *
 * SPDX-License-Identifier: GPL-3.0-or-later
 */

using Tape;
using Tape.YaMAPI;

namespace Cassette {
    /**
     * Interface for initializable widgets that depend on content id.
     */
    public interface Initable {
        /**
         * Content id. Not set directly, use {@link init_content} method instead.
         */
        protected abstract string content_id { get; set; }

        /**
         * Abstract method for content initialization.
         * May include additional actions.
         *
         * @param content_id    id of content to initialize
         */
        public abstract void init_content (string content_id);
    }

    /**
     * Enum for cover image sizes
     */
    public enum CoverSize {
        SMALL = 60,
        BIG = 200
    }

    /**
     * Enum for blocking widget reasons
     */
    public enum BlockReason {
        /**
         * Functionality not implemented
         */
        NOT_IMPLEMENTED,
        /**
         * Authorization required for functionality
         */
        NEED_AUTH,
        /**
         * Bookmate subscription required for functionality
         */
        NEED_BOOKMATE
    }

    /**
     * Function to block a widget
     *
     * @param widget    widget to block
     * @param reason    reason for blocking
     */
    public static void block_widget (Gtk.Widget widget, BlockReason reason) {
        widget.sensitive = false;

        switch (reason) {
            case BlockReason.NOT_IMPLEMENTED:
                widget.tooltip_text = _("Not implemented yet");
                if (Config.IS_DEVEL) {
                    widget.sensitive = true;
                }
                break;

            case BlockReason.NEED_AUTH:
                widget.tooltip_text = _("Need authorization");
                break;

            case BlockReason.NEED_BOOKMATE:
                widget.tooltip_text = _("Need Bookmate subscription");
                break;

            default:
                assert_not_reached ();
        }
    }

    /**
     * Convenience function to clear a Gtk.FlowBox.
     */
    public static void clear_flow_box (Gtk.FlowBox flow_box) {
        while (flow_box.get_last_child () != null) {
            flow_box.remove (flow_box.get_last_child ());
        }
    }

    /**
     * Convert milliseconds to seconds
     *
     * @param ms    milliseconds
     * @return      seconds
     */
    public static int ms2sec (int64 ms) {
        return (int) (ms / 1000L);
    }

    /**
     * Function to create text representation of time.
     * Short representation:  66 -> 1:06
     * Long representation:   Duration: 1 min.
     *
     * @param seconds   seconds
     * @param is_short  whether short representation is needed
     *
     * @return          string representation
     */
    public static string sec2str (int seconds, bool is_short) {
        int minutes = (int) seconds / 60;
        int oth_seconds = (seconds - minutes * 60);

        string minutes_str = minutes.to_string ();
        string oth_seconds_str = oth_seconds.to_string ();

        if (is_short) {
            return @"$minutes_str:$(zfill (oth_seconds_str, 2))";
        } else {
            if (minutes > 60) {
                int hours = (int) minutes / 60;
                minutes -= hours * 60;

                string hours_str = hours.to_string ();
                minutes_str = minutes.to_string ();
                return _("Duration: %s h. %s min.").printf (hours_str, minutes_str);
            }
            return _("Duration: %s min.").printf (minutes_str);
        }
    }

    /**
     * Function to create text representation of time from milliseconds.
     * ``ms2str (66110, true) ->  "1:06"``
     * ``ms2str (66110, false) -> "Duration: 1 min."``
     *
     * @param ms        milliseconds
     * @param is_short  whether short representation is needed
     *
     * @return          string representation
     */
    public static string ms2str (int64 ms, bool is_short) {
        int seconds = ms2sec (ms);
        return sec2str (seconds, is_short);
    }

    /**
     * Function to pad string with characters on the left.
     * ``zfill ("56", 5) -> "00056"``
     * ``zfill ("56", 2) -> "56"``
     * ``zfill ("56", 1) -> "56"``
     *
     * @param str   source string
     * @param width target width
     *
     * @return      result
     */
    public static string zfill (string str, int width) {
        if (str.length >= width) {
            return str;
        }
        int padding = width - str.length;
        return string.nfill (padding, '0') + str;
    }

    /**
     * Function to format numbers with thousands separators.
     * prettify_num (5124421) -> "5 124 421"
     *
     * @param num   number
     *
     * @return      formatted number string
     */
    public static string prettify_num (int num) {
        string num_str = num.to_string ();
        return prettify_chunk (num_str, num_str.length - 3, "");
    }

    /**
     * Helper function for prettify_num - formats one chunk.
     *
     * @param num_str   string containing numeric value
     * @param start_pos starting position of chunk in string
     * @param res_str   recursive result string
     *
     * @return          formatted string
     */
    static string prettify_chunk (string num_str, int start_pos, string res_str) {
        if (start_pos == -3) {
            return res_str;
        }

        int end_pos = start_pos + 3;

        if (start_pos < 0) {
            start_pos = 0;
        }

        return prettify_chunk (num_str, start_pos - 3, num_str[start_pos:end_pos] + " " + res_str);
    }

    /**
     * Function to share playlist link to clipboard.
     *
     * @param playlist_info playlist object, link to which will be copied to clipboard
     */
    public static void playlist_share (YaMAPI.Playlist playlist_info) {
        string url = "https://music.yandex.ru/users/%s/playlists/%s?utm_medium=copy_link".printf (
            playlist_info.owner.login, playlist_info.kind
        );

        Gdk.Display? display = Gdk.Display.get_default ();
        if (display == null) {
            return;
        }
        Gdk.Clipboard clipboard = display.get_clipboard ();
        clipboard.set (typeof (string), url);
        var app = (Application?) GLib.Application.get_default ();
        var window = app?.active_window as Window;
        window?.show_message (_("Link copied to clipboard"));
    }

    /**
     * Add track to playlist dialog.
     *
     * @param track_info track to add
     */
    public static void add_track_to_playlist (YaMAPI.Track track_info) {
        var app = (Application?) GLib.Application.get_default ();
        var window = app?.active_window as Window;
        if (window != null) {
            var dialog = new PlaylistChooseDialog (track_info);
            dialog.present (window);
        }
    }

    /**
     * Remove track from playlist.
     *
     * @param track_info track to remove
     * @param playlist_info playlist to remove track from
     */
    public static void remove_track_from_playlist (YaMAPI.Track track_info, YaMAPI.Playlist playlist_info) {
        int position = -1;
        for (int i = 0; i < playlist_info.tracks.size; i++) {
            if (track_info.id == playlist_info.tracks[i].id) {
                position = i;
                break;
            }
        }

        if (position >= 0) {
            var yam_helper = Application.tape_client.yam_helper;
            yam_helper.remove_tracks_from_playlist.begin (
                playlist_info.kind,
                position,
                playlist_info.revision,
                (obj, res) => {
                    try {
                        yam_helper.remove_tracks_from_playlist.end (res);
                        var app = (Application?) GLib.Application.get_default ();
                        var window = app?.active_window as Window;
                        window?.show_message (_("Track removed from playlist"));
                    } catch (Error e) {
                        var app = (Application?) GLib.Application.get_default ();
                        var window = app?.active_window as Window;
                        window?.show_message (_("Failed to remove track from playlist: %s").printf (e.message));
                    }
                }
            );
        }
    }

    /**
     * Share track - copy link to clipboard.
     *
     * @param track_info track to share
     */
    public static void track_share (YaMAPI.Track track_info) {
        string url = "https://music.yandex.ru/album/%s/track/%s?utm_medium=copy_link".printf (
            track_info.albums[0].id, track_info.id
        );

        Gdk.Display? display = Gdk.Display.get_default ();
        if (display != null) {
            Gdk.Clipboard clipboard = display.get_clipboard ();
            clipboard.set_text (url);

            var app = (Application?) GLib.Application.get_default ();
            var window = app?.active_window as Window;
            window?.show_message (_("Link copied to clipboard"));
        }
    }

    /**
     * Roll shuffle mode to next state.
     * OFF -> ON -> OFF
     */
    public static void roll_shuffle_mode () {
        var player = Application.tape_client.player;
        switch (player.shuffle_mode) {
            case ShuffleMode.OFF:
                player.shuffle_mode = ShuffleMode.ON;
                break;
            case ShuffleMode.ON:
                player.shuffle_mode = ShuffleMode.OFF;
                break;
        }
    }

    /**
     * Roll repeat mode to next state.
     * OFF -> REPEAT_ALL/QUEUE -> REPEAT_ONE -> OFF
     */
    public static void roll_repeat_mode () {
        var player = Application.tape_client.player;
        switch (player.repeat_mode) {
            case RepeatMode.OFF:
                if (player.mode is PlayerFlow) {
                    player.repeat_mode = RepeatMode.ONE;
                } else {
                    player.repeat_mode = RepeatMode.QUEUE;
                }
                break;

            case RepeatMode.QUEUE:
                player.repeat_mode = RepeatMode.ONE;
                break;

            case RepeatMode.ONE:
                player.repeat_mode = RepeatMode.OFF;
                break;
        }
    }

    /**
     * Function to create a filled set from range.
     * ``range_set (1, 6, 1) -> {1, 2, 3, 4, 5}``
     *
     * @param start starting value
     * @param end   target value
     * @param step  step size
     *
     * @return      set
     */
    public static Gee.HashSet<int> range_set (int start, int end, int step = 1) {
        var rng = new Gee.HashSet<int> ();
        for (int item = start; item < end; item += step) {
            rng.add (item);
        }
        return rng;
    }

    /**
     * Function to find difference between two sets of integers.
     * ``difference ({1, 2, 3}, {2, 3, 4}) -> {1}``
     *
     * @param set_1 first set
     * @param set_2 second set
     *
     * @return      resulting set
     */
    public static Gee.HashSet<int> difference (Gee.HashSet<int> set_1, Gee.HashSet<int> set_2) {
        var out_set = new Gee.HashSet<int> ();
        foreach (int el in set_1) {
            if (!set_2.contains (el)) {
                out_set.add (el);
            }
        }
        return out_set;
    }

    /**
     * Get context type string from HasTracks object.
     *
     * @param yam_object object implementing HasTracks
     *
     * @return          context type string
     */
    public static string get_context_type (HasTracks yam_object) {
        if (yam_object is YaMAPI.Playlist) {
            return "playlist";
        }
        if (yam_object is YaMAPI.Album) {
            return "album";
        }
        if (yam_object is YaMAPI.Artist) {
            return "artist";
        }
        return "various";
    }

    /**
     * Function to get human-readable "when?" string.
     * get_when ("2006-04-30T03:01:38") -> "30.04.2006"
     * get_when ("2006-04-30T03:01:38") -> "yesterday"
     *
     * @param iso8601_datetime_str  ISO8601 datetime string
     *
     * @return                      human-readable "when?" string
     */
    public static string get_when (string iso8601_datetime_str) {
        var dt = new DateTime.from_iso8601 (iso8601_datetime_str, null);
        var now_dt = new DateTime.now ();

        var days = (int) (now_dt.difference (dt) / TimeSpan.DAY);

        if (days < 1) {
            return _("today");
        } else if (days < 2) {
            return _("yesterday");
        } else {
            return dt.format ("%x").replace ("/", ".");
        }
    }

    /**
     * Get context description string from HasTracks object.
     *
     * @param yam_object object implementing HasTracks
     *
     * @return          context description string
     */
    public static string? get_context_description (HasTracks yam_object) {
        if (yam_object is YaMAPI.Playlist) {
            return ((YaMAPI.Playlist) yam_object).title;
        }
        if (yam_object is YaMAPI.Album) {
            return ((YaMAPI.Album) yam_object).title;
        }
        if (yam_object is YaMAPI.Artist) {
            return ((YaMAPI.Artist) yam_object).name;
        }
        return null;
    }
}
