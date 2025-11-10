/*
 * Copyright (C) 2024 Vladimir Romanov
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
 * along with this program. If not, see <https://www.gnu.org/licenses/>.
 *
 * SPDX-License-Identifier: GPL-3.0-or-later
 */

using ApiBase;
using Tape.YaMAPI;

/**
 * Class with helper methods. It may include auto saving some of the objects.
 */
public sealed class Tape.YaMHelper : Object {

    public YaMAPI.Client client { get; construct; }
    public LikesHandler likes_handler { get; default = new LikesHandler (); }
    public ContentHandler content_handler { get; default = new ContentHandler (); }

    public signal void track_likes_start_change (string track_id);
    public signal void track_likes_end_change (string track_id, bool is_liked);

    public signal void track_dislikes_start_change (string track_id);
    public signal void track_dislikes_end_change (string track_id, bool is_disliked);

    public signal void playlist_changed (YaMAPI.Playlist new_playlist);
    public signal void playlists_updated ();
    public signal void playlist_start_delete (string oid);
    public signal void playlist_stop_delete (string oid);

    public bool inited {
        get {
            return client.is_init_complete;
        }
    }

    public signal void init_end ();

    Account.About? _me = null;
    public Account.About me {
        owned get {
            if (_me != null) {
                return _me;
            }

            _me = client.me;
            if (_me == null) {
                string my_uid = root.cachier.storager.db.get_additional_data ("me");
                if (my_uid != null) {
                    _me = (Account.About) root.cachier.storager.load_object_sync (typeof (Account.About), my_uid);
                }

                if (_me == null) {
                    return new Account.About ();
                }
            }

            return _me;
        }
    }

    internal YaMHelper (
        string? cookies_path = null,
        string? token = null
    ) {
        assert ((cookies_path != null || token != null) && (cookies_path == null || token == null));

        YaMAPI.Client c;

        if (cookies_path != null) {
            c = new YaMAPI.Client.with_cookie (cookies_path, ApiBase.CookieJarType.DB);
        } else if (token != null) {
            c = new YaMAPI.Client.with_token (token);
        } else {
            assert_not_reached ();
        }

        Object (client: c);
    }

    public bool is_me (string? uid) {
        return uid == null || uid == me.uid;
    }

    public bool is_my_liked (string? uid, string kind) {
        return is_me (uid) && kind == "3";
    }

    public async void init () throws JsonError, SoupError, CantUseError, BadStatusCodeError {
        assert (!client.is_init_complete);

        yield client.init ();

        root.cachier.storager.db.set_additional_data ("me", me.oid);
        yield root.cachier.storager.save_object (me, false);

        likes_handler.full_update (yield client.library_all_ids ());

        _me = null;

        init_end ();
    }

    //
    public async Album? get_album_info (string album_id) throws CantUseError {
        Album? album_info = null;

        try {
            album_info = yield client.albums_with_tracks (album_id, true);
        } catch (ApiBase.BadStatusCodeError e) {
            // Convert BadStatusCodeError to CantUseError
            throw new Tape.CantUseError.NO_PLUS (e.message);
        } catch (Tape.CantUseError e) {
            throw e;
        } catch (Error e) {
            // Log other errors and return null
            warning ("API error: %s", e.message);
            return null;
        }

        if (album_info != null) {
            // Save album to cache if needed
            var object_location = root.cachier.storager.object_cache_location (album_info.get_type (), album_info.oid);
            if (object_location.is_tmp && root.settings.can_cache) {
                yield root.cachier.storager.save_object (album_info, true);
                root.cachier.controller.change_state (
                    ContentType.ALBUM,
                    album_info.oid,
                    CacheingState.TEMP
                );
            }
        }

        return album_info;
    }

    public async Playlist? get_playlist_info_old (
        string? uid = null,
        string kind = "3"
    ) throws BadStatusCodeError, CantUseError {
        Playlist? playlist_info = null;

        try {
            playlist_info = yield client.users_playlists_playlist (kind, true, uid);

            if (is_my_liked (uid, kind)) {
                // Update likes handler with tracks from liked playlist
                // Note: likes_handler.full_update should handle this via library_all_ids
                // This is kept for backward compatibility
            }

            if (playlist_info.tracks.size != 0) {
                if (playlist_info.tracks[0].track == null) {
                    string[] tracks_ids = new string[playlist_info.tracks.size];
                    for (int i = 0; i < tracks_ids.length; i++) {
                        tracks_ids[i] = playlist_info.tracks[i].id;
                    }

                    var track_list = yield client.tracks (tracks_ids);
                    playlist_info.set_track_list (track_list);
                }
            }

            // Сохраняет объект, если он не сохранен в data
            // Постоянными объектами занимается уже Cachier.Job
            var object_location = root.cachier.storager.object_cache_location (
                playlist_info.get_type (), playlist_info.oid);
            if (object_location.is_tmp && root.settings.can_cache) {
                yield root.cachier.storager.save_object (playlist_info, true);
                root.cachier.controller.change_state (
                    ContentType.PLAYLIST,
                    playlist_info.oid,
                    CacheingState.TEMP
                );
            }
        } catch (ApiBase.BadStatusCodeError e) {
            // Re-throw bad status codes
            throw e;
        } catch (Error e) {
            // Log other errors and return null
            warning ("API error: %s", e.message);
            return null;
        }

        return playlist_info;
    }

    public async Playlist? get_playlist_info (string playlist_uuid) throws BadStatusCodeError, CantUseError {
        Playlist? playlist_info = null;

        try {
            playlist_info = yield client.playlist (playlist_uuid, false, true);

            if (is_my_liked (playlist_info.uid, playlist_info.kind)) {
                // Update likes handler with tracks from liked playlist
                // Note: likes_handler.full_update should handle this via library_all_ids
                // This is kept for backward compatibility
            }

            if (playlist_info.tracks.size != 0) {
                if (playlist_info.tracks[0].track == null) {
                    string[] tracks_ids = new string[playlist_info.tracks.size];
                    for (int i = 0; i < tracks_ids.length; i++) {
                        tracks_ids[i] = playlist_info.tracks[i].id;
                    }

                    var track_list = yield client.tracks (tracks_ids);
                    playlist_info.set_track_list (track_list);
                }
            }

            // Сохраняет объект, если он не сохранен в data
            // Постоянными объектами занимается уже Cachier.Job
            var object_location = root.cachier.storager.object_cache_location (
                playlist_info.get_type (), playlist_info.oid);
            if (object_location.is_tmp && root.settings.can_cache) {
                yield root.cachier.storager.save_object (playlist_info, true);
                root.cachier.controller.change_state (
                    ContentType.PLAYLIST,
                    playlist_info.oid,
                    CacheingState.TEMP
                );
            }
        } catch (ApiBase.BadStatusCodeError e) {
            // Ignore bad status codes - API may be temporarily unavailable
        } catch (Error e) {
            // Log other errors but don't fail
            warning ("API error: %s", e.message);
        }

        return playlist_info;
    }

    public async void send_play (YaMAPI.Play[] play_objs) throws CantUseError {
        debug ("[YAM_HELPER] send_play: Starting, play_objs.length=%d", play_objs.length);
        if (play_objs.length > 0) {
            debug ("[YAM_HELPER] send_play: First play_obj: track_id=%s, context=%s, context_item=%s",
                   play_objs[0].track_id, play_objs[0].context, play_objs[0].context_item ?? "(null)");
        }
        try {
            debug ("[YAM_HELPER] send_play: Calling client.plays()");
            yield client.plays (play_objs);
            debug ("[YAM_HELPER] send_play: client.plays() completed successfully");
        } catch (ApiBase.BadStatusCodeError e) {
            // Ignore bad status codes - API may be temporarily unavailable
            debug ("[YAM_HELPER] send_play: BadStatusCodeError: %d", e.code);
        } catch (Error e) {
            // Log other errors but don't fail
            warning ("API error: %s", e.message);
            debug ("[YAM_HELPER] send_play: Error: %s", e.message);
        }
        debug ("[YAM_HELPER] send_play: Completed");
    }

    public async string? get_download_uri (string track_id, bool is_hq) throws CantUseError {
        string? track_uri = null;

        try {
            track_uri = yield client.track_download_url (track_id, is_hq);
        } catch (ApiBase.BadStatusCodeError e) {
            // Ignore bad status codes - API may be temporarily unavailable
        } catch (Error e) {
            // Log other errors but don't fail
            warning ("API error: %s", e.message);
        }

        return track_uri;
    }

    public async void like (
        ContentType content_type,
        string content_id,
        string? playlist_owner = null,
        string? playlist_kind = null
    ) throws CantUseError {
        track_likes_start_change (content_id);
        bool is_ok = false;

        try {
            switch (content_type) {
                case ContentType.TRACK:
                    is_ok = (yield client.users_likes_tracks_add (content_id)) != 0;
                    break;

                case ContentType.PLAYLIST:
                    is_ok = yield client.users_likes_playlists_add (content_id, playlist_owner, playlist_kind);
                    break;

                case ContentType.ALBUM:
                    is_ok = yield client.users_likes_albums_add (content_id);
                    break;

                default:
                    // ARTIST and other types not yet supported via ContentType enum
                    warning ("Like not supported for content type: %u", content_type);
                    break;
            }
        } catch (ApiBase.BadStatusCodeError e) {
            // Ignore bad status codes - API may be temporarily unavailable
        } catch (Error e) {
            // Log other errors but don't fail
            warning ("API error: %s", e.message);
        }

        if (is_ok) {
            likes_handler.add_liked (content_type, content_id);
            track_likes_end_change (content_id, true);
            if (content_type == ContentType.TRACK) {
                likes_handler.remove_disliked (content_id);
                root.player.rotor_feedback (YaMAPI.Rotor.FeedbackType.LIKE, content_id);

                track_dislikes_end_change (content_id, false);
            }
        }
    }

    public async void unlike (
        ContentType content_type,
        string content_id
    ) throws CantUseError {
        track_likes_start_change (content_id);
        bool is_ok = false;

        try {
            switch (content_type) {
                case ContentType.TRACK :
                    is_ok = (yield client.users_likes_tracks_remove (content_id)) != 0;
                    break;

                case ContentType.PLAYLIST :
                    is_ok = yield client.users_likes_playlists_remove (content_id);
                    break;

                case ContentType.ALBUM:
                    is_ok = yield client.users_likes_albums_remove (content_id);
                    break;

                default:
                    // ARTIST and other types not yet supported via ContentType enum
                    warning ("Unlike not supported for content type: %u", content_type);
                    break;
            }
        } catch (ApiBase.BadStatusCodeError e) {
            // Ignore bad status codes - API may be temporarily unavailable
        } catch (Error e) {
            // Log other errors but don't fail
            warning ("API error: %s", e.message);
        }

        if (is_ok) {
            likes_handler.remove_liked (content_type, content_id);
            root.player.rotor_feedback (YaMAPI.Rotor.FeedbackType.UNLIKE, content_id);

            track_likes_end_change (content_id, false);
        }
    }

    public async void dislike (
        ContentType content_type,
        string content_id
    ) throws CantUseError {
        track_dislikes_start_change (content_id);
        bool is_ok = false;

        try {
            switch (content_type) {
                case ContentType.TRACK:
                    is_ok = (yield client.users_dislikes_tracks_add (content_id)) != 0;
                    break;

                default:
                    // Only TRACK is supported for dislikes in current API
                    // ARTIST dislikes not supported via ContentType enum
                    warning ("Dislike not supported for content type: %u", content_type);
                    break;
            }
        } catch (ApiBase.BadStatusCodeError e) {
            // Ignore bad status codes - API may be temporarily unavailable
        } catch (Error e) {
            // Log other errors but don't fail
            warning ("API error: %s", e.message);
        }

        if (is_ok) {
            likes_handler.add_disliked (content_id);
            root.player.rotor_feedback (YaMAPI.Rotor.FeedbackType.DISLIKE, content_id);

            track_dislikes_end_change (content_id, true);
            likes_handler.remove_liked (ContentType.TRACK, content_id);
            track_likes_end_change (content_id, false);
        }
    }

    public async void undislike (
        ContentType content_type,
        string content_id
    ) throws CantUseError {
        track_dislikes_start_change (content_id);
        bool is_ok = false;

        try {
            switch (content_type) {
                case ContentType.TRACK:
                    is_ok = (yield client.users_dislikes_tracks_remove (content_id)) != 0;
                    break;

                default:
                    // Only TRACK is supported for undislikes in current API
                    // ARTIST undislikes not supported via ContentType enum
                    warning ("Undislike not supported for content type: %u", content_type);
                    break;
            }
        } catch (ApiBase.BadStatusCodeError e) {
            // Ignore bad status codes - API may be temporarily unavailable
        } catch (Error e) {
            // Log other errors but don't fail
            warning ("API error: %s", e.message);
        }

        if (is_ok) {
            likes_handler.remove_disliked (content_id);
            root.player.rotor_feedback (YaMAPI.Rotor.FeedbackType.UNDISLIKE, content_id);

            track_dislikes_end_change (content_id, false);
        }
    }

    public async Gee.ArrayList<Playlist>? get_playlist_list (string? uid = null) throws CantUseError {
        Gee.ArrayList<Playlist>? playlist_list = null;

        try {
            playlist_list = yield client.users_playlists_list (uid);

            if (uid == null) {
                string[] playlists_kinds = new string[playlist_list.size];
                for (int i = 0; i < playlist_list.size; i++) {
                    playlists_kinds[i] = playlist_list[i].kind.to_string ();
                }

                root.cachier.storager.db.set_additional_data ("my_playlists", string.joinv (",", playlists_kinds));
            }
        } catch (ApiBase.BadStatusCodeError e) {
            // Ignore bad status codes - API may be temporarily unavailable
        } catch (Error e) {
            // Log other errors but don't fail
            warning ("API error: %s", e.message);
        }

        return playlist_list;
    }

    public async Gee.ArrayList<LikedPlaylist>? get_likes_playlist_list (string? uid = null) throws CantUseError {
        Gee.ArrayList<LikedPlaylist>? playlist_list = null;

        try {
            playlist_list = yield client.users_likes_playlists (uid);
        } catch (ApiBase.BadStatusCodeError e) {
            // Ignore bad status codes - API may be temporarily unavailable
        } catch (Error e) {
            // Log other errors but don't fail
            warning ("API error: %s", e.message);
        }

        return playlist_list;
    }

    public async YaMAPI.SimilarTracks? get_track_similar (string track_id) throws CantUseError {
        YaMAPI.SimilarTracks? similar_tracks = null;

        try {
            similar_tracks = yield client.tracks_similar (track_id);
        } catch (ApiBase.BadStatusCodeError e) {
            // Ignore bad status codes - API may be temporarily unavailable
        } catch (Error e) {
            // Log other errors but don't fail
            warning ("API error: %s", e.message);
        }

        return similar_tracks;
    }

    public async YaMAPI.Lyrics? get_lyrics (string track_id, bool is_sync) throws CantUseError {
        YaMAPI.Lyrics? lyrics = null;

        try {
            lyrics = yield client.track_lyrics (track_id, is_sync);
            var txt = yield load_text (lyrics.download_url);
            lyrics.text = new Gee.ArrayList<string>.wrap (txt.split ("\n"));
        } catch (ApiBase.BadStatusCodeError e) {
            // Ignore bad status codes - API may be temporarily unavailable
        } catch (Error e) {
            // Log other errors but don't fail
            warning ("API error: %s", e.message);
        }

        return lyrics;
    }

    public async string? load_text (string uri) throws CantUseError {
        string? text = null;

        try {
            Bytes? bytes = yield client.get_content_of (uri);
            text = (string) bytes.get_data ();
        } catch (ApiBase.BadStatusCodeError e) {
            // Ignore bad status codes - API may be temporarily unavailable
        } catch (Error e) {
            // Log other errors but don't fail
            warning ("API error: %s", e.message);
        }

        return text;
    }

    // Получает изображение из сети как pixbuf
    public async Bytes? load_image_data (string image_uri) throws CantUseError {
        Bytes? content = null;

        try {
            content = yield client.get_content_of (image_uri);
        } catch (ApiBase.BadStatusCodeError e) {
            // Ignore bad status codes - API may be temporarily unavailable
        } catch (Error e) {
            // Log other errors but don't fail
            warning ("API error: %s", e.message);
        }

        return content;
    }

    public async Bytes? load_track (string track_uri) throws CantUseError {
        Bytes? content = null;

        try {
            content = yield client.get_content_of (track_uri);
        } catch (ApiBase.BadStatusCodeError e) {
            // Ignore bad status codes - API may be temporarily unavailable
        } catch (Error e) {
            // Log other errors but don't fail
            warning ("API error: %s", e.message);
        }

        return content;
    }

    public async Playlist? add_track_to_playlist (Track track_info, Playlist playlist_info) throws CantUseError {
        return yield add_tracks_to_playlist ({ track_info }, playlist_info);
    }

    public async Playlist? add_tracks_to_playlist (
        Track[] tracks,
        Playlist playlist_info
    ) throws CantUseError {
        Playlist? new_playlist = null;

        var diff = new YaMAPI.DifferenceBuilder ();

        diff.add_insert (
            root.settings.add_tracks_to_start ? 0 : playlist_info.track_count,
            tracks
        );

        try {
            new_playlist = yield client.users_playlists_change (
                null,
                playlist_info.kind,
                diff.to_json (),
                playlist_info.revision
            );
            playlist_changed (new_playlist);
        } catch (ApiBase.BadStatusCodeError e) {
            // Ignore bad status codes - API may be temporarily unavailable
        } catch (Error e) {
            // Log other errors but don't fail
            warning ("API error: %s", e.message);
        }

        return new_playlist;
    }

    public async Playlist? remove_tracks_from_playlist (
        string kind,
        int position,
        int revision
    ) throws CantUseError {
        Playlist? new_playlist = null;

        var diff = new YaMAPI.DifferenceBuilder ();

        diff.add_delete (position, position + 1);

        try {
            new_playlist = yield client.users_playlists_change (null, kind, diff.to_json (), revision);
        } catch (ApiBase.BadStatusCodeError e) {
            // Ignore bad status codes - API may be temporarily unavailable
        } catch (Error e) {
            // Log other errors but don't fail
            warning ("API error: %s", e.message);
        }

        playlist_changed (new_playlist);

        return new_playlist;
    }

    public async Playlist? change_playlist_visibility (
        string kind,
        bool is_public
    ) throws CantUseError {
        Playlist? new_playlist = null;

        try {
            new_playlist = yield client.users_playlists_visibility (null, kind, is_public ? "public" : "private");
            playlist_changed (new_playlist);
        } catch (ApiBase.BadStatusCodeError e) {
            // Ignore bad status codes - API may be temporarily unavailable
        } catch (Error e) {
            // Log other errors but don't fail
            warning ("API error: %s", e.message);
        }

        return new_playlist;
    }

    public async Playlist? create_playlist () throws CantUseError {
        Playlist? new_playlist = null;

        try {
            // Translators: name of new created playlist
            new_playlist = yield client.users_playlists_create (null, _("New Playlist"));
            playlists_updated ();
        } catch (ApiBase.BadStatusCodeError e) {
            // Ignore bad status codes - API may be temporarily unavailable
        } catch (Error e) {
            // Log other errors but don't fail
            warning ("API error: %s", e.message);
        }

        return new_playlist;
    }

    public async bool delete_playlist (string kind) throws CantUseError {
        bool is_success = false;

        try {
            playlist_start_delete (kind);
            is_success = yield client.users_playlists_delete (null, kind);
            if (is_success) {
                playlists_updated ();
            } else {
                playlist_stop_delete (kind);
            }
        } catch (ApiBase.BadStatusCodeError e) {
            // Ignore bad status codes - API may be temporarily unavailable
            playlist_stop_delete (kind);
        } catch (Error e) {
            // Log other errors but don't fail
            warning ("API error: %s", e.message);
            playlist_stop_delete (kind);
        }

        return is_success;
    }

    public async Playlist? change_playlist_name (
        string kind,
        string new_name
    ) throws CantUseError {
        Playlist? new_playlist = null;

        try {
            new_playlist = yield client.users_playlists_name (null, kind, new_name);
            playlist_changed (new_playlist);
        } catch (ApiBase.BadStatusCodeError e) {
            // Ignore bad status codes - API may be temporarily unavailable
        } catch (Error e) {
            // Log other errors but don't fail
            warning ("API error: %s", e.message);
        }

        return new_playlist;
    }

    async Gee.ArrayList<YaMAPI.TrackShort>? get_disliked_tracks_short () throws CantUseError {
        Gee.ArrayList<YaMAPI.TrackShort>? trackshort_list = null;

        try {
            trackshort_list = yield client.users_dislikes_tracks (null);
        } catch (ApiBase.BadStatusCodeError e) {
            // Ignore bad status codes - API may be temporarily unavailable
        } catch (Error e) {
            // Log other errors but don't fail
            warning ("API error: %s", e.message);
        }

        return trackshort_list;
    }

    public async YaMAPI.TrackHeap? get_disliked_tracks () throws CantUseError {
        YaMAPI.TrackHeap? track_list = null;

        try {
            var trackshort_list = yield get_disliked_tracks_short ();

            string[] track_ids = new string[trackshort_list.size];
            for (int i = 0; i < track_ids.length; i++) {
                track_ids[i] = trackshort_list[i].id;
            }
            var tracks = yield client.tracks (track_ids);
            track_list = new YaMAPI.TrackHeap ();
            track_list.tracks = tracks;
        } catch (ApiBase.BadStatusCodeError e) {
            // Ignore bad status codes - API may be temporarily unavailable
        } catch (Error e) {
            // Log other errors but don't fail
            warning ("API error: %s", e.message);
        }

        return track_list;
    }

    public async YaMAPI.TrackHeap? get_collection_liked_tracks (int count = 50) throws CantUseError {
        YaMAPI.TrackHeap? track_heap = null;

        try {
            var collection_data = yield client.collection_playlist_with_likes (count);
            debug ("YaMHelper.get_collection_liked_tracks: collection_data=%s, tracks.size=%d",
                collection_data != null ? "not null" : "null",
                collection_data != null ? collection_data.tracks.size : 0);
            if (collection_data != null && collection_data.tracks.size > 0) {
                track_heap = new YaMAPI.TrackHeap ();
                track_heap.tracks = collection_data.tracks;
            }
        } catch (ApiBase.BadStatusCodeError e) {
            warning ("Bad status code for collection liked tracks: %d", e.code);
        } catch (Error e) {
            warning ("Failed to get collection liked tracks: %s", e.message);
        }

        return track_heap;
    }

    public async Gee.ArrayList<YaMAPI.Album>? get_collection_liked_albums (int count = 8) throws CantUseError {
        Gee.ArrayList<YaMAPI.Album>? albums = null;

        try {
            var collection_data = yield client.collection_liked_albums (count);
            debug ("YaMHelper.get_collection_liked_albums: collection_data=%s, tabs.size=%d",
                collection_data != null ? "not null" : "null",
                collection_data != null ? collection_data.tabs.size : 0);
            if (collection_data != null && collection_data.tabs.size > 0) {
                albums = new Gee.ArrayList<YaMAPI.Album> ();
                int total_items = 0;
                foreach (var tab in collection_data.tabs) {
                    debug ("YaMHelper.get_collection_liked_albums: tab.type=%s, tab.items.size=%d",
                           tab.type_, tab.items.size);
                    foreach (var item in tab.items) {
                        total_items++;
                        debug ("YaMHelper.get_collection_liked_albums: item.type=%s, item.data=%s, item.data.album=%s",
                            item.type_, item.data != null ? "not null" : "null",
                            item.data != null && item.data.album != null ? "not null" : "null");
                        // Item has data.album, not item.album directly
                        if (item.data != null && item.data.album != null) {
                            albums.add (item.data.album);
                        }
                    }
                }
                debug ("YaMHelper.get_collection_liked_albums: total_items=%d, albums.size=%d",
                       total_items, albums.size);
            }
        } catch (ApiBase.BadStatusCodeError e) {
            warning ("Bad status code for collection liked albums: %d", e.code);
        } catch (Error e) {
            warning ("Failed to get collection liked albums: %s", e.message);
        }

        return albums;
    }

    public async Gee.ArrayList<YaMAPI.LikedPlaylist>? get_collection_liked_playlists (
        int count = 8) throws CantUseError {
        Gee.ArrayList<YaMAPI.LikedPlaylist>? playlists = null;

        try {
            var collection_data = yield client.collection_liked_playlists (count);
            debug ("YaMHelper.get_collection_liked_playlists: collection_data=%s, tabs.size=%d",
                collection_data != null ? "not null" : "null",
                collection_data != null ? collection_data.tabs.size : 0);
            if (collection_data != null && collection_data.tabs.size > 0) {
                playlists = new Gee.ArrayList<YaMAPI.LikedPlaylist> ();
                int total_items = 0;
                foreach (var tab in collection_data.tabs) {
                    debug ("YaMHelper.get_collection_liked_playlists: tab.type=%s, tab.items.size=%d",
                           tab.type_, tab.items.size);
                    foreach (var item in tab.items) {
                        total_items++;
                        debug (
                            "YaMHelper.get_collection_liked_playlists: item.type=%s, item.data=%s, playlist=%s",
                            item.type_,
                            item.data != null ? "not null" : "null",
                            item.data != null &&
                            item.data.playlist != null ?
                                "not null" : "null");
                        // Item has data.playlist, need to wrap it in LikedPlaylist
                        if (item.data != null && item.data.playlist != null) {
                            var liked_playlist = new YaMAPI.LikedPlaylist ();
                            liked_playlist.playlist = item.data.playlist;
                            playlists.add (liked_playlist);
                        }
                    }
                }
                debug ("YaMHelper.get_collection_liked_playlists: total_items=%d, playlists.size=%d",
                       total_items, playlists.size);
            }
        } catch (ApiBase.BadStatusCodeError e) {
            warning ("Bad status code for collection liked playlists: %d", e.code);
        } catch (Error e) {
            warning ("Failed to get collection liked playlists: %s", e.message);
        }

        return playlists;
    }

    public async YaMAPI.Rotor.StationTracks? start_new_session (string station_id) throws CantUseError {
        YaMAPI.Rotor.StationTracks? station_tracks = null;

        try {
            var ses_new = new YaMAPI.Rotor.SessionNew ();
            ses_new.seeds.add (station_id);

            station_tracks = yield client.rotor_session_new (ses_new);
        } catch (ApiBase.BadStatusCodeError e) {
            // Ignore bad status codes - API may be temporarily unavailable
        } catch (Error e) {
            // Log other errors but don't fail
            warning ("API error: %s", e.message);
        }

        return station_tracks;
    }

    public async void send_rotor_feedback (
        string radio_session_id,
        string batch_id,
        string feedback_type,
        string? track_id = null,
        double total_played_seconds = 0.0
    ) throws CantUseError {

        try {
            var feedback_obj = new YaMAPI.Rotor.Feedback () {
                event = new YaMAPI.Rotor.Event () {
                    type_ = feedback_type,
                    track_id = track_id,
                    total_played_seconds = total_played_seconds
                },
                batch_id = batch_id
            };

            yield client.rotor_session_feedback (
                radio_session_id,
                feedback_obj
            );
        } catch (ApiBase.BadStatusCodeError e) {
            // Ignore bad status codes - API may be temporarily unavailable
        } catch (Error e) {
            // Log other errors but don't fail
            warning ("API error: %s", e.message);
        }
    }

    public async YaMAPI.Rotor.StationTracks? get_session_tracks (
        string radio_session_id,
        Gee.ArrayList<string> queue
    ) throws CantUseError {
        YaMAPI.Rotor.StationTracks? station_tracks = null;

        try {
            var ses_queue = new YaMAPI.Rotor.Queue () {
                queue = queue
            };

            station_tracks = yield client.rotor_session_tracks (radio_session_id, ses_queue);
        } catch (ApiBase.BadStatusCodeError e) {
            // Ignore bad status codes - API may be temporarily unavailable
        } catch (Error e) {
            // Log other errors but don't fail
            warning ("API error: %s", e.message);
        }

        return station_tracks;
    }

    public async YaMAPI.Rotor.Dashboard? get_stations_dashboard () throws CantUseError {
        YaMAPI.Rotor.Dashboard? dashboard = null;

        try {
            dashboard = yield client.rotor_stations_dashboard ();
        } catch (ApiBase.BadStatusCodeError e) {
            // Ignore bad status codes - API may be temporarily unavailable
        } catch (Error e) {
            // Log other errors but don't fail
            warning ("API error: %s", e.message);
        }

        return dashboard;
    }

    public async Gee.ArrayList<YaMAPI.Rotor.Station>? get_all_stations () throws CantUseError {
        Gee.ArrayList<YaMAPI.Rotor.Station>? stations_list = null;

        try {
            stations_list = yield client.rotor_stations_list ();
        } catch (ApiBase.BadStatusCodeError e) {
            // Ignore bad status codes - API may be temporarily unavailable
        } catch (Error e) {
            // Log other errors but don't fail
            warning ("API error: %s", e.message);
        }

        return stations_list;
    }

    public async YaMAPI.Rotor.Settings? get_wave_settings () throws CantUseError {
        YaMAPI.Rotor.Settings? wave_settings = null;

        try {
            wave_settings = yield client.rotor_wave_settings ();
        } catch (ApiBase.BadStatusCodeError e) {
            // Ignore bad status codes - API may be temporarily unavailable
        } catch (Error e) {
            // Log other errors but don't fail
            warning ("API error: %s", e.message);
        }

        return wave_settings;
    }

    public async YaMAPI.Rotor.Wave? get_last_wave () throws CantUseError {
        YaMAPI.Rotor.Wave? last_wave = null;

        try {
            last_wave = yield client.rotor_wave_last ();
        } catch (ApiBase.BadStatusCodeError e) {
            // Ignore bad status codes - API may be temporarily unavailable
        } catch (Error e) {
            // Log other errors but don't fail
            warning ("API error: %s", e.message);
        }

        return last_wave;
    }

    public async void reset_last_wave () throws CantUseError {
        bool is_success = false;

        try {
            is_success = yield client.rotor_wave_last_reset ();
        } catch (ApiBase.BadStatusCodeError e) {
            // Ignore bad status codes - API may be temporarily unavailable
        } catch (Error e) {
            // Log other errors but don't fail
            warning ("API error: %s", e.message);
        }

        yield;
    }
}
