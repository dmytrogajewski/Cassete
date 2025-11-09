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

namespace Cassette {

    public class LoadingSpinner : Adw.Bin {
        public int size {
            get {
                return width_request;
            }
            set {
                width_request = value;
                height_request = value;
            }
        }

        private Gtk.Spinner spinner = new Gtk.Spinner ();

        public LoadingSpinner () {
            Object ();
        }

        construct {
            child = spinner;

            vexpand = true;
            hexpand = true;
            valign = Gtk.Align.CENTER;
            halign = Gtk.Align.CENTER;

            map.connect (on_map);
            unmap.connect (on_unmap);
        }

        void on_map () {
            spinner.start ();
        }

        void on_unmap () {
            spinner.stop ();
        }
    }
}
