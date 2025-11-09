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

public class Cassette.PrimaryMenuButton : CustomMenuButton {

    construct {
        primary = true;
        icon_name = "open-menu-symbolic";

        // Tooltip provides accessible name for screen readers
        real_button.tooltip_text = _("Primary menu");
    }

    protected override string get_title_label () {
        return _("Primary menu");
    }

    protected override MenuItem[] get_popover_menu_items () {
        MenuItem[] items = {
            { _("Log out"), "app.log-out", 0 },
            { _("Parse URL from clipboard"), "app.parse-url", 1 },
            { _("Preferences"), "win.preferences", 2 },
            { _("Keyboard Shortcuts"), "win.show-help-overlay", 2 },
            { _("About Cassette"), "win.about", 2 },
            { _("Show authentication"), "win.show-auth", 3 }
        };

        return items;
    }

    protected override MenuItem[] get_dialog_menu_items () {
        return get_popover_menu_items ();
    }
}
