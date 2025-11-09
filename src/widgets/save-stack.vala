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

[GtkTemplate (ui = "/space/rirusha/Cassette/ui/save-stack.ui")]
public class Cassette.SaveStack : Adw.Bin, Initable {

    [GtkChild]
    unowned Gtk.Stack save_stack;
    [GtkChild]
    unowned Gtk.Spinner save_spin;
    [GtkChild]
    unowned Gtk.Image temp_mark_image;
    [GtkChild]
    unowned Gtk.Image perm_mark_image;

    public bool show_anyway { get; set; default = false; }

    protected string content_id { get; set; }
    public Tape.ContentType content_type { get; construct; }

    public bool hide_when_none { get; construct; default = false; }

    ulong? con_id = null;

    public SaveStack () {
        Object ();
    }

    string get_content_name () {
        switch (content_type) {
            case Tape.ContentType.ALBUM:
                return _("Album");
            case Tape.ContentType.IMAGE:
                return _("Image");
            case Tape.ContentType.PLAYLIST:
                return _("Playlist");
            case Tape.ContentType.TRACK:
                return _("Track");
            default:
                assert_not_reached ();
        }
    }

    construct {
        // Tooltip provides accessible name for screen readers
        tooltip_text = _("Save status");

        Application.app_settings.changed.connect (on_app_settings_changed);

        save_spin.tooltip_text = _("%s saving…").printf (get_content_name ());
        temp_mark_image.tooltip_text = _("%s cached").printf (get_content_name ());
        perm_mark_image.tooltip_text = _("%s saved").printf (get_content_name ());

        if (hide_when_none) {
            visible = false;
            save_stack.notify.connect (on_save_stack_notify);
        }
    }

    void on_app_settings_changed (string key) {
        if (content_id == null) {
            return;
        }

        if (key == "show-save-stack" || key == "show-temp-save-mark") {
            cache_state_changed (
                Application.tape_client.cachier.controller.get_content_cache_state (
                    content_type, content_id));
        }
    }

    void on_save_stack_notify (ParamSpec pspec) {
        if (pspec.name == "visible-child-name") {
            visible = save_stack.visible_child_name != "none";
        }
    }

    public void clear () {
        cache_state_changed (Tape.CacheingState.NONE);
    }

    public void init_content (string content_id) {
        // Disconnect previous handler if any
        if (con_id != null) {
            Application.tape_client.cachier.controller.content_cache_state_changed.disconnect (
                on_content_cache_state_changed);
            con_id = null;
        }

        this.content_id = content_id;

        con_id = Application.tape_client.cachier.controller.content_cache_state_changed.connect (
            on_content_cache_state_changed);

        cache_state_changed (
            Application.tape_client.cachier.controller.get_content_cache_state (
                content_type, content_id));
    }

    void on_content_cache_state_changed (Tape.ContentType content_type, string content_id, Tape.CacheingState state) {
        if (this.content_id == content_id && this.content_type == content_type) {
            cache_state_changed (state);
        }
    }

    void cache_state_changed (Tape.CacheingState state) {
        if (!Application.app_settings.get_boolean ("show-save-stack")) {
            state = Tape.CacheingState.NONE;
        }

        switch (state) {
            case Tape.CacheingState.NONE:
                save_stack.visible_child_name = "none";
                save_spin.stop ();
                break;
            case Tape.CacheingState.LOADING:
                save_stack.visible_child_name = "loading";
                save_spin.start ();
                break;
            case Tape.CacheingState.TEMP:
                if (Application.app_settings.get_boolean ("show-temp-save-mark") || show_anyway) {
                    save_stack.visible_child_name = "temp";
                } else {
                    save_stack.visible_child_name = "none";
                }
                save_spin.stop ();
                break;
            case Tape.CacheingState.PERM:
                save_stack.visible_child_name = "perm";
                save_spin.stop ();
                break;
        }
    }

    protected override void dispose () {
        if (con_id != null) {
            Application.tape_client.cachier.controller.content_cache_state_changed.disconnect (
                on_content_cache_state_changed);
            con_id = null;
        }
        base.dispose ();
    }
}
