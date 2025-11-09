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

            var image_bytes = yield Cachier.get_image (account_info, 200);
            if (image_bytes != null) {
                try {
                    var loader = new Gdk.PixbufLoader ();
                    loader.write_bytes (image_bytes);
                    loader.close ();
                    var pixbuf = loader.get_pixbuf ();
                    if (pixbuf != null) {
                        avatar.custom_image = Gdk.Texture.for_pixbuf (pixbuf);
                    }
                } catch (Error e) {
                    warning ("Failed to create pixbuf from avatar image: %s", e.message);
                }
            }
        }
    }
}
