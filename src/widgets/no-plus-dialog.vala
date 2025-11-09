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

[GtkTemplate (ui = "/space/rirusha/Cassette/ui/no-plus-dialog.ui")]
public class Cassette.NoPlusDialog : Adw.Dialog {

    public bool log_out_button_visible { get; set; }
}
