/*
 * Copyright (C) 2024 Vladimir Romanov
 * SPDX-License-Identifier: GPL-3.0-or-later
 */

using Tape;

namespace Cassette {
    public class JobInfoBadge : Gtk.Box {
        Job job;
        Gtk.Label title_label;
        Gtk.Label status_label;
        Gtk.ProgressBar progress_bar;
        Gtk.Button cancel_button;

        public JobInfoBadge (Job job) {
            Object (orientation: Gtk.Orientation.VERTICAL, spacing: 6);
            this.job = job;

            var header_box = new Gtk.Box (Gtk.Orientation.HORIZONTAL, 6);
            append (header_box);

            title_label = new Gtk.Label (job.object_title);
            title_label.halign = Gtk.Align.START;
            title_label.hexpand = true;
            title_label.ellipsize = Pango.EllipsizeMode.END;
            title_label.add_css_class ("heading");
            header_box.append (title_label);

            cancel_button = new Gtk.Button.from_icon_name ("process-stop-symbolic");
            cancel_button.add_css_class ("flat");
            cancel_button.clicked.connect (() => {
                 job.abort ();
            });
            header_box.append (cancel_button);

            progress_bar = new Gtk.ProgressBar ();
            append (progress_bar);
            
            status_label = new Gtk.Label ("");
            status_label.halign = Gtk.Align.START;
            status_label.add_css_class ("caption");
            append (status_label);

            update_progress (job.saved_tracks_count, job.total_tracks_count);

            job.track_saving_ended.connect ((saved, total, current) => {
                update_progress (saved, total);
            });
        }

        void update_progress (int saved, int total) {
            if (total > 0) {
                progress_bar.fraction = (double) saved / (double) total;
                status_label.label = _("%d of %d").printf(saved, total);
            } else {
                progress_bar.fraction = 0;
                status_label.label = _("Waiting...");
            }
        }
    }
}

