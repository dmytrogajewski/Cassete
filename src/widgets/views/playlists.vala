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
using Tape.YaMAPI;
using Gee;

[GtkTemplate (ui = "/space/rirusha/Cassette/ui/playlists-view.ui")]
public class Cassette.PlaylistsView : BaseView {
    [GtkChild]
    unowned Gtk.Label playlists_label;
    [GtkChild]
    unowned Gtk.FlowBox flow_box;
    [GtkChild]
    unowned Gtk.Label liked_playlists_label;
    [GtkChild]
    unowned Gtk.FlowBox likes_flow_box;

    public override bool can_refresh { get; default = true; }

    PlaylistMicro liked_micro;

    public string? uid { get; construct set; }

    public PlaylistsView (string? uid = null) {
        Object (uid: uid);
    }

    construct {
        var yam_helper = Application.tape_client.yam_helper;
        yam_helper.playlists_updated.connect (() => {
            refresh.begin ();
        });

        liked_micro = new PlaylistMicro (this, new YaMAPI.Playlist.liked ());
    }

    void set_values (
        Gee.ArrayList<YaMAPI.Playlist?>? playlists_info,
        Gee.ArrayList<YaMAPI.LikedPlaylist?>? likes_playlists_info
    ) {
        clear_flow_box (flow_box);
        clear_flow_box (likes_flow_box);

        var app_settings = Application.app_settings;

        if (!app_settings.get_boolean ("show-liked")) {
            flow_box.append (liked_micro);
        }
        flow_box.append (new PlaylistCreateButton ());

        if (playlists_info != null) {
            if (playlists_info.size == 0) {
                playlists_label.visible = false;
            }

            foreach (var playlist_info in playlists_info) {
                if (playlist_info != null) {
                    flow_box.append (new PlaylistMicro (this, playlist_info));
                } else {
                    flow_box.append (new PlaylistMicro.empty ());
                }
            }
        } else {
            playlists_label.visible = false;
        }

        if (likes_playlists_info != null) {
            if (likes_playlists_info.size == 0) {
                liked_playlists_label.visible = false;
            }

            foreach (var liked_playlist in likes_playlists_info) {
                if (liked_playlist != null) {
                    likes_flow_box.append (new PlaylistMicro (this, liked_playlist.playlist));
                } else {
                    likes_flow_box.append (new PlaylistMicro.empty ());
                }
            }
        } else {
            liked_playlists_label.visible = false;
        }

        show_ready ();

        // Magicaly fix it https://t.me/RiruAndFriends/49936
        Idle.add_once (() => {
            flow_box.homogeneous = false;
            likes_flow_box.homogeneous = false;
        });

        Idle.add_once (() => {
            flow_box.homogeneous = true;
            likes_flow_box.homogeneous = true;
        });
    }

    public async override void first_show () {
        yield refresh ();
    }

    public async override int try_load_from_web () {
        Gee.ArrayList<YaMAPI.Playlist>? playlists_info = null;
        Gee.ArrayList<YaMAPI.LikedPlaylist>? liked_playlists_info = null;
        var yam_helper = Application.tape_client.yam_helper;
        try {
            playlists_info = yield yam_helper.get_playlist_list (uid);
            liked_playlists_info = yield yam_helper.get_likes_playlist_list (uid);
        } catch (ApiBase.BadStatusCodeError e) {
            // Ignore bad status codes - API may be temporarily unavailable
        } catch (Error e) {
            // Log other errors but don't fail
            warning ("API error: %s", e.message);
        }

        // Show playlists even if one of the lists is null
        if (playlists_info != null || liked_playlists_info != null) {
            set_values (playlists_info, liked_playlists_info);
            return -1;
        }
        
        return 0;
    }

    public async override bool try_load_from_cache () {
        var storager = Application.tape_client.cachier.storager;
        var playlists_kinds_str = storager.db.get_additional_data ("my_playlists");
        var playlists_info = new Gee.ArrayList<YaMAPI.Playlist?> ();

        var yam_helper = Application.tape_client.yam_helper;
        string? uid_val = uid;
        if (uid_val == null) {
            uid_val = yam_helper.me.oid;
        }

        if (playlists_kinds_str != null && uid_val != null) {
            string[] playlists_kinds = playlists_kinds_str.split (",");
            foreach (string kind in playlists_kinds) {
                string playlist_id = @"$uid_val:$kind";
                var playlist_info = (YaMAPI.Playlist) (yield storager.load_object (typeof (YaMAPI.Playlist), playlist_id));
                playlists_info.add (playlist_info);
            }
        }

        if (playlists_info.size > 0) {
            set_values (playlists_info, null);
            return true;
        }
        return false;
    }
}

