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

public abstract class Cassette.SidebarChildBin: Adw.Bin {

    public string child_id { get; set; }

    public string title { get; set; }

    public string subtitle { get; set; }

    construct {
        // Set accessible name based on title for screen readers
        update_accessible_name ();
        notify["title"].connect (update_accessible_name);
    }

    void update_accessible_name () {
        if (title != null && title.length > 0) {
            // Set accessible name using tooltip for screen readers
            tooltip_text = title;
        }
    }

    static construct {
        set_css_name ("sidebar-child-bin");
    }
}

