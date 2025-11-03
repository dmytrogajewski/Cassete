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

namespace Cassette {
    public abstract class CachiableView : HasTracksView {

        internal struct ContentInfo {
            public string content_name;
        }

        public Gtk.Stack download_stack { get; set; }
        Gtk.Overlay overlay { get; default = new Gtk.Overlay (); }
        public Gtk.ProgressBar saving_progress_bar { get; default = new Gtk.ProgressBar (); }

        public new Gtk.Widget child {
            get {
                return overlay.child;
            }
            set {
                overlay.child = value;
            }
        }

        bool yell_status = true;

        construct {
            base.child = overlay;

            saving_progress_bar.add_css_class ("osd");
            saving_progress_bar.visible = false;

            saving_progress_bar.valign = Gtk.Align.START;
            saving_progress_bar.vexpand = false;

            overlay.add_overlay (saving_progress_bar);
        }

        public async override void first_show () {
            download_stack.sensitive = false;
            bool cache_success = yield try_load_from_cache ();
            int soup_code = yield try_load_from_web ();
            if (!cache_success) {
                if (soup_code != -1) {
                    if (root_view != null) {
                        root_view.show_error (this, soup_code);
                    }
                } else {
                    check_cache ();
                }
            } else {
                if (soup_code == -1) {
                    check_cache ();
                }
            }
        }

        public async override void refresh () {
            int soup_code = yield try_load_from_web ();
            if (soup_code != -1) {
                bool cache_success = yield try_load_from_cache ();
                if (!cache_success) {
                    if (root_view != null) {
                        root_view.show_error (this, soup_code);
                    }
                    return;
                }
            } else {
                check_cache ();
            }
        }

        ContentInfo get_content_info (HasTracks obj_info) {
            string content_name = "";

            if (obj_info is YaMAPI.Playlist) {
                content_name = _("Playlist");

            } else if (obj_info is YaMAPI.Album) {
                content_name = _("Album");

            } else {
                assert_not_reached ();
            }

            return {content_name};
        }

        protected void start_saving (bool yell_status) {
            // TODO: Implement when cachier job API is available
            // download_stack.visible_child_name = "abort";
            // this.yell_status = yell_status;

            // var cachier = Application.tape_client.cachier;
            // job = cachier.start_cache (object_info);

            // if (yell_status) {
            //     var content_info = get_content_info (object_info);
            //     var app = (Application?) GLib.Application.get_default ();
            //     var window = app?.active_window as Window;
            //     window?.show_message (_("%s saving has started").printf (
            //         content_info.content_name
            //     ));
            // }
        }

        protected virtual void check_cache () {
            // TODO: Implement when cachier job API is available
            // download_stack.sensitive = true;

            // var cachier = Application.tape_client.cachier;
            // if (job == null) {
            //     job = cachier.find_job (object_info.oid);

            //     if (job == null) {
            //         var storager = Application.tape_client.cachier.storager;
            //         var location = storager.object_cache_location (object_info.get_type (), object_info.oid);
            //         if (!location.is_tmp) {
            //             start_saving (false);
            //         }
            //     }
            // }
        }

        public virtual void abort_saving () {
            // TODO: Implement when cachier job API is available
            // if (job != null) {
            //     job.abort ();
            // }
        }

        public virtual void uncache_playlist (bool yell_status) {
            download_stack.sensitive = false;
            this.yell_status = yell_status;

            // TODO: Implement when uncache API is available
            // var cachier = Application.tape_client.cachier;
            // cachier.uncache.begin (object_info, () => {
            //     download_stack.visible_child_name = "save";
            //     download_stack.sensitive = true;

            //     if (yell_status) {
            //         var content_info = get_content_info (object_info);
            //         var app = (Application?) GLib.Application.get_default ();
            //         var window = app?.active_window as Window;
            //         window?.show_message (_("%s '%s' was moved from data to cache").printf (
            //             content_info.content_name,
            //             content_info.content_title
            //         ));
            //     }
            // });

            if (yell_status) {
                var content_info = get_content_info (object_info);
                var app = (Application?) GLib.Application.get_default ();
                var window = app?.active_window as Window;
                window?.show_message (_("%s removing has started. Please do not close the app").printf (
                    content_info.content_name
                ));
            }
        }
    }
}

