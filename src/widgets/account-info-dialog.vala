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
using Tape.YaMAPI;

namespace Cassette {
    [GtkTemplate (ui = "/space/rirusha/Cassette/ui/account-info-dialog.ui")]
    public class AccountInfoDialog : Adw.Dialog {
        [GtkChild]
        unowned Adw.Avatar avatar;
        [GtkChild]
        unowned Gtk.Label public_name_label;

        public YaMAPI.Account.About account_info { get; construct; }

        public AccountInfoDialog (YaMAPI.Account.About account_info) {
            Object (account_info: account_info);
        }

        construct {
            load_avatar.begin ();

            public_name_label.label = account_info.public_name;

            if (Config.IS_DEVEL) {
                add_css_class ("devel");
            }
        }

        async void load_avatar () {
            avatar.text = account_info.public_name;
            avatar.size = 200;
            // TODO: Uncomment when image API is available
            // var cachier = Application.tape_client.cachier;
            // var pixbuf = yield cachier.get_image (account_info, 200);
            // if (pixbuf != null) {
            //     avatar.custom_image = Gdk.Texture.for_pixbuf (pixbuf);
            // }
        }
    }
}

