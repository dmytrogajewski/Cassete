/*
 * Copyright (C) 2025 Vladimir Romanov <rirusha@altlinux.org>
 * 
 * This program is free software: you can redistribute it and/or modify
 * it under the terms of the GNU General Public License as published by
 * the Free Software Foundation, either version 3 of the License, or
 * (at your option) any later version.
 * 
 * This program is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the
 * GNU General Public License for more details.
 * 
 * You should have received a copy of the GNU General Public License
 * along with this program. If not, see
 * <https://www.gnu.org/licenses/gpl-3.0-standalone.html>.
 * 
 * SPDX-License-Identifier: GPL-3.0-or-later
 */

[GtkTemplate (ui = "/space/rirusha/Cassette/ui/main-content.ui")]
public sealed class Cassette.MainContent : Adw.Bin {

    [GtkChild]
    unowned Adw.ViewStack view_stack;

    public Window? window { get; construct; }

    public PageRoot? main_page_root { get; private set; }

    public MainContent (Window? window = null) {
        Object (window: window);
    }

    construct {
        if (window != null) {
            initialize_navigation ();
        }
    }

    void initialize_navigation () {
        var main_view = new MainView ();
        main_page_root = new PageRoot (window, main_view);

        view_stack.add_named (main_page_root, "main");
        view_stack.visible_child_name = "main";
    }
}
