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

namespace Cassette {

    public class BeginDialog : Adw.Dialog {
        public BeginView begin_view { get; default = new BeginView (true); }

        construct {
            child = begin_view;

            presentation_mode = Adw.DialogPresentationMode.FLOATING;
            content_width = 600;
            content_height = 960;

        begin_view.online_complete.connect (on_online_complete);
        begin_view.local_choosed.connect (on_local_choosed);

        can_close = false;
        close_attempt.connect (on_close_attempt);
        }

        void on_online_complete () {
            var app = (Application?) GLib.Application.get_default ();
            if (app != null) {
                app.application_state = ApplicationState.ONLINE;
            }
            force_close ();
        }

        void on_local_choosed () {
            var app = (Application?) GLib.Application.get_default ();
            if (app != null) {
                app.application_state = ApplicationState.LOCAL;
            }
            force_close ();
        }

        void on_close_attempt () {
            var app = (Application?) GLib.Application.get_default ();
            app?.quit ();
        }
    }
}
