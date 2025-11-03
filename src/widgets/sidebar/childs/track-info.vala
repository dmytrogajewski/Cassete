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

[GtkTemplate (ui = "/space/rirusha/Cassette/ui/track-info.ui")]
public class Cassette.TrackInfo : SidebarChildBin {

    [GtkChild]
    unowned LyricsPanel lyrics_panel;
    [GtkChild]
    unowned Gtk.Label writers_label;
    [GtkChild]
    unowned Gtk.Label major_label;
    [GtkChild]
    unowned Gtk.Stack loading_stack;
    [GtkChild]
    unowned Gtk.Box lyrics_box;
    [GtkChild]
    unowned Gtk.Box similar_box;
    [GtkChild]
    unowned Gtk.Button play_button;
    [GtkChild]
    unowned PlayMarkTrack play_mark_track;
    [GtkChild]
    unowned SaveStack save_stack;
    [GtkChild]
    unowned LikeButton like_button;
    [GtkChild]
    unowned DislikeButton dislike_button;
    [GtkChild]
    unowned TrackInfoPanel info_panel;
    [GtkChild]
    unowned TrackOptionsButton track_options_button;

    public YaMAPI.Track track_info { get; construct set; }

    public TrackInfo (YaMAPI.Track track_info) {
        Object (track_info: track_info);
    }

    construct {
        info_panel.track_info = track_info;
        track_options_button.track_info = track_info;

        play_button.clicked.connect (play_mark_track.trigger);
        play_mark_track.triggered_not_playing.connect (play_pause);

        if (track_info.is_ugc) {
            title = _("Your music track");
            dislike_button.visible = false;
        } else {
            title = _("Music track");
            dislike_button.visible = true;
        }

        child_id = track_info.id;
        subtitle = track_info.title_with_version;

        lyrics_panel.track_id = track_info.id;

        play_mark_track.init_content (track_info.id);
        dislike_button.init_content (track_info.id);
        like_button.init_content (track_info.id);
        save_stack.init_content (track_info.id);

        load_content.begin ();
    }

    async void load_content () {
        YaMAPI.SimilarTracks? similar_tracks = null;
        YaMAPI.Lyrics? lyrics = null;

        // TODO: Uncomment when API methods are available in libtape
        // var yam_helper = Application.tape_client.yam_helper;
        // try {
        //     similar_tracks = yield yam_helper.get_track_similar (track_info.id);
        // } catch (Error e) {
        //     debug ("Failed to load similar tracks: %s", e.message);
        // }

        // if (track_info.lyrics_info != null) {
        //     try {
        //         if (track_info.lyrics_info.has_available_sync_lyrics) {
        //             lyrics = yield yam_helper.get_lyrics (track_info.id, true);
        //         } else if (track_info.lyrics_info.has_available_text_lyrics) {
        //             lyrics = yield yam_helper.get_lyrics (track_info.id, false);
        //         }
        //     } catch (Error e) {
        //         debug ("Failed to load lyrics: %s", e.message);
        //     }
        // }

        set_values (similar_tracks, lyrics);
    }

    void set_values (YaMAPI.SimilarTracks? similar_tracks, YaMAPI.Lyrics? lyrics) {
        if (lyrics != null) {
            if (lyrics.is_sync) {
                lyrics_panel.set_sync_lyrics_lines (lyrics.text.to_array ());
            } else {
                lyrics_panel.set_text_lyrics_lines (lyrics.text.to_array ());
            }
            writers_label.label = lyrics.get_writers_names ();
            major_label.label = lyrics.major.pretty_name;
        } else {
            lyrics_box.visible = false;
        }

        if (similar_tracks != null) {
            if (similar_tracks.similar_tracks.size != 0) {
                var track_list = new TrackList.simple ();
                similar_box.append (track_list);
                track_list.set_tracks_base (similar_tracks.similar_tracks, similar_tracks);
            } else {
                similar_box.visible = false;
            }
        } else {
            similar_box.visible = false;
        }

        loading_stack.visible_child_name = "loaded";
    }

    void play_pause () {
        var player = Application.tape_client.player;
        var track_list = new Gee.ArrayList<YaMAPI.Track> ();
        track_list.add (track_info);

        player.start_track_list (
            track_list,
            "various",
            null,
            0,
            null
        );
    }
}

