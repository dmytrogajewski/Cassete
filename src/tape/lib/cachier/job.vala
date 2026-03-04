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


namespace Tape {

public enum JobDoneStatus {
    SUCCESS,
    ABORTED,
    FAILED
}

// Класс представляющий объект для кэширования объекта ямы и его составных частей по интерфейсам
public class Job : Object {

    public YaMAPI.HasTracks yam_object { get; construct; }

    public string object_id { get; construct; }
    public ContentType object_type { get; construct; }
    public string object_title { get; construct; }

    int _now_saving_tracks_count = 0;
    public int now_saving_tracks_count {
        get {
            return _now_saving_tracks_count;
        }
        private set {
            _now_saving_tracks_count = value;

            if (cancellable.is_cancelled () && value == 0) {
                unsave_async.begin (() => {
                        Idle.add (() => {
                            job_done (JobDoneStatus.ABORTED);
                            return Source.REMOVE;
                        }, Priority.HIGH_IDLE);
                    });
            }
        }
    }

    public signal void track_saving_started (
        int saved_tracks_count,
        int total_tracks_count,
        int now_saving_tracks_count
    );

    public signal void track_saving_ended (
        int saved_tracks_count,
        int total_tracks_count,
        int now_saving_tracks_count
    );

    JobDoneStatus? done_status = null;

    public int saved_tracks_count { get; private set; default = 0; }
    public int total_tracks_count { get; private set; default = 1; }

    // Для отмены изменяется переменная should_stop, чтобы объект успел докэшировать то, что он кэширует
    Cancellable cancellable = new Cancellable ();

    public bool is_cancelled {
        get {
            return cancellable.is_cancelled ();
        }
    }

    public signal void cancelled ();

    /**
     * В случае завершения кэширования поднимает сигнал со статусом окончания:
     * завершено с ошибкой, успешно или отменено
     */
    public signal void job_done (JobDoneStatus status);

    // Сделано значимое действие. Например, не проверка, сохранен ли трек, а его загрузка.
    public signal void action_done ();

    public Job (YaMAPI.HasTracks yam_object) {
        Object (yam_object : yam_object);
    }

    construct {
        object_id = yam_object.oid;

        if (yam_object is YaMAPI.Playlist) {
            object_type = ContentType.PLAYLIST;
            object_title = ((YaMAPI.Playlist) yam_object).title;

        } else if (yam_object is YaMAPI.Album) {
            object_type = ContentType.ALBUM;
            object_title = ((YaMAPI.Album) yam_object).title;

        } else {
            assert_not_reached ();
        }

        cancellable.cancelled.connect (() => {
            cancelled ();
        });

        job_done.connect ((status) => {
                done_status = status;
                root.cachier.controller.stop_loading (object_type, object_id, null);

                switch (status) {
                        case JobDoneStatus.SUCCESS:
                            debug ("Job %s.%s was finished with success".printf (
                                object_type.to_string (),
                                yam_object.oid
                            ));
                            break;

                        case JobDoneStatus.ABORTED:
                            debug ("Job %s.%s was aborted".printf (
                                object_type.to_string (),
                                yam_object.oid
                            ));
                            break;

                        case JobDoneStatus.FAILED:
                            debug ("Job %s.%s was failed".printf (
                                object_type.to_string (),
                                yam_object.oid
                            ));
                            break;
                }
            });

        debug ("Job %s.%s was created".printf (object_type.to_string (), yam_object.oid));
    }

    public void abort () {
        cancellable.cancel ();
    }

    public async void abort_with_wait () {
        job_done.connect (() => {
            Idle.add (abort_with_wait.callback);
        });

        abort ();

        yield;
    }

    public async void save () {
        root.cachier.controller.start_loading (object_type, object_id);

        var storager = root.cachier.storager;

        var need_cache_track_ids = new Gee.ArrayList<string> ();
        var need_uncache_tracks = new Gee.ArrayList<YaMAPI.Track> ();

        var track_list = yam_object.get_filtered_track_list (true, true);

        debug ("Job %s.%s was started".printf (
            object_type.to_string (),
            yam_object.oid
        ));

        foreach (var track_info in track_list) {
            need_cache_track_ids.add (track_info.id);
        }

        var obj_location = storager.object_cache_location (yam_object.get_type (), object_id);
        if (obj_location.is_tmp == false) {
            var cachied_obj_wt = (YaMAPI.HasTracks) yield storager.load_object (yam_object.get_type (), object_id);

            if (cachied_obj_wt != null) {
                var cachied_obj_track_list = cachied_obj_wt.get_filtered_track_list (true, true);

                foreach (var track_info in cachied_obj_track_list) {
                    if (!(track_info.id in need_cache_track_ids)) {
                        need_uncache_tracks.add (track_info);
                    }
                }
            }

        } else {
            if (obj_location.file != null) {
                yield Storager.remove_file (obj_location.file);
            }
        }

        yield root.cachier.storager.save_object (yam_object, false);

        debug ("Job %s.%s, object saved".printf (
            object_type.to_string (),
            yam_object.oid
        ));

        // Удаление из кэшей треков, которые были удалены из объекта вне текущего клиента
        foreach (var track_info in need_uncache_tracks) {
            root.cachier.storager.db.remove_content_ref (track_info.id, object_id);
            if (root.cachier.storager.db.get_content_ref_count (track_info.id) == 0) {
                yield storager.move_loc_to_temp (storager.audio_cache_location (track_info.id));
            }

            var cover_items = track_info.get_cover_items_by_size (CoverSize.SMALL);

            if (cover_items.size != 0) {
                string image_uri = cover_items[0];
                storager.db.remove_content_ref (image_uri, object_id);
                if (storager.db.get_content_ref_count (image_uri) == 0) {
                    yield storager.move_loc_to_temp (storager.image_cache_location (image_uri));
                }

                debug ("Job %s.%s, track %s in db was fixed".printf (
                    object_type.to_string (),
                    yam_object.oid,
                    @"$(track_info.id) ($(track_info.title))"
                ));
            }
        }

        var has_cover_yam_obj = yam_object as YaMAPI.HasCover;
        if (has_cover_yam_obj != null) {
            foreach (var cover_uri in has_cover_yam_obj.get_cover_items_by_size (CoverSize.BIG)) {
                var image_location = storager.image_cache_location (cover_uri);
                if (image_location.file != null) {
                    yield storager.move_loc_to_perm (image_location);

                } else {
                    Bytes? bytes = null;
                    try {
                         // Ensure URI scheme
                        string full_uri = cover_uri;
                        if (!cover_uri.has_prefix ("http")) full_uri = "https://" + cover_uri;

                        bytes = yield root.yam_helper.load_image_data (full_uri);
                    } catch (Error e) {
                        warning ("Failed to load cover: %s", e.message);
                    }

                    if (bytes != null) {
                        yield storager.save_image (bytes.get_data (), cover_uri, false);
                    } else {
                        Idle.add (() => {
                            job_done (JobDoneStatus.FAILED);
                            return Source.REMOVE;
                        }, Priority.HIGH_IDLE);

                        // Abort further processing if cover failed? 
                        // Legacy code returned here.
                        return;
                    }
                }

                storager.db.set_content_ref (cover_uri, object_id);
            }

            debug ("Job %s.%s, cover of object saved".printf (
                                object_type.to_string (),
                                yam_object.oid
                                ));
        }

        total_tracks_count = track_list.size;
        if (total_tracks_count == 0) {
            Idle.add (() => {
                    job_done (JobDoneStatus.SUCCESS);
                    return Source.REMOVE;
                });
        } else {
            int concurrency_limit = 3;
            int active_tasks = 0;
            foreach (var track_info in track_list) {
                if (cancellable.is_cancelled()) break;
                
                active_tasks++;
                save_track_async.begin (track_info, (obj, res) => {
                    save_track_async.end (res);
                    active_tasks--;
                    save.callback ();
                });

                if (active_tasks >= concurrency_limit) {
                    yield;
                }
            }
            
            while (active_tasks > 0) {
                yield;
            }
        }
    }

    public async void unsave_async () {
        debug ("Job %s.%s, uncache object started".printf (
                          object_type.to_string (),
                          yam_object.oid
                          ));

        string object_id = yam_object.oid;
        var storager = root.cachier.storager;

        var has_cover_yam_obj = yam_object as YaMAPI.HasCover;
        if (has_cover_yam_obj != null) {
            foreach (var cover_uri in has_cover_yam_obj.get_cover_items_by_size (CoverSize.BIG)) {
                storager.db.remove_content_ref (cover_uri, object_id);

                if (storager.db.get_content_ref_count (cover_uri) == 0) {
                    var image_location = storager.image_cache_location (cover_uri);
                    yield storager.move_loc_to_temp (image_location);
                }
            }
        }

        var object_location = storager.object_cache_location (yam_object.get_type (), yam_object.oid);
        yield storager.move_loc_to_temp (object_location);

        if (root.settings.can_cache) {
            root.cachier.controller.change_state (object_type, object_id, CacheingState.TEMP);
        } else {
            root.cachier.controller.change_state (object_type, object_id, CacheingState.NONE);
        }

        var track_list = yam_object.get_filtered_track_list (true, true);

        foreach (var track_info in track_list) {
            var cover_items = track_info.get_cover_items_by_size (CoverSize.SMALL);

            if (cover_items.size != 0) {
                string image_cover_uri = cover_items[0];
                storager.db.remove_content_ref (image_cover_uri, track_info.id);
                if (storager.db.get_content_ref_count (image_cover_uri) == 0) {
                    var image_location = storager.image_cache_location (image_cover_uri);
                    yield storager.move_loc_to_temp (image_location);
                }
            }

            storager.db.remove_content_ref (track_info.id, object_id);
            if (storager.db.get_content_ref_count (track_info.id) == 0) {
                var track_location = storager.audio_cache_location (track_info.id);
                yield storager.move_loc_to_temp (track_location);

                if (track_location.file != null && root.settings.can_cache) {
                    root.cachier.controller.change_state (ContentType.TRACK, track_info.id, CacheingState.TEMP);
                } else {
                    root.cachier.controller.change_state (ContentType.TRACK, track_info.id, CacheingState.NONE);
                }
            }

            Idle.add (unsave_async.callback);
            yield;
        }

        debug ("Job %s.%s, uncache object finished".printf (
                          object_type.to_string (),
                          yam_object.oid
                          ));
    }


    string sanitize_filename (string name) {
        return name.replace ("/", "_").replace ("\0", "");
    }

    async void save_track_async (YaMAPI.Track track_info) {
        debug ("Job %s.%s, saving track %s was started".printf (
                          object_type.to_string (),
                          yam_object.oid,
                          @"$(track_info.id) ($(track_info.title))"
                          ));

        lock (now_saving_tracks_count) {
            now_saving_tracks_count++;
            Idle.add_once (() => {
                track_saving_started (saved_tracks_count, total_tracks_count, now_saving_tracks_count);
            });
        }

        debug ("Job %s.%s, audio of track %s was started".printf (
                          object_type.to_string (),
                          yam_object.oid,
                          @"$(track_info.id) ($(track_info.title))"
                          ));

        Idle.add (() => {
            root.cachier.controller.start_loading (ContentType.TRACK, track_info.id);
            return Source.REMOVE;
        }, Priority.HIGH_IDLE);

        var storager = root.cachier.storager;
        var track_location = storager.audio_cache_location (track_info.id);

        string filename = sanitize_filename ("%s - %s.mp3".printf (
            track_info.get_artists_names (),
            track_info.title
        ));

        if (track_location.file != null) {
            if (track_location.is_tmp == true) {
                yield storager.move_audio_to_perm (track_info.id, filename);

                Idle.add_once (() => {
                    action_done ();
                });
            }
        } else {
            string? track_uri = null;
            try {
                bool is_hq = true;
                if (root.settings.music_quality == MusicQuality.LQ) {
                    is_hq = false;
                }
                track_uri = yield root.yam_helper.get_download_uri (track_info.id, is_hq);
            } catch (Error e) {
                warning ("Failed to get download uri: %s", e.message);
            }

            if (track_uri != null) {
                Bytes? audio_bytes = null;
                try {
                    audio_bytes = yield root.yam_helper.load_track (track_uri);
                } catch (Error e) {
                    warning ("Failed to load track: %s", e.message);
                }

                if (audio_bytes != null) {
                    storager.db.set_filename (track_info.id, filename);
                    yield storager.save_audio (audio_bytes, track_info.id, false);

                    Idle.add_once (() => {
                        action_done ();
                    });
                } else {
                    cancellable.cancel ();
                    Idle.add (() => {
                        job_done (JobDoneStatus.FAILED);
                        return Source.REMOVE;
                    }, Priority.HIGH_IDLE);

                    lock (now_saving_tracks_count) {
                        now_saving_tracks_count--;
                    }
                    return;
                }
            } else {
                cancellable.cancel ();
                Idle.add (() => {
                    job_done (JobDoneStatus.FAILED);
                    return Source.REMOVE;
                }, Priority.HIGH_IDLE);

                lock (now_saving_tracks_count) {
                    now_saving_tracks_count--;
                }
                return;
            }
        }

        storager.db.set_content_ref (track_info.id, object_id);

        debug ("Job %s.%s, audio of track %s was saved".printf (
                          object_type.to_string (),
                          yam_object.oid,
                          @"$(track_info.id) ($(track_info.title))"
                          ));

        debug ("Job %s.%s, cover of track %s was started".printf (
                          object_type.to_string (),
                          yam_object.oid,
                          @"$(track_info.id) ($(track_info.title))"
                          ));

        var cover_items = track_info.get_cover_items_by_size (CoverSize.SMALL);

        if (cover_items.size != 0) {
            string image_cover_uri = cover_items[0];
            var image_location = storager.image_cache_location (image_cover_uri);
            
            if (image_location.file != null) {
                if (image_location.is_tmp == true) {
                    yield storager.move_loc_to_perm (image_location);

                    Idle.add_once (() => {
                        action_done ();
                    });
                }
            } else {
                Bytes? pixbuf_bytes = null;
                try {
                    string full_uri = image_cover_uri;
                    if (!image_cover_uri.has_prefix ("http")) full_uri = "https://" + image_cover_uri;
                    pixbuf_bytes = yield root.yam_helper.load_image_data (full_uri);
                } catch (Error e) {
                    warning ("Failed to load cover: %s", e.message);
                }

                if (pixbuf_bytes != null) {
                    yield storager.save_image (pixbuf_bytes.get_data (), image_cover_uri, false);

                    Idle.add_once (() => {
                        action_done ();
                    });
                } else {
                    cancellable.cancel ();
                    Idle.add (() => {
                        job_done (JobDoneStatus.FAILED);
                        return Source.REMOVE;
                    }, Priority.HIGH_IDLE);

                    lock (now_saving_tracks_count) {
                        now_saving_tracks_count--;
                    }
                    return;
                }
            }

            storager.db.set_content_ref (image_cover_uri, track_info.id);

            debug ("Job %s.%s, cover of track %s was saved".printf (
                              object_type.to_string (),
                              yam_object.oid,
                              @"$(track_info.id) ($(track_info.title))"
                              ));
        }

        Idle.add (() => {
            root.cachier.controller.stop_loading (ContentType.TRACK, track_info.id, CacheingState.PERM);

            debug ("Job %s.%s, saving track %s was finished".printf (
                              object_type.to_string (),
                              yam_object.oid,
                              @"$(track_info.id) ($(track_info.title))"
                              ));

            return Source.REMOVE;
        }, Priority.HIGH_IDLE);

        lock (now_saving_tracks_count) {
            now_saving_tracks_count--;
        }

        lock (saved_tracks_count) {
            saved_tracks_count++;
        }

        Idle.add_once (() => {
                track_saving_ended (saved_tracks_count, total_tracks_count, now_saving_tracks_count);
            });

        if (!cancellable.is_cancelled ()) {
            lock (saved_tracks_count) {
                Idle.add_once (() => {
                        if (saved_tracks_count == total_tracks_count && done_status == null) {
                            job_done (JobDoneStatus.SUCCESS);
                        }
                    });
            }
        }
    }
}
}
