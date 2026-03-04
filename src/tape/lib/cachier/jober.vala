/*
 * Copyright 2024 Vladimir Romanov
 * This program is free software: you can redistribute it and/or modify
 * it under the terms of the GNU General Public License as published by
 * the Free Software Foundation, version 3
 *
 * This program is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 * GNU General Public License for more details.
 *
 * You should have received a copy of the GNU General Public License
 * along with this program.  If not, see <http://www.gnu.org/licenses/>.
 *
 * SPDX-License-Identifier: GPL-3.0-only
 */

using Gee;

public class Tape.Jober : Object {

    public ArrayList<Job> job_list { get; default = new ArrayList<Job> (); }

    public signal void job_created (Job job);

    public signal void job_removed (Job job);

    /**
     * Находит job в списке job'ов. Если таковой нет, возвращает null
     */
    public Job ? find_job (YaMAPI.HasTracks yam_obj) {
        foreach (var job in job_list) {
            if (yam_obj.oid == job.yam_object.oid) {
                return job;
            }
        }

        return null;
    }

    public async void uncache_obj_async (YaMAPI.HasTracks yam_obj) {
        Job? job;

        job = find_job (yam_obj);

        if (job != null) {
            yield job.abort_with_wait ();
        }

        job = new Job (yam_obj);

        yield job.unsave_async ();
    }

    public async void uncache_obj_many_async (YaMAPI.HasTracks[] yam_objs) {
        foreach (var obj in yam_objs) {
            yield uncache_obj_async (obj);
        }
    }

    /**
     * Start new object cacheing.
     *
     * @param yam_obj   object to cache
     *
     * @return          `Job` object or `null` if object already
     *                  cacheing
     */
    public Job? start_cache_obj (YaMAPI.HasTracks yam_obj) {
        /**
            Начать сохранение объекта с треками
         */

        Job? job = null;

        job = find_job (yam_obj);

        if (job != null) {
            return null;
        }

        job = new Job (yam_obj);
        job_list.add (job);
        job_created (job);

        job.job_done.connect (() => {
            job_list.remove (job);
            job_removed (job);
        });

        job.save.begin ();

        return job;
    }

    public async void check_all_cache () {
        debug ("Started full saves check");

        var objs = yield root.cachier.storager.get_saved_objects ();

        foreach (var obj in objs) {
            YaMAPI.HasTracks new_obj = null;

            if (obj is YaMAPI.Playlist) {
                var pl_obj = (YaMAPI.Playlist) obj;

                try {
                    new_obj = yield root.yam_helper.get_playlist_info (pl_obj.playlist_uuid);
                } catch (ApiBase.BadStatusCodeError e) {
                } catch (Error e) {}
            } else {
                 if (obj is YaMAPI.Album) {
                     var alb_obj = (YaMAPI.Album) obj;
                     try {
                         new_obj = (YaMAPI.HasTracks?) yield root.yam_helper.get_album_info (alb_obj.id);
                     } catch (ApiBase.BadStatusCodeError e) {
                     } catch (Error e) {}
                 }
            }

            if (new_obj != null) {
                start_cache_obj (new_obj);
            }
        }
    }

    public async void uncache_all () {
        var objs = yield root.cachier.storager.get_saved_objects ();

        yield uncache_obj_many_async (objs);
    }
}
