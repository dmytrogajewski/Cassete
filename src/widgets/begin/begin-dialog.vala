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

            begin_view.online_complete.connect (force_close);
            begin_view.local_choosed.connect (force_close);

            can_close = false;
            close_attempt.connect (() => {
                var app = (Application?) GLib.Application.get_default ();
                app?.quit ();
            });
        }
    }
}

