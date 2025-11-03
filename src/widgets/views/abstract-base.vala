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
    public abstract class BaseView : Adw.Bin {

        public virtual bool can_refresh { get; default = false; }

        public signal void show_ready ();

        public async abstract int try_load_from_web ();

        public async abstract bool try_load_from_cache ();

        public PageRoot? root_view { get; set; }

        public async virtual void first_show () {
            bool cache_is_success = yield try_load_from_cache ();
            int soup_code = yield try_load_from_web ();
            if (!cache_is_success) {
                if (soup_code != -1) {
                    if (root_view != null) {
                        root_view.show_error (this, soup_code);
                    }
                }
            }
        }

        public async virtual void refresh () {
            int soup_code = yield try_load_from_web ();
            if (soup_code != -1) {
                bool cache_is_success = yield try_load_from_cache ();
                if (!cache_is_success) {
                    if (root_view != null) {
                        root_view.show_error (this, soup_code);
                    }
                }
            }
        }
    }
}

