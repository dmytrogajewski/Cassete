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

[SingleInstance]
public sealed class Tape.Cachier : Object {

    public Storager storager { get; default = new Storager (); }

    public CacheController controller { get; default = new CacheController (); }

    public Jober jober { get; default = new Jober (); }


























    public async static void save_track (YaMAPI.Track track_info) {
        /**
            Функция удобства, объединяющая сохранение аудио и изображения
         */

        download_audio_async.begin (track_info.id);
        get_image.begin (track_info, CoverSize.SMALL);
    }

    public async static void download_audio_async (
        string track_id,
        owned string? track_uri = null,
        bool is_tmp = true
    ) {
        /**
            Скачивание аудио по его id. Если не передан uri трека, то uri будет самостоятельно загружен.
            Аргумент is_tmp определяет место, куда будет загружено аудио
         */

        if (root.cachier.storager.audio_cache_location (track_id).file != null) {
            root.cachier.controller.stop_loading (ContentType.TRACK, track_id, null);
            return;
        }

        root.cachier.controller.start_loading (ContentType.TRACK, track_id);

        CacheingState? cacheing_state = null;

        if (track_uri == null) {
            try {
                // Convert MusicQuality enum to is_hq boolean
                bool is_hq = root.settings.music_quality != MusicQuality.LQ;
                track_uri = yield root.yam_helper.get_download_uri (track_id, is_hq);
            } catch (Error e) {
                warning ("Failed to get download URI for track %s: %s", track_id, e.message);
                root.cachier.controller.stop_loading (ContentType.TRACK, track_id, null);
                return;
            }
        }

        if (track_uri != null && (root.settings.can_cache || !is_tmp)) {
            try {
                Bytes audio_bytes = yield root.yam_helper.load_track (track_uri);
                if (audio_bytes != null) {
                    yield root.cachier.storager.save_audio (audio_bytes, track_id, is_tmp);
                    if (is_tmp) {
                        cacheing_state = CacheingState.TEMP;
                    } else {
                        cacheing_state = CacheingState.PERM;
                    }
                }
            } catch (Error e) {
                warning ("Failed to load track from URI %s: %s", track_uri, e.message);
            }
        }

        root.cachier.controller.stop_loading (ContentType.TRACK, track_id, cacheing_state);
    }

    public async static string? get_track_uri (string track_id) {
        /**
            Выдает uri трека: локальный, если трек сохранен; интернет ссылку в ином случае.
            Если трек не был сохранен, то сохраняет его
         */

        debug ("[CACHIER] get_track_uri: Starting for track %s", track_id);
        string? track_uri = null;

        // Check if track is cached locally
        debug ("[CACHIER] get_track_uri: Checking cache for track %s", track_id);
        var audio_location = root.cachier.storager.audio_cache_location (track_id);
        if (audio_location.file != null) {
            var playback_path = yield root.cachier.storager.ensure_audio_playback_file (track_id);
            if (playback_path != null) {
                track_uri = File.new_for_path (playback_path).get_uri ();
                debug ("[CACHIER] get_track_uri: Using cached playback file for track %s: %s", track_id, track_uri);
                return track_uri;
            }

            debug ("[CACHIER] get_track_uri: Failed to prepare cached audio for %s, will refetch", track_id);
        }

        debug ("[CACHIER] get_track_uri: Track %s not cached, fetching from API", track_id);
        // Get download URI from API
        try {
            // Convert MusicQuality enum to is_hq boolean
            // LOSSLESS and NQ are high quality, LQ is low quality
            bool is_hq = root.settings.music_quality != MusicQuality.LQ;
            debug ("[CACHIER] get_track_uri: Calling get_download_uri for track %s (is_hq=%s)",
                   track_id, is_hq.to_string ());
            track_uri = yield root.yam_helper.get_download_uri (track_id, is_hq);
            debug ("[CACHIER] get_track_uri: get_download_uri returned: %s", track_uri ?? "(null)");
        } catch (Error e) {
            warning ("Failed to get download URI for track %s: %s", track_id, e.message);
            debug ("[CACHIER] get_track_uri: Error getting download URI: %s", e.message);
            return null;
        }

        if (track_uri != null) {
            // Start downloading in background for future use
            debug ("[CACHIER] get_track_uri: Starting background download for track %s", track_id);
            download_audio_async.begin (track_id, track_uri);
        }

        debug ("[CACHIER] get_track_uri: Returning URI: %s", track_uri ?? "(null)");
        return track_uri;
    }

    // Получение изображения ямобъекта, если есть, иначе получение из сети и сохранение
    public async static Bytes? get_image (YaMAPI.HasCover yam_object, int size) {
        /**
            Выдает объект Bytes с артом трека. Если изображение не найдено локально, загружает его.
            Если арт не был сохранен, то сохраняет его
         */

        Gee.ArrayList<string> cover_uris = yam_object.get_cover_items_by_size (size);
        if (cover_uris.size == 0) {
            return null;
        }

        // Try to load from cache first
        Bytes? image_bytes = null;
        string? cover_uri = null;
        
        foreach (var uri in cover_uris) {
            if (uri != null) {
                cover_uri = uri;
                var image_data = yield root.cachier.storager.load_image (uri);
                if (image_data != null) {
                    image_bytes = new Bytes.take (image_data);
                    break;
                }
            }
        }

        // If not in cache, load from network
        if (image_bytes == null && cover_uri != null) {
            try {
                // Ensure URI has https:// scheme
                string full_uri = cover_uri;
                if (!cover_uri.has_prefix ("http://") && !cover_uri.has_prefix ("https://")) {
                    full_uri = "https://" + cover_uri;
                }
                image_bytes = yield root.yam_helper.load_image_data (full_uri);
                if (image_bytes != null && root.settings.can_cache) {
                    uint8[] image_data = image_bytes.get_data ();
                    yield root.cachier.storager.save_image (image_data, cover_uri, true);
                }
            } catch (Error e) {
                warning ("Failed to load image from URI %s: %s", cover_uri, e.message);
            }
        }

        return image_bytes;
    }
}
