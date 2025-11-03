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
using Gee;

namespace Cassette {
    [GtkTemplate (ui = "/space/rirusha/Cassette/ui/info-marks.ui")]
    public class InfoMarks : Adw.Bin {

        [GtkChild]
        unowned Gtk.Image track_replaced_mark;
        [GtkChild]
        unowned Gtk.Image exp_mark;
        [GtkChild]
        public unowned Gtk.Image child_mark;

        YaMAPI.Track? _replaced_by = null;
        public YaMAPI.Track? replaced_by {
            set {
                _replaced_by = value;

                if (value != null) {
                    track_replaced_mark.tooltip_text = _("Track was replaced. Original version: %s, %s").printf (
                        value.title_with_version, value.get_artists_names ()
                    );
                } else {
                    track_replaced_mark.tooltip_text = "";
                }

                check_replaced_mark_visible ();
            }
        }

        public bool is_exp {
            set {
                exp_mark.visible = value;
            }
        }

        public bool is_child {
            set {
                child_mark.visible = value;
            }
        }

        construct {
            Application.app_settings.changed.connect ((key) => {
                if (key == "show-replaced-mark") {
                    check_replaced_mark_visible ();
                }
            });
        }

        void check_replaced_mark_visible () {
            if (_replaced_by != null && Application.app_settings.get_boolean ("show-replaced-mark")) {
                track_replaced_mark.visible = true;
            } else {
                track_replaced_mark.visible = false;
            }
        }
    }
}

