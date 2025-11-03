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
    [GtkTemplate (ui = "/space/rirusha/Cassette/ui/cant-show-view.ui")]
    public class CantShowView : Adw.Bin {

        [GtkChild]
        unowned Adw.StatusPage status_page;

        public BaseView base_view { get; construct set; }
        public int code { get; construct; }

        public CantShowView (BaseView base_view, int code = 0) {
            Object (base_view: base_view, code: code);
        }

        construct {
            status_page.title = _("Error %d").printf (code);

            switch (code) {
                case 0:
                    status_page.title = _("Can't load page");
                    break;
                case 404:
                    status_page.description = _("Can't find desired content");
                    break;
                default:

            }
        }
    }
}

