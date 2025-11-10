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

using Gee;

public sealed class Tape.LikesHandler : Object {

    HashModel _liked_tracks = new HashModel ();
    HashModel liked_tracks {
        get {
            return _liked_tracks;
        }
    }
    HashModel _liked_playlists = new HashModel ();
    HashModel liked_playlists {
        get {
            return _liked_playlists;
        }
    }
    HashModel _liked_albums = new HashModel ();
    HashModel liked_albums {
        get {
            return _liked_albums;
        }
    }
    HashModel _liked_artists = new HashModel ();
    HashModel liked_artists {
        get {
            return _liked_artists;
        }
    }

    HashModel _disliked_tracks = new HashModel ();
    HashModel disliked_tracks {
        get {
            return _disliked_tracks;
        }
    }
    HashModel _disliked_artists = new HashModel ();
    HashModel disliked_artists {
        get {
            return _disliked_artists;
        }
    }

    public void full_update (YaMAPI.Library.AllIds ids) {
        _liked_tracks.set_iterator (filter_and_map (ids.default_library, 1));
        _liked_playlists.set_iterator (filter_and_map (ids.playlists, 1));
        _liked_albums.set_iterator (filter_and_map (ids.albums, 1));
        _liked_artists.set_iterator (filter_and_map (ids.artists, 1));

        _disliked_tracks.set_iterator (filter_and_map (ids.default_library, -1));
        _disliked_artists.set_iterator (filter_and_map (ids.artists, -1));
    }

    Iterator<string> filter_and_map (HashMap<string, int> map, int filter_value) {
        return map.filter ((pred) => {
            return pred.value == filter_value;
        }).map<string> ((pred) => {
            return pred.key;
        });
    }

    // Helper methods for checking likes/dislikes
    public bool is_track_liked (string track_id) {
        return _liked_tracks.contains (track_id);
    }

    public bool is_playlist_liked (string playlist_id) {
        return _liked_playlists.contains (playlist_id);
    }

    public bool is_album_liked (string album_id) {
        return _liked_albums.contains (album_id);
    }

    public bool is_track_disliked (string track_id) {
        return _disliked_tracks.contains (track_id);
    }

    // Helper methods for managing likes/dislikes (matching old likes_controller API)
    public void add_liked (ContentType content_type, string content_id) {
        switch (content_type) {
            case ContentType.TRACK:
                _liked_tracks.append (content_id);
                break;
            case ContentType.PLAYLIST:
                _liked_playlists.append (content_id);
                break;
            case ContentType.ALBUM:
                _liked_albums.append (content_id);
                break;
            default:
                break;
        }
    }

    public void remove_liked (ContentType content_type, string content_id) {
        switch (content_type) {
            case ContentType.TRACK:
                _liked_tracks.remove (content_id);
                break;
            case ContentType.PLAYLIST:
                _liked_playlists.remove (content_id);
                break;
            case ContentType.ALBUM:
                _liked_albums.remove (content_id);
                break;
            default:
                break;
        }
    }

    public void add_disliked (string content_id) {
        _disliked_tracks.append (content_id);
    }

    public void remove_disliked (string content_id) {
        _disliked_tracks.remove (content_id);
    }
}
