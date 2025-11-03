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

using Tape.YaMAPI;

[GtkTemplate (ui = "/space/rirusha/Cassette/ui/wave-settings.ui")]
public sealed class Cassette.WaveSettings: SidebarChildBin {

    [GtkChild]
    unowned LoadableWidget loadable_widget;
    [GtkChild]
    unowned Gtk.FlowBox by_activity_box;
    [GtkChild]
    unowned Gtk.FlowBox by_diversity_box;
    [GtkChild]
    unowned Gtk.FlowBox by_mood_energy_box;
    [GtkChild]
    unowned Gtk.FlowBox by_language_box;

    Rotor.Settings? wave_settings;

    construct {
        child_id = "null:wave";
        title = _("Wave settings");

        fetch_wave_settings.begin ();
    }

    async void fetch_wave_settings () {
        // TODO: Uncomment when API method is available in libtape
        // var yam_helper = Application.tape_client.yam_helper;
        // TODO: Uncomment when API method is available in libtape
        // try {
        //     wave_settings = yield yam_helper.get_wave_settings ();
        //
        //     if (wave_settings != null) {
        //         loadable_widget.show_result ();
        //         set_values ();
        //     } else {
        //         loadable_widget.show_error ();
        //     }
        // } catch (Error e) {
        //     debug ("Failed to load wave settings: %s", e.message);
        //     loadable_widget.show_error ();
        // }
        loadable_widget.show_error ();
    }

    void set_values () {
        if (wave_settings == null) {
            return;
        }

        NarrowToggleButton? button_for_group = null;

        foreach (var item in wave_settings.blocks[0].items) {
            var narrow_button = new NarrowToggleButton () {
                label = item.name,
                icon_name = item.icon.get_internal_icon_name (item.id.normal),
            };

            if (button_for_group == null) {
                button_for_group = narrow_button;
            } else {
                narrow_button.group = button_for_group;
            }

            by_activity_box.append (narrow_button);
        }

        button_for_group = null;

        foreach (var item in wave_settings.setting_restrictions.diversity.possible_values) {
            if (item.value != "default") {
                var narrow_button = new NarrowToggleButton () {
                    label = item.name,
                };

                if (button_for_group == null) {
                    button_for_group = narrow_button;
                } else {
                    narrow_button.group = button_for_group;
                }

                by_diversity_box.append (narrow_button);
            }
        }

        button_for_group = null;

        foreach (var item in wave_settings.setting_restrictions.mood_energy.possible_values) {
            if (item.value != "all") {
                var narrow_button = new NarrowToggleButton () {
                    label = item.name,
                };

                if (button_for_group == null) {
                    button_for_group = narrow_button;
                } else {
                    narrow_button.group = button_for_group;
                }

                by_mood_energy_box.append (narrow_button);
            }
        }

        button_for_group = null;

        foreach (var item in wave_settings.setting_restrictions.language.possible_values) {
            if (item.value != "any") {
                var narrow_button = new NarrowToggleButton () {
                    label = item.name,
                };

                if (button_for_group == null) {
                    button_for_group = narrow_button;
                } else {
                    narrow_button.group = button_for_group;
                }

                by_language_box.append (narrow_button);
            }
        }
    }
}

