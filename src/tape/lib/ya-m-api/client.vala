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

using Tape.YaMAPI.Rotor;
using ApiBase;

public sealed class Tape.YaMAPI.Client : Object {

    const string USER_AGENT = "libtape";
    const string YAM_BASE_URL = "https://api.music.yandex.net";

    public Session session { private get; construct; }

    public AuthType auth_type { get; construct; }

    public string token { internal get; set construct; default = ""; }

    public Account.About? me { get; private set; default = null; }

    public string? cookies_path { get; construct; default = null; }

    public CookieJarType cookie_jar_type { get; construct; default = NONE; }

    public bool is_init_complete {
        get {
            return me != null;
        }
    }

    Client () {}

    public Client.with_token (string token) {
        Object (
            session: new Session (USER_AGENT),
            token: token,
            auth_type: AuthType.TOKEN
        );
    }

    public Client.with_cookie (string cookie_path, CookieJarType cookie_jar_type) {
        AuthType auth_type;
        switch (cookie_jar_type) {
            case DB:
                auth_type = COOKIES_DB;
                break;

            case TEXT:
                auth_type = COOKIES_TEXT;
                break;

            default:
                assert_not_reached ();
        }

        Object (
            session: new Session (USER_AGENT),
            cookie_jar_type: cookie_jar_type,
            cookies_path: cookie_path,
            auth_type: auth_type
        );
    }

    construct {
        reload_cookies ();

        session.add_headers_preset (
            "device",
            {{
                "X-Yandex-Music-Device",
                "os=%s; os_version=%s; manufacturer=%s; model=%s; clid=; device_id=random; uuid=random".printf (
                    Environment.get_os_info (OsInfoKey.NAME),
                    Environment.get_os_info (OsInfoKey.VERSION),
                    "Cassette Dev Team",
                    "Yandex Music API"
                )
            }}
        );
    }

    public void reload_cookies () {
        if (cookies_path != null && cookie_jar_type != NONE) {
            session.init_cookies (cookie_jar_type, cookies_path);
        }
    }

    public async void init (
        int priority = Priority.DEFAULT,
        Cancellable? cancellable = null
    ) throws SoupError, JsonError, BadStatusCodeError, CantUseError {
        if (auth_type != TOKEN) {
            var datalist = Datalist<string> ();
            with (datalist) {
                set_data ("grant_type", "sessionid");
                set_data ("client_id", "23cabbbdc6cd418abb4b39c32c41195d");
                set_data ("client_secret", "53bc75238f0c4d08a118e51fe9203300");
                set_data ("host", "oauth.yandex.ru");
            }

            PostContent post_content = { PostContentType.X_WWW_FORM_URLENCODED };
            post_content.set_datalist (datalist);

            var request = new Request.POST ("https://oauth.yandex.ru/token");
            request.add_post_content (post_content);

            var bytes = yield session.exec_async (request, priority, cancellable);

            var jsoner = new Jsoner.from_bytes (bytes, { "access_token" }, Case.SNAKE);

            var val = jsoner.deserialize_value ();

            if (val.type () == Type.STRING) {
                token = val.get_string ();
            }
        }

        if (token != "") {
            session.add_headers_preset (
                "default",
                {
                    { "Authorization", @"OAuth $token" },
                    { "X-Yandex-Music-Client", "YandexMusicAndroid/24023231" }
                }
            );
            session.add_headers_preset (
                "auth",
                {
                    { "Authorization", @"OAuth $token" }
                }
            );

            me = yield account_about (priority, cancellable);
            if (me != null) {
                if (!me.has_plus) {
                    throw new CantUseError.NO_PLUS ("No Plus Subscription");
                }
            }
        } else {
            throw new SoupError.INTERNAL (_("No token provided"));
        }
    }

    /**
     * Получит содержимое по url
     *
     * @param url   url, по котором нужно получить контент
     *
     * @return      контент в байтах
     */
    public async Bytes get_content_of (
        string url,
        int priority = Priority.DEFAULT,
        Cancellable? cancellable = null
    ) throws SoupError, BadStatusCodeError {
        return yield session.exec_async (new Request.GET (url), priority, cancellable);
    }

    string fix_uid (string? uid) throws SoupError {
        if (uid != null) {
            return uid;
        }

        if (me != null) {
            return me.uid;
        }

        throw new SoupError.INTERNAL (_("Authorization not completed"));
    }

    /**
     *
     */
    public async void account_experiments () throws SoupError, JsonError, BadStatusCodeError {
        assert_not_reached ();
    }

    /**
     *
     */
    public async void account_experiments_details () throws SoupError, JsonError, BadStatusCodeError {
        assert_not_reached ();
    }

    /**
     *
     */
    public async void account_settings () throws SoupError, JsonError, BadStatusCodeError {
        assert_not_reached ();
    }

    /**
     * Получение информации о текущем пользователе
     */
    public async Account.About account_about (
        int priority = Priority.DEFAULT,
        Cancellable? cancellable = null
    ) throws SoupError, JsonError, BadStatusCodeError {
        var request = new Request.GET (@"$(YAM_BASE_URL)/account/about");
        request.presets = { "default" };

        var bytes = yield session.exec_async (
            request,
            priority,
            cancellable
        );

        var jsoner = new Jsoner.from_bytes (bytes, { "result" }, Case.CAMEL);

        return yield jsoner.deserialize_object_async<Account.About> ();
    }

    /**
     * Get album information with tracks
     */
    public async Album albums_with_tracks (
        string album_id,
        bool rich_tracks,
        int priority = Priority.DEFAULT,
        Cancellable? cancellable = null
    ) throws SoupError, JsonError, BadStatusCodeError {
        var request = new Request.GET (@"$(YAM_BASE_URL)/albums/$album_id/with-tracks");
        with (request) {
            presets = { "default" };
            add_param ("richTracks", rich_tracks.to_string ());
        }

        var bytes = yield session.exec_async (
            request,
            priority,
            cancellable
        );
        var jsoner = new Jsoner.from_bytes (bytes, { "result" }, Case.CAMEL);

        // Creation function for nested arrays (ArrayList<ArrayList<Track>> for Album.volumes)
        SubCollectionCreationFunc create_nested_array = (out collection, element_type) => {
            if (element_type == typeof (Track)) {
                collection = new Gee.ArrayList<Track> ();
            } else {
                collection = new Gee.ArrayList<Object> ();
            }
        };

        return yield jsoner.deserialize_object_async<Album> (create_nested_array);
    }

    /**
     *
     */
    public async Playlist playlist (
        string playlist_uuid,
        bool resume_stream,
        bool rich_tracks,
        int priority = Priority.DEFAULT,
        Cancellable? cancellable = null
    ) throws SoupError, JsonError, BadStatusCodeError {
        var request = new Request.GET (@"$(YAM_BASE_URL)/playlist/$playlist_uuid");
        with (request) {
            presets = { "default" };
            add_param ("resumeStream", resume_stream.to_string ());
            add_param ("richTracks", rich_tracks.to_string ());
        }

        var bytes = yield session.exec_async (
            request,
            priority,
            cancellable
        );
        var jsoner = new Jsoner.from_bytes (bytes, { "result" }, Case.CAMEL);

        return yield jsoner.deserialize_object_async<Playlist> ();
    }

    /**
     *
     */
    public async void playlists (
        int priority = Priority.DEFAULT,
        Cancellable? cancellable = null
    ) throws SoupError, JsonError, BadStatusCodeError {
        assert_not_reached ();
    }

    /**
     *
     */
    public async void artists_tracks (
        string artist_id,
        int priority = Priority.DEFAULT,
        Cancellable? cancellable = null
    ) throws SoupError, JsonError, BadStatusCodeError {
        assert_not_reached ();
    }

    /**
     *
     */
    public async void artists_track_ids (
        string artist_id,
        int priority = Priority.DEFAULT,
        Cancellable? cancellable = null
    ) throws SoupError, JsonError, BadStatusCodeError {
        assert_not_reached ();
    }

    /**
     *
     */
    public async void artists_safe_direct_albums (
        string artist_id,
        int priority = Priority.DEFAULT,
        Cancellable? cancellable = null
    ) throws SoupError, JsonError, BadStatusCodeError {
        assert_not_reached ();
    }

    /**
     *
     */
    public async void artists_brief_info (
        string artist_id,
        int priority = Priority.DEFAULT,
        Cancellable? cancellable = null
    ) throws SoupError, JsonError, BadStatusCodeError {
        assert_not_reached ();
    }

    /**
     *
     */
    public async void artists_similar (
        string artist_id,
        int priority = Priority.DEFAULT,
        Cancellable? cancellable = null
    ) throws SoupError, JsonError, BadStatusCodeError {
        assert_not_reached ();
    }

    /**
     *
     */
    public async void artists_discography_albums (
        string artist_id,
        int priority = Priority.DEFAULT,
        Cancellable? cancellable = null
    ) throws SoupError, JsonError, BadStatusCodeError {
        assert_not_reached ();
    }

    /**
     *
     */
    public async void artists_direct_albums (
        string artist_id,
        int priority = Priority.DEFAULT,
        Cancellable? cancellable = null
    ) throws SoupError, JsonError, BadStatusCodeError {
        assert_not_reached ();
    }

    /**
     *
     */
    public async void artists_also_albums (
        string artist_id,
        int priority = Priority.DEFAULT,
        Cancellable? cancellable = null
    ) throws SoupError, JsonError, BadStatusCodeError {
        assert_not_reached ();
    }

    /**
     *
     */
    public async void artists_concerts (
        string artist_id,
        int priority = Priority.DEFAULT,
        Cancellable? cancellable = null
    ) throws SoupError, JsonError, BadStatusCodeError {
        assert_not_reached ();
    }

    /**
     *
     */
    public async void users_playlists_list_kinds (
        string? uid = null,
        int priority = Priority.DEFAULT,
        Cancellable? cancellable = null
    ) throws SoupError, JsonError, BadStatusCodeError {
        fix_uid (uid);
    }

    /**
     *
     */
    public async void users_playlists (
        string? uid = null,
        int priority = Priority.DEFAULT,
        Cancellable? cancellable = null
    ) throws SoupError, JsonError, BadStatusCodeError {
        fix_uid (uid);
    }

    /**
     *
     */
    public async Gee.ArrayList<Playlist> users_playlists_list (
        string? uid = null,
        int priority = Priority.DEFAULT,
        Cancellable? cancellable = null
    ) throws SoupError, JsonError,
    BadStatusCodeError {
        var real_uid = fix_uid (uid);

        var request = new Request.GET (@"$(YAM_BASE_URL)/users/$real_uid/playlists/list");
        request.presets = { "default" };

        Bytes bytes = yield session.exec_async (
            request,
            priority,
            cancellable
        );
        var jsoner = new Jsoner.from_bytes (bytes, { "result" }, Case.CAMEL);

        return yield jsoner.deserialize_array_async<Playlist> ();
    }

    /**
     *
     */
    public async Playlist users_playlists_playlist (
        string playlist_kind,
        bool rich_tracks,
        string? uid = null,
        int priority = Priority.DEFAULT,
        Cancellable? cancellable = null
    ) throws SoupError, JsonError, BadStatusCodeError {
        var real_uid = fix_uid (uid);

        var request = new Request.GET (@"$(YAM_BASE_URL)/users/$real_uid/playlists/$playlist_kind");
        with (request) {
            presets = { "default" };
            add_param ("richTracks", rich_tracks.to_string ());
        }

        var bytes = yield session.exec_async (
            request,
            priority,
            cancellable
        );
        var jsoner = new Jsoner.from_bytes (bytes, { "result" }, Case.CAMEL);

        return yield jsoner.deserialize_object_async<Playlist> ();
    }

    /**
     *
     */
    public async void users_playlists_playlist_change_relative (
        string playlist_kind,
        string? uid = null,
        int priority = Priority.DEFAULT,
        Cancellable? cancellable = null
    ) throws SoupError, JsonError, BadStatusCodeError {
        fix_uid (uid);
    }

    public async bool users_playlists_delete (
        string? uid,
        string kind,
        int priority = Priority.DEFAULT,
        Cancellable? cancellable = null
    ) throws SoupError, JsonError, BadStatusCodeError {
        var real_uid = fix_uid (uid);

        var request = new Request.POST (@"$(YAM_BASE_URL)/users/$real_uid/playlists/$kind/delete");
        with (request) {
            presets = { "default" };
        }

        Bytes bytes = yield session.exec_async (
            request,
            priority,
            cancellable
        );

        var jsoner = new Jsoner.from_bytes (bytes, { "result" }, Case.CAMEL);
        try {
            var value = jsoner.deserialize_value ();
            // Check if result is a boolean true or string "ok"
            if (value.type () == Type.BOOLEAN) {
                return value.get_boolean ();
            } else if (value.type () == Type.STRING) {
                return value.get_string () == "ok";
            }
            // If we got a value, assume success
            return true;
        } catch (ApiBase.JsonError e) {
        return false;
        }
    }

    public async Playlist users_playlists_change (
        string? uid,
        string kind,
        string diff,
        int revision = 1,
        int priority = Priority.DEFAULT,
        Cancellable? cancellable = null
    ) throws SoupError, JsonError, BadStatusCodeError {
        var real_uid = fix_uid (uid);

        var datalist = Datalist<string> ();
        with (datalist) {
            set_data ("kind", kind);
            set_data ("revision", revision.to_string ());
            set_data ("diff", diff);
        }

        PostContent post_content = { PostContentType.X_WWW_FORM_URLENCODED };
        post_content.set_datalist (datalist);

        var request = new Request.POST (@"$(YAM_BASE_URL)/users/$real_uid/playlists/$kind/change");
        with (request) {
            presets = { "default" };
            add_post_content (post_content);
        }

        Bytes bytes = yield session.exec_async (
            request,
            priority,
            cancellable
        );

        var jsoner = new Jsoner.from_bytes (bytes, { "result" }, Case.CAMEL);

        return yield jsoner.deserialize_object_async<Playlist> ();
    }

    public async Playlist users_playlists_create (
        string? uid,
        string title,
        PlaylistVisible visibility = PlaylistVisible.PRIVATE,
        int priority = Priority.DEFAULT,
        Cancellable? cancellable = null
    ) throws SoupError, JsonError, BadStatusCodeError {
        var real_uid = fix_uid (uid);

        var datalist = Datalist<string> ();
        with (datalist) {
            set_data ("title", title);
            set_data ("visibility", visibility.to_string ());
        }

        PostContent post_content = { PostContentType.X_WWW_FORM_URLENCODED };
        post_content.set_datalist (datalist);

        var request = new Request.POST (@"$(YAM_BASE_URL)/users/$real_uid/playlists/create");
        with (request) {
            presets = { "default" };
            add_post_content (post_content);
        }

        Bytes bytes = yield session.exec_async (
            request,
            priority,
            cancellable
        );

        var jsoner = new Jsoner.from_bytes (bytes, { "result" }, Case.CAMEL);

        return yield jsoner.deserialize_object_async<Playlist> ();
    }

    public async Playlist users_playlists_name (
        string? uid,
        string kind,
        string new_name,
        int priority = Priority.DEFAULT,
        Cancellable? cancellable = null
    ) throws SoupError, JsonError, BadStatusCodeError {
        var real_uid = fix_uid (uid);

        var datalist = Datalist<string> ();
        datalist.set_data ("value", new_name);

        PostContent post_content = { PostContentType.X_WWW_FORM_URLENCODED };
        post_content.set_datalist (datalist);

        var request = new Request.POST (@"$(YAM_BASE_URL)/users/$real_uid/playlists/$kind/name");
        with (request) {
            presets = { "default" };
            add_post_content (post_content);
        }

        Bytes bytes = yield session.exec_async (
            request,
            priority,
            cancellable
        );

        var jsoner = new Jsoner.from_bytes (bytes, { "result" }, Case.CAMEL);

        return yield jsoner.deserialize_object_async<Playlist> ();
    }

    public async PlaylistRecommendations users_playlists_recommendations (
        string? uid,
        string kind,
        int priority = Priority.DEFAULT,
        Cancellable? cancellable = null
    ) throws SoupError, JsonError,
    BadStatusCodeError {
        var real_uid = fix_uid (uid);

        var request = new Request.GET (@"$(YAM_BASE_URL)/users/$real_uid/playlists/$kind/recommendations");
        request.presets = { "default" };

        var bytes = yield session.exec_async (
            request,
            priority,
            cancellable
        );

        var jsoner = new Jsoner.from_bytes (bytes, { "result" }, Case.CAMEL);

        return yield jsoner.deserialize_object_async<PlaylistRecommendations> ();
    }

    public async Playlist users_playlists_visibility (
        string? uid,
        string kind,
        string visibility,
        int priority = Priority.DEFAULT,
        Cancellable? cancellable = null
    ) throws SoupError, JsonError, BadStatusCodeError {
        var real_uid = fix_uid (uid);

        var datalist = Datalist<string> ();
        datalist.set_data ("value", visibility);

        PostContent post_content = { PostContentType.X_WWW_FORM_URLENCODED };
        post_content.set_datalist (datalist);

        var request = new Request.POST (@"$(YAM_BASE_URL)/users/$real_uid/playlists/$kind/visibility");
        with (request) {
            presets = { "default" };
            add_post_content (post_content);
        }

        var bytes = yield session.exec_async (
            request,
            priority,
            cancellable
        );

        var jsoner = new Jsoner.from_bytes (bytes, { "result" }, Case.CAMEL);

        return yield jsoner.deserialize_object_async<Playlist> ();
    }

    //  public async Playlist users_palylists_cover_upload (
    //      string? uid,
    //      string kind,
    //      uint8[] new_cover,
    //      string filename,
    //      string content_type,
    //      int priority = Priority.DEFAULT,
    //      Cancellable? cancellable = null
    //  ) throws SoupError, JsonError, BadStatusCodeError {
    //      var real_uid = fix_uid (uid);

    //      var post_builder = new StringBuilder ();

    //      post_builder.append (Uuid.string_random ());
    //      post_builder.append_printf ("Content-Disposition: form-data; name=\"image\"; filename=\"%s\"\n", filename);
    //      post_builder.append_printf ("Content-Type: %s\n", content_type);
    //      post_builder.append_printf ("Content-Length: %d\n", new_cover.length);
    //      post_builder.append ("\n");
    //      post_builder.append ((string) new_cover);

    //      PostContent post_content = { PostContentType.X_WWW_FORM_URLENCODED, post_builder.free_and_steal () };

    //      Bytes bytes = yield session.post_async (
    //          @"$(YAM_BASE_URL)/users/$uid/playlists/$kind/cover/upload",
    //          { "default" },
    //          post_content,
    //          null,
    //          null,
    //          priority,
    //          cancellable
    //      );

    //      var jsoner = new Jsoner.from_bytes (bytes, { "result" }, Case.CAMEL);

    //      return (Playlist) yield jsoner.deserialize_object_async (typeof (Playlist));
    //  }

    //  public async Playlist users_palylists_cover_clear (
    //      string? uid,
    //      string kind,
    //      uint8[] new_cover,
    //      int priority = Priority.DEFAULT,
    //      Cancellable? cancellable = null
    //  ) throws SoupError, JsonError, BadStatusCodeError {
    //      var real_uid = fix_uid (uid);

    //      Bytes bytes = yield session.post_async (
    //          @"$(YAM_BASE_URL)/users/$uid/playlists/$kind/cover/clear",
    //          { "default" },
    //          null,
    //          null,
    //          null,
    //          priority,
    //          cancellable
    //      );

    //      var jsoner = new Jsoner.from_bytes (bytes, { "result" }, Case.CAMEL);

    //      return (Playlist) yield jsoner.deserialize_object_async (typeof (Playlist));
    //  }

    //  /**
    //   *
    //   */
    //  public async void users_likes_albums (
    //      string? uid = null,
    //      int priority = Priority.DEFAULT,
    //      Cancellable? cancellable = null
    //  ) throws SoupError, JsonError, BadStatusCodeError {
    //      var real_uid = fix_uid (uid);
    //  }

    //  /**
    //   *
    //   */
    //  public async void users_likes_artists (
    //      string? uid = null,
    //      int priority = Priority.DEFAULT,
    //      Cancellable? cancellable = null
    //  ) throws SoupError, JsonError, BadStatusCodeError {
    //      var real_uid = fix_uid (uid);
    //  }

    //  /**
    //   *
    //   */
    public async Gee.ArrayList<LikedPlaylist> users_likes_playlists (
        string? uid = null,
        int priority = Priority.DEFAULT,
        Cancellable? cancellable = null
    ) throws SoupError, JsonError, BadStatusCodeError {
        var real_uid = fix_uid (uid);

        var request = new Request.GET (@"$(YAM_BASE_URL)/users/$real_uid/likes/playlists");
        request.presets = { "default" };

        Bytes bytes = yield session.exec_async (
            request,
            priority,
            cancellable
        );
        var jsoner = new Jsoner.from_bytes (bytes, { "result" }, Case.CAMEL);

        var playlist_array = new Gee.ArrayList<LikedPlaylist> ();
        yield jsoner.deserialize_array_into_async (playlist_array);
        return playlist_array;
    }

    /**
     *
     */
    public async int64 users_likes_tracks_add (
        string track_id,
        string? uid = null,
        int priority = Priority.DEFAULT,
        Cancellable? cancellable = null
    ) throws SoupError, JsonError, BadStatusCodeError {
        var real_uid = fix_uid (uid);

        var datalist = Datalist<string> ();
        datalist.set_data ("track-id", track_id);

        PostContent post_content = { PostContentType.X_WWW_FORM_URLENCODED };
        post_content.set_datalist (datalist);

        var request = new Request.POST (@"$(YAM_BASE_URL)/users/$real_uid/likes/tracks/add");
        with (request) {
            presets = { "default" };
            add_post_content (post_content);
        }

        var bytes = yield session.exec_async (
            request,
            priority,
            cancellable
        );
        var jsoner = new Jsoner.from_bytes (bytes, { "result", "revision" }, Case.CAMEL);

        var value = jsoner.deserialize_value ();

        if (value.type () == Type.INT64) {
            return value.get_int64 ();
        }
        return 0;
    }

    /**
     *
     */
    public async int64 users_likes_tracks_remove (
        string track_id,
        string? uid = null,
        int priority = Priority.DEFAULT,
        Cancellable? cancellable = null
    ) throws SoupError, JsonError, BadStatusCodeError {
        var real_uid = fix_uid (uid);

        var request = new Request.POST (@"$(YAM_BASE_URL)/users/$real_uid/likes/tracks/$track_id/remove");
        request.presets = { "default" };

        var bytes = yield session.exec_async (
            request,
            priority,
            cancellable
        );
        var jsoner = new Jsoner.from_bytes (bytes, { "result", "revision" }, Case.CAMEL);

        var value = jsoner.deserialize_value ();

        if (value.type () == Type.INT64) {
            return value.get_int64 ();
        }
        return 0;
    }

    public async Gee.ArrayList<TrackShort> users_dislikes_tracks (
        string? uid,
        int if_modified_since_revision = 0,
        int priority = Priority.DEFAULT,
        Cancellable? cancellable = null
    ) throws SoupError, JsonError, BadStatusCodeError {
        var real_uid = fix_uid (uid);

        var request = new Request.GET (@"$(YAM_BASE_URL)/users/$real_uid/dislikes/tracks");
        with (request) {
            presets = { "default" };
            add_param ("if_modified_since_revision", if_modified_since_revision.to_string ());
        }

        var bytes = yield session.exec_async (
            request,
            priority,
            cancellable
        );
        var jsoner = new Jsoner.from_bytes (bytes, { "result", "library", "tracks" }, Case.CAMEL);

        var our_array = new Gee.ArrayList<TrackShort> ();
        yield jsoner.deserialize_array_into_async (our_array);

        return our_array;
    }

    /**
     *
     */
    public async int64 users_dislikes_tracks_add (
        string track_id,
        string? uid = null,
        int priority = Priority.DEFAULT,
        Cancellable? cancellable = null
    ) throws SoupError, JsonError, BadStatusCodeError {
        var real_uid = fix_uid (uid);

        var datalist = Datalist<string> ();
        datalist.set_data ("track-id", track_id);

        PostContent post_content = { PostContentType.X_WWW_FORM_URLENCODED };
        post_content.set_datalist (datalist);

        var request = new Request.POST (@"$(YAM_BASE_URL)/users/$real_uid/dislikes/tracks/add");
        with (request) {
            presets = { "default" };
            add_post_content (post_content);
        }

        var bytes = yield session.exec_async (
            request,
            priority,
            cancellable
        );
        var jsoner = new Jsoner.from_bytes (bytes, { "result", "revision" }, Case.CAMEL);

        var value = jsoner.deserialize_value ();

        if (value.type () == Type.INT64) {
            return value.get_int64 ();
        }
        return 0;
    }

    /**
     *
     */
    public async int64 users_dislikes_tracks_remove (
        string track_id,
        string? uid = null,
        int priority = Priority.DEFAULT,
        Cancellable? cancellable = null
    ) throws SoupError, JsonError, BadStatusCodeError {
        var real_uid = fix_uid (uid);

        var request = new Request.POST (@"$(YAM_BASE_URL)/users/$real_uid/dislikes/tracks/$track_id/remove");
        request.presets = { "default" };

        var bytes = yield session.exec_async (
            request,
            priority,
            cancellable
        );
        var jsoner = new Jsoner.from_bytes (bytes, { "result", "revision" }, Case.CAMEL);

        var value = jsoner.deserialize_value ();

        if (value.type () == Type.INT64) {
            return value.get_int64 ();
        }
        return 0;
    }

    /**
     *
     */
    public async bool users_likes_artists_add (
        string artist_id,
        string? uid = null,
        int priority = Priority.DEFAULT,
        Cancellable? cancellable = null
    ) throws SoupError, JsonError, BadStatusCodeError {
        var real_uid = fix_uid (uid);

        var datalist = Datalist<string> ();
        datalist.set_data ("artist-id", artist_id);

        PostContent post_content = { PostContentType.X_WWW_FORM_URLENCODED };
        post_content.set_datalist (datalist);

        var request = new Request.POST (@"$(YAM_BASE_URL)/users/$real_uid/likes/artists/add");
        with (request) {
            presets = { "default" };
            add_post_content (post_content);
        }

        var bytes = yield session.exec_async (
            request,
            priority,
            cancellable
        );
        var jsoner = new Jsoner.from_bytes (bytes, { "result" }, Case.CAMEL);

        var value = jsoner.deserialize_value ();

        if (value.type () == Type.STRING) {
            return value.get_string () == "ok";
        }
        return false;
    }

    /**
     *
     */
    public async bool users_likes_artists_remove (
        string artist_id,
        string? uid = null,
        int priority = Priority.DEFAULT,
        Cancellable? cancellable = null
    ) throws SoupError, JsonError, BadStatusCodeError {
        var real_uid = fix_uid (uid);

        var request = new Request.POST (@"$(YAM_BASE_URL)/users/$real_uid/likes/artists/$artist_id/remove");
        request.presets = { "default" };

        var bytes = yield session.exec_async (
            request,
            priority,
            cancellable
        );
        var jsoner = new Jsoner.from_bytes (bytes, { "result" }, Case.CAMEL);

        var value = jsoner.deserialize_value ();

        if (value.type () == Type.STRING) {
            return value.get_string () == "ok";
        }
        return false;
    }

    /**
     *
     */
    public async bool users_dislikes_artists_add (
        string artist_id,
        string? uid = null,
        int priority = Priority.DEFAULT,
        Cancellable? cancellable = null
    ) throws SoupError, JsonError, BadStatusCodeError {
        var real_uid = fix_uid (uid);

        var datalist = Datalist<string> ();
        datalist.set_data ("artist-id", artist_id);

        PostContent post_content = { PostContentType.X_WWW_FORM_URLENCODED };
        post_content.set_datalist (datalist);

        var request = new Request.POST (@"$(YAM_BASE_URL)/users/$real_uid/dislikes/artists/add");
        with (request) {
            presets = { "default" };
            add_post_content (post_content);
        }

        var bytes = yield session.exec_async (
            request,
            priority,
            cancellable
        );
        var jsoner = new Jsoner.from_bytes (bytes, { "result" }, Case.CAMEL);

        var value = jsoner.deserialize_value ();

        if (value.type () == Type.STRING) {
            return value.get_string () == "ok";
        }
        return false;
    }

    /**
     *
     */
    public async bool users_dislikes_artists_remove (
        string artist_id,
        string? uid = null,
        int priority = Priority.DEFAULT,
        Cancellable? cancellable = null
    ) throws SoupError, JsonError, BadStatusCodeError {
        var real_uid = fix_uid (uid);

        var request = new Request.POST (@"$(YAM_BASE_URL)/users/$real_uid/dislikes/artists/$artist_id/remove");
        request.presets = { "default" };

        var bytes = yield session.exec_async (
            request,
            priority,
            cancellable
        );
        var jsoner = new Jsoner.from_bytes (bytes, { "result" }, Case.CAMEL);

        var value = jsoner.deserialize_value ();

        if (value.type () == Type.STRING) {
            return value.get_string () == "ok";
        }
        return false;
    }

    /**
     *
     */
    public async bool users_likes_albums_add (
        string album_id,
        string? uid = null,
        int priority = Priority.DEFAULT,
        Cancellable? cancellable = null
    ) throws SoupError, JsonError, BadStatusCodeError {
        var real_uid = fix_uid (uid);

        var datalist = Datalist<string> ();
        datalist.set_data ("album-id", album_id);

        PostContent post_content = { PostContentType.X_WWW_FORM_URLENCODED };
        post_content.set_datalist (datalist);

        var request = new Request.POST (@"$(YAM_BASE_URL)/users/$real_uid/likes/albums/add");
        with (request) {
            presets = { "default" };
            add_post_content (post_content);
        }

        var bytes = yield session.exec_async (
            request,
            priority,
            cancellable
        );
        var jsoner = new Jsoner.from_bytes (bytes, { "result" }, Case.CAMEL);

        var value = jsoner.deserialize_value ();

        if (value.type () == Type.STRING) {
            return value.get_string () == "ok";
        }
        return false;
    }

    /**
     *
     */
    public async bool users_likes_albums_remove (
        string album_id,
        string? uid = null,
        int priority = Priority.DEFAULT,
        Cancellable? cancellable = null
    ) throws SoupError, JsonError, BadStatusCodeError {
        var real_uid = fix_uid (uid);

        var request = new Request.POST (@"$(YAM_BASE_URL)/users/$real_uid/likes/albums/$album_id/remove");
        request.presets = { "default" };

        var bytes = yield session.exec_async (
            request,
            priority,
            cancellable
        );
        var jsoner = new Jsoner.from_bytes (bytes, { "result" }, Case.CAMEL);

        var value = jsoner.deserialize_value ();

        if (value.type () == Type.STRING) {
            return value.get_string () == "ok";
        }
        return false;
    }

    /**
     *
     */
    public async bool users_likes_playlists_add (
        string playlist_uid,
        string owner_uid,
        string playlist_kind,
        string? uid = null,
        int priority = Priority.DEFAULT,
        Cancellable? cancellable = null
    ) throws SoupError, JsonError, BadStatusCodeError {
        var real_uid = fix_uid (uid);

        var datalist = Datalist<string> ();
        with (datalist) {
            set_data ("playlist-uuid", playlist_uid);
            set_data ("owner-uid", owner_uid);
            set_data ("kind", playlist_kind);
        }

        PostContent post_content = { PostContentType.X_WWW_FORM_URLENCODED };
        post_content.set_datalist (datalist);

        var request = new Request.POST (@"$(YAM_BASE_URL)/users/$real_uid/likes/playlists/add");
        with (request) {
            presets = { "default" };
            add_post_content (post_content);
        }

        var bytes = yield session.exec_async (
            request,
            priority,
            cancellable
        );
        var jsoner = new Jsoner.from_bytes (bytes, { "result" }, Case.CAMEL);

        var value = jsoner.deserialize_value ();

        if (value.type () == Type.STRING) {
            return value.get_string () == "ok";
        }
        return false;
    }

    /**
     *
     */
    public async bool users_likes_playlists_remove (
        string playlist_uid,
        string? uid = null,
        int priority = Priority.DEFAULT,
        Cancellable? cancellable = null
    ) throws SoupError, JsonError, BadStatusCodeError {
        var real_uid = fix_uid (uid);

        var request = new Request.POST (@"$(YAM_BASE_URL)/users/$real_uid/likes/playlists/$playlist_uid/remove");
        request.presets = { "default" };

        var bytes = yield session.exec_async (
            request,
            priority,
            cancellable
        );
        var jsoner = new Jsoner.from_bytes (bytes, { "result" }, Case.CAMEL);

        var value = jsoner.deserialize_value ();

        if (value.type () == Type.STRING) {
            return value.get_string () == "ok";
        }
        return false;
    }

    //  /**
    //   *
    //   */
    //  public async void users_presaves_add (
    //      string? uid = null,
    //      int priority = Priority.DEFAULT,
    //      Cancellable? cancellable = null
    //  ) throws SoupError, JsonError, BadStatusCodeError {
    //      var real_uid = fix_uid (uid);
    //  }

    //  /**
    //   *
    //   */
    //  public async void users_presaves_remove (
    //      string? uid = null,
    //      int priority = Priority.DEFAULT,
    //      Cancellable? cancellable = null
    //  ) throws SoupError, JsonError, BadStatusCodeError {
    //      var real_uid = fix_uid (uid);
    //  }

    //  /**
    //   *
    //   */
    //  public async void users_search_history (
    //      string? uid = null,
    //      int priority = Priority.DEFAULT,
    //      Cancellable? cancellable = null
    //  ) throws SoupError, JsonError, BadStatusCodeError {
    //      var real_uid = fix_uid (uid);
    //  }

    //  /**
    //   *
    //   */
    //  public async void users_search_history_clear (
    //      string? uid = null,
    //      int priority = Priority.DEFAULT,
    //      Cancellable? cancellable = null
    //  ) throws SoupError, JsonError, BadStatusCodeError {
    //      var real_uid = fix_uid (uid);
    //  }

    /**
     * Получение данных о библиотеке пользователя
     */
    public async Library.AllIds library_all_ids (
        int priority = Priority.DEFAULT,
        Cancellable? cancellable = null
    ) throws SoupError, JsonError, BadStatusCodeError {
        var request = new Request.GET (@"$(YAM_BASE_URL)/library/all-ids");
        request.presets = { "default" };

        var bytes = yield session.exec_async (
            request,
            priority,
            cancellable
        );

        var jsoner = new Jsoner.from_bytes (bytes, { "result" }, Case.CAMEL);

        return yield jsoner.deserialize_object_async<Library.AllIds> ();
    }

    //  /**
    //   *
    //   */
    //  public async void landing3_metatags (
    //      int priority = Priority.DEFAULT,
    //      Cancellable? cancellable = null
    //  ) throws SoupError, JsonError, BadStatusCodeError {
    //      assert_not_reached ();
    //  }

    //  /**
    //   *
    //   */
    //  public async void metatags_metatag (
    //      string metatag,
    //      int priority = Priority.DEFAULT,
    //      Cancellable? cancellable = null
    //  ) throws SoupError, JsonError, BadStatusCodeError {
    //      assert_not_reached ();
    //  }

    //  /**
    //   *
    //   */
    //  public async void metatags_albums (
    //      string metatag,
    //      int priority = Priority.DEFAULT,
    //      Cancellable? cancellable = null
    //  ) throws SoupError, JsonError, BadStatusCodeError {
    //      assert_not_reached ();
    //  }

    //  /**
    //   *
    //   */
    //  public async void metatags_artists (
    //      string metatag,
    //      int priority = Priority.DEFAULT,
    //      Cancellable? cancellable = null
    //  ) throws SoupError, JsonError, BadStatusCodeError {
    //      assert_not_reached ();
    //  }

    //  /**
    //   *
    //   */
    //  public async void metatags_playlists (
    //      string metatag,
    //      int priority = Priority.DEFAULT,
    //      Cancellable? cancellable = null
    //  ) throws SoupError, JsonError, BadStatusCodeError {
    //      assert_not_reached ();
    //  }

    //  /**
    //   *
    //   */
    //  public async void top_category (
    //      string category,
    //      int priority = Priority.DEFAULT,
    //      Cancellable? cancellable = null
    //  ) throws SoupError, JsonError, BadStatusCodeError {
    //      assert_not_reached ();
    //  }

    //  /**
    //   *
    //   */
    //  public async void rotor_station_info (
    //      string station_id,
    //      int priority = Priority.DEFAULT,
    //      Cancellable? cancellable = null
    //  ) throws SoupError, JsonError, BadStatusCodeError {
    //      assert_not_reached ();
    //  }

    //  /**
    //   *
    //   */
    //  public async void rotor_station_stream (
    //      int priority = Priority.DEFAULT,
    //      Cancellable? cancellable = null
    //  ) throws SoupError, JsonError, BadStatusCodeError {
    //      assert_not_reached ();
    //  }

    /**
     *
     */
    public async StationTracks rotor_session_new (
        SessionNew session_new,
        int priority = Priority.DEFAULT,
        Cancellable? cancellable = null
    ) throws SoupError, JsonError, BadStatusCodeError {
        PostContent post_content = {
            PostContentType.JSON,
            yield ApiBase.Jsoner.serialize_async (session_new, Case.CAMEL)
        };

        var request = new Request.POST (@"$(YAM_BASE_URL)/rotor/session/new");
        with (request) {
            presets = { "default" };
            add_post_content (post_content);
        }

        var bytes = yield session.exec_async (
            request,
            priority,
            cancellable
        );

        var jsoner = new Jsoner.from_bytes (bytes, { "result" }, Case.CAMEL);

        return yield jsoner.deserialize_object_async<StationTracks> ();
    }

    /**
     *
     */
    public async StationTracks rotor_session_tracks (
        string radio_session_id,
        Rotor.Queue queue,
        int priority = Priority.DEFAULT,
        Cancellable? cancellable = null
    ) throws SoupError, JsonError, BadStatusCodeError {
        PostContent post_content = {
            PostContentType.JSON,
            yield ApiBase.Jsoner.serialize_async (queue, Case.CAMEL)
        };

        var request = new Request.POST (@"$(YAM_BASE_URL)/rotor/session/$radio_session_id/tracks");
        with (request) {
            presets = { "default" };
            add_post_content (post_content);
        }

        var bytes = yield session.exec_async (
            request,
            priority,
            cancellable
        );

        var jsoner = new Jsoner.from_bytes (bytes, { "result" }, Case.CAMEL);

        return yield jsoner.deserialize_object_async<StationTracks> ();
    }

    /**
     *
     */
    public async void rotor_session_feedback (
        string radio_session_id,
        Rotor.Feedback feedback,
        int priority = Priority.DEFAULT,
        Cancellable? cancellable = null
    ) throws SoupError, JsonError, BadStatusCodeError {
        PostContent post_content = {
            PostContentType.JSON,
            yield ApiBase.Jsoner.serialize_async (feedback, Case.CAMEL)
        };

        var request = new Request.POST (@"$(YAM_BASE_URL)/rotor/session/$radio_session_id/feedback");
        with (request) {
            presets = { "default" };
            add_post_content (post_content);
        }

        yield session.exec_async (
            request,
            priority,
            cancellable
        );
    }

    /**
     * Метод для получения всех возможных настроек волны
     *
     * @return  объект `YaMAPI.Rotor.Settings`, содержащий все настройки
     */
    public async Rotor.Settings rotor_wave_settings (
        int priority = Priority.DEFAULT,
        Cancellable? cancellable = null
    ) throws SoupError, JsonError, BadStatusCodeError {
        var request = new Request.GET (@"$(YAM_BASE_URL)/rotor/wave/settings");
        with (request) {
            presets = { "default" };
            add_param ("language", get_language ());
        }

        var bytes = yield session.exec_async (
            request,
            priority,
            cancellable
        );

        var jsoner = new Jsoner.from_bytes (bytes, { "result" }, Case.CAMEL);

        return yield jsoner.deserialize_object_async<Rotor.Settings> ();
    }

    /**
     * Получение последней прослушиваемой волны текущим пользователем
     */
    public async Rotor.Wave rotor_wave_last (
        int priority = Priority.DEFAULT,
        Cancellable? cancellable = null
    ) throws SoupError, JsonError, BadStatusCodeError {
        var request = new Request.GET (@"$(YAM_BASE_URL)/rotor/wave/last");
        with (request) {
            presets = { "default" };
            add_param ("language", get_language ());
        }

        var bytes = yield session.exec_async (
            request,
            priority,
            cancellable
        );

        var jsoner = new Jsoner.from_bytes (bytes, { "result" }, Case.CAMEL);

        return yield jsoner.deserialize_object_async<Wave> ();
    }

    /**
     * Сбросить значение последней прослушиваемой станции.
     *
     * @return  успех выполнения
     */
    public async bool rotor_wave_last_reset (
        int priority = Priority.DEFAULT,
        Cancellable? cancellable = null
    ) throws SoupError, JsonError, BadStatusCodeError {
        var request = new Request.POST (@"$(YAM_BASE_URL)/rotor/wave/last/reset");
        request.presets = { "default" };

        var bytes = yield session.exec_async (
            request,
            priority,
            cancellable
        );

        var jsoner = new Jsoner.from_bytes (bytes, { "result" }, Case.CAMEL);

        try {
            return jsoner.deserialize_value ().get_string () == "ok";
        } catch (Error e) {
            return false;
        }
    }

    public async Dashboard rotor_stations_dashboard (
        int priority = Priority.DEFAULT,
        Cancellable? cancellable = null
    ) throws SoupError, JsonError, BadStatusCodeError {
        var request = new Request.GET (@"$(YAM_BASE_URL)/rotor/stations/dashboard");
        with (request) {
            presets = { "default", "device" };
            add_param ("language", get_language ());
        }

        var bytes = yield session.exec_async (
            request,
            priority,
            cancellable
        );
        var jsoner = new Jsoner.from_bytes (bytes, { "result" }, Case.CAMEL);

        return yield jsoner.deserialize_object_async<Dashboard> ();
    }

    public async Gee.ArrayList<Station> rotor_stations_list (
        int priority = Priority.DEFAULT,
        Cancellable? cancellable = null
    ) throws SoupError, JsonError, BadStatusCodeError {
        var request = new Request.GET (@"$(YAM_BASE_URL)/rotor/stations/list");
        with (request) {
            presets = { "default", "device" };
            add_param ("language", get_language ());
        }

        var bytes = yield session.exec_async (
            request,
            priority,
            cancellable
        );
        var jsoner = new Jsoner.from_bytes (bytes, { "result" }, Case.CAMEL);

        return yield jsoner.deserialize_array_async<Station> ();
    }

    //  /**
    //   *
    //   */
    //  public async void search_feedback (
    //      int priority = Priority.DEFAULT,
    //      Cancellable? cancellable = null
    //  ) throws SoupError, JsonError, BadStatusCodeError {
    //      assert_not_reached ();
    //  }

    //  /**
    //   *
    //   */
    //  public async void search_instant_mixed (
    //      int priority = Priority.DEFAULT,
    //      Cancellable? cancellable = null
    //  ) throws SoupError, JsonError, BadStatusCodeError {
    //      assert_not_reached ();
    //  }

    /**
     * Search for tracks by query
     */
    public async TrackHeap? search_tracks (
        string query,
        int page = 0,
        int page_size = 36,
        int priority = Priority.DEFAULT,
        Cancellable? cancellable = null
    ) throws SoupError, JsonError, BadStatusCodeError {
        var request = new Request.GET (@"$(YAM_BASE_URL)/search/instant/mixed");
        with (request) {
            presets = { "default" };
            add_param ("text", query);
            add_param ("type", "album,artist,playlist,track,wave,podcast,podcast_episode,clip");
            add_param ("page", page.to_string ());
            add_param ("pageSize", page_size.to_string ());
            add_param ("withLikesCount", "true");
            add_param ("withBestResults", "true");
        }

        var bytes = yield session.exec_async (
            request,
            priority,
            cancellable
        );

        try {
            // Parse the response: root has "result" object, which contains "results" array
            // We need to manually parse because "type" is a reserved keyword
            var parser = new Json.Parser ();
            parser.load_from_data ((string) bytes.get_data (), (ssize_t) bytes.length);
            
            var root_node = parser.get_root ();
            if (root_node == null || root_node.get_node_type () != Json.NodeType.OBJECT) {
                warning ("Search response root is not an object");
                return null;
            }

            var root_obj = root_node.get_object ();
            if (!root_obj.has_member ("result")) {
                warning ("Search response has no 'result' member");
                return null;
            }

            var result_node = root_obj.get_member ("result");
            if (result_node.get_node_type () != Json.NodeType.OBJECT) {
                warning ("Search response 'result' is not an object");
                return null;
            }

            var result_obj = result_node.get_object ();
            if (!result_obj.has_member ("results")) {
                warning ("Search response 'result' has no 'results' member");
                return null;
            }

            var results_node = result_obj.get_member ("results");
            if (results_node.get_node_type () != Json.NodeType.ARRAY) {
                warning ("Search response 'results' is not an array");
                return null;
            }

            var results_array = results_node.get_array ();
            var track_list = new Gee.ArrayList<Track> ();

            for (uint i = 0; i < results_array.get_length (); i++) {
                var item_node = results_array.get_element (i);
                if (item_node.get_node_type () != Json.NodeType.OBJECT) {
                    continue;
                }

                var item_obj = item_node.get_object ();
                if (!item_obj.has_member ("type")) {
                    continue;
                }

                var type_node = item_obj.get_member ("type");
                if (type_node.get_node_type () != Json.NodeType.VALUE) {
                    continue;
                }

                var type_value = type_node.get_value ();
                if (type_value.get_string () != "track") {
                    continue;
                }

                if (!item_obj.has_member ("track")) {
                    continue;
                }

                var track_node = item_obj.get_member ("track");
                if (track_node.get_node_type () != Json.NodeType.OBJECT) {
                    continue;
                }
                
                // Serialize the track node to JSON string and parse it
                var generator = new Json.Generator ();
                generator.set_root (track_node);
                generator.pretty = false;
                var track_json = generator.to_data (null);
                
                try {
                    var track_jsoner = new Jsoner (track_json, null, Case.CAMEL);
                    var track = yield track_jsoner.deserialize_object_async<Track> ();
                    if (track != null) {
                        track_list.add (track);
                    }
                } catch (Error e) {
                    debug ("Failed to deserialize track: %s", e.message);
                    continue;
                }
            }

            if (track_list.size > 0) {
                var track_heap = new TrackHeap ();
                track_heap.tracks = track_list;
                return track_heap;
            }
            
            return null;
        } catch (Error e) {
            warning ("Failed to parse search results: %s", e.message);
            return null;
        }
    }

    /**
     * Get collection playlist with liked tracks
     */
    public async CollectionPlaylistWithLikes? collection_playlist_with_likes (
        int count = 8,
        int priority = Priority.DEFAULT,
        Cancellable? cancellable = null
    ) throws SoupError, JsonError, BadStatusCodeError {
        var request = new Request.GET (@"$(YAM_BASE_URL)/landing-blocks/collection/playlist-with-likes");
        with (request) {
            presets = { "default" };
            add_param ("count", count.to_string ());
        }

        var bytes = yield session.exec_async (
            request,
            priority,
            cancellable
        );

        var jsoner = new Jsoner.from_bytes (bytes, { "result" }, Case.CAMEL);
        return yield jsoner.deserialize_object_async<CollectionPlaylistWithLikes> ();
    }

    /**
     * Get collection liked albums
     */
    public async CollectionLikedAlbums? collection_liked_albums (
        int count = 8,
        int priority = Priority.DEFAULT,
        Cancellable? cancellable = null
    ) throws SoupError, JsonError, BadStatusCodeError {
        var request = new Request.GET (@"$(YAM_BASE_URL)/landing-blocks/collection/albums-liked-and-albums-presaved");
        with (request) {
            presets = { "default" };
            add_param ("count", count.to_string ());
        }

        var bytes = yield session.exec_async (
            request,
            priority,
            cancellable
        );

        var jsoner = new Jsoner.from_bytes (bytes, { "result" }, Case.CAMEL);
        return yield jsoner.deserialize_object_async<CollectionLikedAlbums> ();
    }

    /**
     * Get collection liked playlists
     */
    public async CollectionLikedPlaylists? collection_liked_playlists (
        int count = 8,
        int priority = Priority.DEFAULT,
        Cancellable? cancellable = null
    ) throws SoupError, JsonError, BadStatusCodeError {
        var request = new Request.GET (
            @"$(YAM_BASE_URL)/landing-blocks/collection/playlists-liked-and-playlists-created");
        with (request) {
            presets = { "default" };
            add_param ("count", count.to_string ());
        }

        var bytes = yield session.exec_async (
            request,
            priority,
            cancellable
        );

        var jsoner = new Jsoner.from_bytes (bytes, { "result" }, Case.CAMEL);
        return yield jsoner.deserialize_object_async<CollectionLikedPlaylists> ();
    }

    /**
     * Get new releases landing block
     */
    public async Landing.NewReleases? landing_blocks_new_releases (
        int priority = Priority.DEFAULT,
        Cancellable? cancellable = null
    ) throws SoupError, JsonError, BadStatusCodeError {
        var request = new Request.GET (@"$(YAM_BASE_URL)/landing-blocks/new-releases");
        request.presets = { "default" };

        var bytes = yield session.exec_async (
            request,
            priority,
            cancellable
        );

        var json_string = (string) bytes.get_data ();
        debug ("[landing_blocks_new_releases] Response: %s",
               json_string.substring (0, json_string.length > 500 ? 500 : json_string.length));
        
        // API returns: {"newReleases": […]} but class expects "items"
        // Parse manually to map newReleases -> items
        var parser = new Json.Parser ();
        try {
            parser.load_from_data (json_string, -1);
        } catch (GLib.Error e) {
            throw new JsonError.INVALID ("Failed to parse JSON: %s".printf (e.message));
        }
        var root_node = parser.get_root ();
        
        var new_releases = new Landing.NewReleases ();
        
        // Creation function for nested arrays
        SubCollectionCreationFunc create_nested_array = (out collection, element_type) => {
            if (element_type == typeof (Track)) {
                collection = new Gee.ArrayList<Track> ();
            } else {
                collection = new Gee.ArrayList<Object> ();
            }
        };
        
        // Get newReleases array from JSON
        if (root_node.get_node_type () == Json.NodeType.OBJECT) {
            var root_obj = root_node.get_object ();
            if (root_obj.has_member ("newReleases")) {
                var items_array_node = root_obj.get_member ("newReleases");
                if (items_array_node.get_node_type () == Json.NodeType.ARRAY) {
                    var items_array = items_array_node.get_array ();
                    
                    // Deserialize each item
                    foreach (var item_node in items_array.get_elements ()) {
                        var item_json_string = Json.to_string (item_node, false);
                        var item_jsoner = new Jsoner (item_json_string, null, Case.CAMEL);
                        
                        try {
                            var item = item_jsoner.deserialize_object<Landing.NewReleasesItem> (create_nested_array);
                            new_releases.items.add (item);
                        } catch (JsonError e) {
                            warning ("Failed to deserialize NewReleasesItem: %s", e.message);
                        }
                    }
                }
            }
        }
        
        debug ("[landing_blocks_new_releases] Parsed %d items", new_releases.items.size);
        return new_releases;
    }

    /**
     * Get in-style landing block
     */
    public async Landing.InStyle? landing_blocks_in_style (
        int priority = Priority.DEFAULT,
        Cancellable? cancellable = null
    ) throws SoupError, JsonError, BadStatusCodeError {
        var request = new Request.GET (@"$(YAM_BASE_URL)/landing-blocks/in-style");
        request.presets = { "default" };

        var bytes = yield session.exec_async (
            request,
            priority,
            cancellable
        );

        // API response structure: {"inStyleTabs": […]} (no result wrapper)
        // JSON field is camelCase "inStyleTabs", but Jsoner converts camelCase to kebab-case "in-style-tabs"
        // Property name "inStyleTabs" doesn't match kebab-case. We need to manually map it.
        var json_string = (string) bytes.get_data ();
        debug ("[landing_blocks_in_style] Response: %s",
               json_string.substring (0, json_string.length > 500 ? 500 : json_string.length));
        
        var parser = new Json.Parser ();
        try {
            parser.load_from_data (json_string, -1);
        } catch (GLib.Error e) {
            throw new JsonError.INVALID ("Failed to parse JSON: %s".printf (e.message));
        }
        var root_node = parser.get_root ();
        
        var in_style = new Landing.InStyle ();
        
        // Creation function for nested arrays (ArrayList<ArrayList<Track>> for Album.volumes)
        SubCollectionCreationFunc create_nested_array = (out collection, element_type) => {
            if (element_type == typeof (Track)) {
                collection = new Gee.ArrayList<Track> ();
            } else {
                collection = new Gee.ArrayList<Object> ();
            }
        };
        
        // Get inStyleTabs array from JSON
        if (root_node.get_node_type () == Json.NodeType.OBJECT) {
            var root_obj = root_node.get_object ();
            if (root_obj.has_member ("inStyleTabs")) {
                var tabs_array_node = root_obj.get_member ("inStyleTabs");
                if (tabs_array_node.get_node_type () == Json.NodeType.ARRAY) {
                    var tabs_array = tabs_array_node.get_array ();
                    
                    // Deserialize each tab with proper nested object handling
                    foreach (var tab_node in tabs_array.get_elements ()) {
                        // Create Jsoner for this tab node
                        var tab_json_string = Json.to_string (tab_node, false);
                        var tab_jsoner = new Jsoner (tab_json_string, null, Case.CAMEL);
                        
                        // Deserialize the tab with creation function for nested arrays
                        try {
                            var tab = tab_jsoner.deserialize_object<Landing.InStyleTab> (create_nested_array);
                            in_style.inStyleTabs.add (tab);
                        } catch (JsonError e) {
                            warning ("Failed to deserialize InStyleTab: %s", e.message);
                        }
                    }
                }
            }
        }
        
        return in_style;
    }

    /**
     * Get waves landing block (discoveries)
     */
    public async Landing.Waves? landing_blocks_waves (
        int priority = Priority.DEFAULT,
        Cancellable? cancellable = null
    ) throws SoupError, JsonError, BadStatusCodeError {
        var request = new Request.GET (@"$(YAM_BASE_URL)/landing-blocks/waves");
        request.presets = { "default" };

        var bytes = yield session.exec_async (
            request,
            priority,
            cancellable
        );

        var json_string = (string) bytes.get_data ();
        debug ("[landing_blocks_waves] Response: %s",
               json_string.substring (0, json_string.length > 500 ? 500 : json_string.length));
        
        // API returns: {"waves": [{"id":"mix","title":"топ","items":[…]}]}
        // Preserve groups structure for tabbed display
        var parser = new Json.Parser ();
        try {
            parser.load_from_data (json_string, -1);
        } catch (GLib.Error e) {
            throw new JsonError.INVALID ("Failed to parse JSON: %s".printf (e.message));
        }
        var root_node = parser.get_root ();
        
        var waves = new Landing.Waves ();
        
        // Get waves array from JSON
        if (root_node.get_node_type () == Json.NodeType.OBJECT) {
            var root_obj = root_node.get_object ();
            if (root_obj.has_member ("waves")) {
                var waves_array_node = root_obj.get_member ("waves");
                if (waves_array_node.get_node_type () == Json.NodeType.ARRAY) {
                    var waves_array = waves_array_node.get_array ();
                    
                    // Process each wave group
                    foreach (var wave_group_node in waves_array.get_elements ()) {
                        if (wave_group_node.get_node_type () == Json.NodeType.OBJECT) {
                            var wave_group_obj = wave_group_node.get_object ();
                            
                            // Create WaveGroup
                            var wave_group = new Landing.WaveGroup ();
                            
                            // Get group id and title
                            if (wave_group_obj.has_member ("id")) {
                                wave_group.id = wave_group_obj.get_string_member ("id") ?? "";
                            }
                            if (wave_group_obj.has_member ("title")) {
                                wave_group.title = wave_group_obj.get_string_member ("title") ?? "";
                            }
                            
                            // Process items in this group
                            if (wave_group_obj.has_member ("items")) {
                                var items_array_node = wave_group_obj.get_member ("items");
                                if (items_array_node.get_node_type () == Json.NodeType.ARRAY) {
                                    var items_array = items_array_node.get_array ();
                                    
                                    // Deserialize each wave item
                                    foreach (var item_node in items_array.get_elements ()) {
                                        if (item_node.get_node_type () == Json.NodeType.OBJECT) {
                                            var item_obj = item_node.get_object ();
                                            
                                            // Create WaveItem
                                            var wave_item = new Landing.WaveItem ();
                                            
                                            // Parse stationId to create Rotor.Id
                                            if (item_obj.has_member ("stationId")) {
                                                var station_id_str = item_obj.get_string_member ("stationId");
                                                if (station_id_str != null) {
                                                    // stationId format: "epoch:twenties" -> type:tag
                                                    var parts = station_id_str.split (":", 2);
                                                    if (parts.length == 2) {
                                                        var station_id = new Rotor.Id ();
                                                        station_id.type_ = parts[0];
                                                        station_id.tag = parts[1];
                                                        
                                                        // Create StationInfo
                                                        var station_info = new Rotor.StationInfo ();
                                                        station_info.id = station_id;
                                                        
                                                        // Create Icon object for the station
                                                        station_info.icon = new YaMAPI.Icon ();
                                                        
                                                        // Map title to name - display name like "2020-е", "Дип-хаус"
                                                        if (item_obj.has_member ("title")) {
                                                            station_info.name =
                                                                item_obj.get_string_member ("title") ?? "";
                                                        }
                                                        
                                                        // Map compactImageUrl to full_image_url
                                                        if (item_obj.has_member ("compactImageUrl")) {
                                                            var url = item_obj.get_string_member ("compactImageUrl");
                                                            if (url != null) {
                                                                // Fix URL format (replace %% with actual size)
                                                            station_info.full_image_url =
                                                                url.replace ("%%", "200x200");
                                                            }
                                                        }
                                                        
                                                        wave_item.station_info = station_info;
                                                        
                                                        // Map header to type_ and value
                                                        if (item_obj.has_member ("header")) {
                                                            // Header like "Моя волна по эпохе" -> type: "epoch"
                                                            // We can infer type from station_id.type_ or header
                                                            wave_item.type_ = station_id.type_;
                                                            wave_item.value = station_info.name;
                                                        } else {
                                                            wave_item.type_ = station_id.type_;
                                                            wave_item.value = station_info.name;
                                                        }
                                                        
                                                        // Add to both group items and flat list
                                                        wave_group.items.add (wave_item);
                                                        waves.items.add (wave_item);
                                                    }
                                                }
                                            }
                                        }
                                    }
                                }
                            }
                            
                            // Add group to waves
                            if (wave_group.items.size > 0) {
                                waves.groups.add (wave_group);
                            }
                        }
                    }
                }
            }
        }
        
        debug ("[landing_blocks_waves] Parsed %d items", waves.items.size);
        return waves;
    }

    /**
     * Get history playlist (recent tracks)
     */
    public async Playlist? landing_block_premiere_recent_tracks (
        int priority = Priority.DEFAULT,
        Cancellable? cancellable = null
    ) throws SoupError, JsonError, BadStatusCodeError {
        var request = new Request.GET (@"$(YAM_BASE_URL)/landing/block/premiere/smart-open-playlist/RECENT_TRACKS");
        request.presets = { "default" };

        var bytes = yield session.exec_async (
            request,
            priority,
            cancellable
        );

        var json_string = (string) bytes.get_data ();
        debug ("[landing_block_premiere_recent_tracks] Response: %s",
               json_string.substring (0, json_string.length > 500 ? 500 : json_string.length));
        
        // API may return playlist directly or wrapped in result
        // Try both formats
        var parser = new Json.Parser ();
        try {
            parser.load_from_data (json_string, -1);
        } catch (GLib.Error e) {
            throw new JsonError.INVALID ("Failed to parse JSON: %s".printf (e.message));
        }
        var root_node = parser.get_root ();
        
        Json.Node? playlist_node = null;
        
        // Check if wrapped in "result"
        if (root_node.get_node_type () == Json.NodeType.OBJECT) {
            var root_obj = root_node.get_object ();
            if (root_obj.has_member ("result")) {
                playlist_node = root_obj.get_member ("result");
            } else {
                // Playlist is at root level
                playlist_node = root_node;
            }
        }
        
        if (playlist_node == null) {
            return null;
        }
        
        // Deserialize playlist
        var playlist_json_string = Json.to_string (playlist_node, false);
        var playlist_jsoner = new Jsoner (playlist_json_string, null, Case.CAMEL);
        
        // Creation function for nested arrays
        SubCollectionCreationFunc create_nested_array = (out collection, element_type) => {
            if (element_type == typeof (Track)) {
                collection = new Gee.ArrayList<Track> ();
            } else {
                collection = new Gee.ArrayList<Object> ();
            }
        };
        
        try {
            var playlist = playlist_jsoner.deserialize_object<Playlist> (create_nested_array);
            // Ensure this smart-open playlist does not inherit "liked" visuals
            // Some APIs omit kind; default "3" would make it look like Liked
            if (playlist != null && (playlist.kind == null || playlist.kind == "3")) {
                playlist.kind = "recent";
            }
            debug ("[landing_block_premiere_recent_tracks] Parsed playlist: %s (%d tracks)",
                   playlist.title ?? "null", playlist.track_count);
            return playlist;
        } catch (Error e) {
            warning ("Failed to deserialize recent tracks playlist: %s", e.message);
            return null;
        }
    }

    /**
     *
     * @param play_id               id сессии прослушивания
     * @param total_played_seconds  общее количество прослушанного времени в секундах
     * @param end_position_seconds  секунда, на которой закончилось прослушивание
     * @param track_length_seconds  общее количество секунд в треке
     * @param track_id              id трека
     * @param album_id              id вльбома, может быть `null`
     * @param from
     * @param context               контекст воспроизведения (То же что и `Queue.context.type`)
     * @param context_item          id контекста, (Тоже же, что и `Queue.context.id`)
     * @param radio_session_id      id сессии волны
     *
     * @return                      успех выполнения
     */
    public async bool plays (
        Play[] play_objs,
        int priority = Priority.DEFAULT,
        Cancellable? cancellable = null
    ) throws SoupError, JsonError, BadStatusCodeError {
        var plays_obj = new Plays ();
        plays_obj.plays.add_all_array (play_objs);

        PostContent post_content = {
            PostContentType.JSON,
            yield ApiBase.Jsoner.serialize_async (plays_obj, Case.CAMEL)
        };

        var request = new Request.POST (@"$(YAM_BASE_URL)/plays");
        with (request) {
            presets = { "default" };
            add_post_content (post_content);
            add_param ("clientNow", Tape.YaMAPI.get_timestamp ());
        }

        var bytes = yield session.exec_async (
            request,
            priority,
            cancellable
        );

        var jsoner = new Jsoner.from_bytes (bytes, { "result" }, Case.CAMEL);

        try {
            return jsoner.deserialize_value ().get_string () == "ok";
        } catch (Error e) {
            return false;
        }
    }

    //  /**
    //   *
    //   */
    //  public async void rewind_slides_user (
    //      int priority = Priority.DEFAULT,
    //      Cancellable? cancellable = null
    //  ) throws SoupError, JsonError, BadStatusCodeError {
    //      assert_not_reached ();
    //  }

    //  /**
    //   *
    //   */
    //  public async void rewind_slides_artist (
    //      string artist_id,
    //      int priority = Priority.DEFAULT,
    //      Cancellable? cancellable = null
    //  ) throws SoupError, JsonError, BadStatusCodeError {
    //      assert_not_reached ();
    //  }

    //  /**
    //   *
    //   */
    //  public async void pins (
    //      int priority = Priority.DEFAULT,
    //      Cancellable? cancellable = null
    //  ) throws SoupError, JsonError, BadStatusCodeError {
    //      assert_not_reached ();
    //  }

    //  /**
    //   *
    //   */
    //  public async void pins_albums (
    //      bool pin,
    //      int priority = Priority.DEFAULT,
    //      Cancellable? cancellable = null
    //  ) throws SoupError, JsonError, BadStatusCodeError {
    //      assert_not_reached ();
    //  }

    //  /**
    //   *
    //   */
    //  public async void pins_playlist (
    //      bool pin,
    //      int priority = Priority.DEFAULT,
    //      Cancellable? cancellable = null
    //  ) throws SoupError, JsonError, BadStatusCodeError {
    //      assert_not_reached ();
    //  }

    //  /**
    //   *
    //   */
    //  public async void pins_artist (
    //      bool pin,
    //      int priority = Priority.DEFAULT,
    //      Cancellable? cancellable = null
    //  ) throws SoupError, JsonError, BadStatusCodeError {
    //      assert_not_reached ();
    //  }

    //  /**
    //   *
    //   */
    //  public async void pins_wave (
    //      bool pin,
    //      int priority = Priority.DEFAULT,
    //      Cancellable? cancellable = null
    //  ) throws SoupError, JsonError, BadStatusCodeError {
    //      assert_not_reached ();
    //  }

    //  /**
    //   *
    //   */
    //  public async void tags_playlist_ids (
    //      string tag_id,
    //      int priority = Priority.DEFAULT,
    //      Cancellable? cancellable = null
    //  ) throws SoupError, JsonError, BadStatusCodeError {
    //      assert_not_reached ();
    //  }

    //  /**
    //   *
    //   */
    //  public async void feed_promotions_promo (
    //      string promo_id,
    //      int priority = Priority.DEFAULT,
    //      Cancellable? cancellable = null
    //  ) throws SoupError, JsonError, BadStatusCodeError {
    //      assert_not_reached ();
    //  }

    public async Gee.ArrayList<Track> tracks (
        string[] id_list,
        bool with_positions = false,
        int priority = Priority.DEFAULT,
        Cancellable? cancellable = null
    ) throws SoupError, JsonError, BadStatusCodeError {
        var datalist = Datalist<string> ();
        with (datalist) {
            set_data ("track-ids", string.joinv (",", id_list));
            set_data ("with-positions", with_positions.to_string ());
        }

        PostContent post_content = { PostContentType.X_WWW_FORM_URLENCODED };
        post_content.set_datalist (datalist);

        var request = new Request.POST (@"$(YAM_BASE_URL)/tracks");
        with (request) {
            presets = { "default" };
            add_post_content (post_content);
        }

        var bytes = yield session.exec_async (
            request,
            priority,
            cancellable
        );
        var jsoner = new Jsoner.from_bytes (bytes, { "result" }, Case.CAMEL);

        return yield jsoner.deserialize_array_async<Track> ();
    }

    public async string track_download_url (
        string track_id,
        bool hq = true,
        int priority = Priority.DEFAULT,
        Cancellable? cancellable = null
    ) throws SoupError, JsonError, BadStatusCodeError {
        var di_array = yield tracks_download_info (
            track_id,
            priority,
            cancellable
        );

        int bitrate = hq ? 0 : 500;
        string dl_info_uri = "";
        foreach (DownloadInfo download_info in di_array) {
            if (hq == (bitrate < download_info.bitrate_in_kbps)) {
                bitrate = download_info.bitrate_in_kbps;
                dl_info_uri = download_info.download_info_url;
            }
        }

        return yield form_download_url (
            dl_info_uri,
            priority,
            cancellable
        );
    }

    public async Gee.ArrayList<DownloadInfo> tracks_download_info (
        string track_id,
        int priority = Priority.DEFAULT,
        Cancellable? cancellable = null
    ) throws SoupError, JsonError, BadStatusCodeError {
        var request = new Request.GET (@"$(YAM_BASE_URL)/tracks/$track_id/download-info");
        request.presets = { "default" };

        var bytes = yield session.exec_async (
            request,
            priority,
            cancellable
        );
        var jsoner = new Jsoner.from_bytes (bytes, { "result" }, Case.CAMEL);

        var di_array = new Gee.ArrayList<DownloadInfo> ();
        yield jsoner.deserialize_array_into_async (di_array);

        return di_array;
    }

    async string form_download_url (
        string dl_info_url,
        int priority = Priority.DEFAULT,
        Cancellable? cancellable = null
    ) throws SoupError, JsonError, BadStatusCodeError {
        Bytes bytes = yield get_content_of (
            dl_info_url,
            priority,
            cancellable
        );
        string xml_string = (string) bytes.get_data ();

        Xml.Parser.init ();
        var doc = Xml.Parser.parse_memory (xml_string, xml_string.length);

        var root = doc->get_root_element ();

        var children = root->children;
        var host = children->get_content ();

        children = children->next;
        var path = children->get_content ();

        children = children->next;
        var ts = children->get_content ();

        children = children->next;
        children = children->next;
        var s = children->get_content ();

        var str = "XGRlBW9FXlekgbPrRHuSiA" + path[1:] + s;
        var sign = Checksum.compute_for_string (ChecksumType.MD5, str, str.length);

        return @"https://$host/get-mp3/$sign/$ts/$path";
    }

    public async Lyrics track_lyrics (
        string track_id,
        bool is_sync,
        int priority = Priority.DEFAULT,
        Cancellable? cancellable = null
    ) throws SoupError, JsonError, BadStatusCodeError {
        string format = is_sync ? "LRC" : "TEXT";
        string timestamp = new DateTime.now_utc ().to_unix ().to_string ();
        string msg = @"$track_id$timestamp";

        var hmac = new Hmac (ChecksumType.SHA256, "p93jhgh689SBReK6ghtw62".data);
        hmac.update (msg.data);
        uint8[] hmac_sign = new uint8[32];
        size_t digest_length = 32;
        hmac.get_digest (hmac_sign, ref digest_length);
        string sign = Base64.encode (hmac_sign);

        var request = new Request.GET (@"$(YAM_BASE_URL)/tracks/$track_id/lyrics");
        with (request) {
            presets = { "default" };
            add_param ("format", format);
            add_param ("timeStamp", timestamp);
            add_param ("sign", sign);
        }

        var bytes = yield session.exec_async (
            request,
            priority,
            cancellable
        );
        var jsoner = new Jsoner.from_bytes (bytes, { "result" }, Case.CAMEL);

        var lyrics = yield jsoner.deserialize_object_async<Lyrics> ();
        lyrics.is_sync = is_sync;

        return lyrics;
    }

    public async SimilarTracks tracks_similar (
        string track_id,
        int priority = Priority.DEFAULT,
        Cancellable? cancellable = null
    ) throws SoupError, JsonError, BadStatusCodeError {
        var request = new Request.GET (@"$(YAM_BASE_URL)/tracks/$track_id/similar");
        request.presets = { "default" };

        var bytes = yield session.exec_async (
            request,
            priority,
            cancellable
        );
        var jsoner = new Jsoner.from_bytes (bytes, { "result" }, Case.CAMEL);

        return yield jsoner.deserialize_object_async<SimilarTracks> ();
    }
}
