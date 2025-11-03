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

[GtkTemplate (ui = "/space/rirusha/Cassette/ui/cache-indicator.ui")]
public class Cassette.CacheIndicator : Adw.Bin {
        [GtkChild]
        unowned Gtk.Popover jobs_popover;
        [GtkChild]
        unowned Gtk.Box jobs_box;
        [GtkChild]
        unowned Gtk.Revealer indicator_revealer;
        [GtkChild]
        unowned Gtk.DrawingArea jobs_icon;

        public CacheIndicator () {
            Object ();
        }

        construct {
            jobs_popover.notify["visible"].connect (() => {
                while (jobs_box.get_last_child () != null) {
                    jobs_box.remove (jobs_box.get_last_child ());
                }

                if (jobs_popover.visible) {
                    fill_box ();
                }
            });

            indicator_revealer.notify["reveal-child"].connect (() => {
                if (indicator_revealer.reveal_child) {
                    indicator_revealer.visible = true;
                }
            });

            indicator_revealer.notify["child-revealed"].connect (() => {
                if (!indicator_revealer.child_revealed) {
                    indicator_revealer.visible = false;
                }
            });

            jobs_icon.set_draw_func (update_jobs_icon);

            // Note: Cachier job system is not fully implemented in libtape yet
            // The Jober class exists with job_created/job_removed signals, but it's commented out in Cachier
            // When libtape's cachier.jober is uncommented and active, wire like this:
            // var cachier = Application.tape_client.cachier;
            // var jober = cachier.jober;
            //
            // jober.job_created.connect ((job) => {
            //     job.track_saving_ended.connect (jobs_icon.queue_draw);
            //     indicator_revealer.reveal_child = true;
            // });
            //
            // jober.job_removed.connect ((job) => {
            //     jobs_icon.queue_draw ();
            //     update_indicator_visibility ();
            // });
        }

        //
        // void update_indicator_visibility () {
        //     // Note: Jober.job_list will be available when cachier.jober is uncommented
        //     // When available, check like this:
        //     // var cachier = Application.tape_client.cachier;
        //     // var jober = cachier.jober;
        //     // if (jober.job_list.size == 0) {
        //     //     indicator_revealer.reveal_child = false;
        //     // }
        // }

        void fill_box () {
            //
            // foreach (var job in cachier.job_list) {
            //     jobs_box.append (new JobInfoBadge (job));
            // }
        }

        // Took from https://gitlab.gnome.org/GNOME/nautilus/-/blob/main/src/nautilus-progress-indicator.c
        void update_jobs_icon (Gtk.DrawingArea drawing_area, Cairo.Context cairo, int width, int height) {
            int elapsed_progress = 0;
            int total_progress = 0;

            double ratio;

            var foreground = drawing_area.get_color ();
            var background = foreground;
            background.alpha *= 0.3f;

            //
            // foreach (var job in cachier.job_list) {
            //     elapsed_progress += job.saved_tracks_count;
            //     total_progress += job.total_tracks_count;
            // }

            if (total_progress > 0) {
                ratio = double.max (0.01, (double) elapsed_progress / (double) total_progress);
            } else {
                ratio = 1;
            }

            width = drawing_area.get_width ();
            double dwidth = (double) width;

            height = drawing_area.get_height ();
            double dheight = (double) height;

            cairo.set_source_rgba (background.red, background.green, background.blue, background.alpha);

            cairo.arc (
                dwidth / 2.0,
                dheight / 2.0,
                double.min (dwidth, dheight) / 2.0,
                0,
                2 * Math.PI
            );
            cairo.fill ();

            cairo.move_to (
                dwidth / 2.0,
                dheight / 2.0
            );

            cairo.set_source_rgba (foreground.red, foreground.green, foreground.blue, foreground.alpha);

            cairo.arc (
                dwidth / 2.0,
                dheight / 2.0,
                double.min (dwidth, dheight) / 2.0,
                -Math.PI_2,
                ratio * 2 * Math.PI - Math.PI_2
            );
            cairo.fill ();
        }
    }

