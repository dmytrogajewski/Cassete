/*
 * Copyright (C) 2024 Vladimir Romanov
 *
 * This program is free software: you can redistribute it and/or modify
 * it under the terms of the GNU General Public License as published by
 * the Free Software Foundation, either version 3 of the License, or
 * (at your option) any later version.
 *
 * SPDX-License-Identifier: GPL-3.0-or-later
 */

namespace Cassette {

    /**
     * Animated wave canvas widget for main page background
     */
    public class WaveCanvas : Gtk.DrawingArea {
        private uint animation_timeout = 0;
        private double animation_time = 0.0;
        private const int WAVE_COUNT = 3;
        private const double WAVE_SPEED = 0.02;
        private const double WAVE_AMPLITUDE = 20.0;

        public WaveCanvas () {
            Object ();
        }

        construct {
            set_draw_func (draw_waves);

            // Start animation when mapped
            map.connect (on_map);

            // Stop animation when unmapped
            unmap.connect (on_unmap);
        }

        void on_map () {
            start_animation ();
        }

        void on_unmap () {
            stop_animation ();
        }

        void start_animation () {
            if (animation_timeout != 0) {
                return;
            }

            animation_timeout = Timeout.add (16, on_animation_tick); // ~60 FPS
        }

        bool on_animation_tick () {
            animation_time += WAVE_SPEED;
            queue_draw ();
            return true;
        }

        void stop_animation () {
            if (animation_timeout == 0) {
                return;
            }

            Source.remove (animation_timeout);
            animation_timeout = 0;
        }

        void draw_waves (Gtk.DrawingArea area, Cairo.Context cairo, int width, int height) {
            if (width <= 0 || height <= 0) {
                return;
            }

            // Clear background - transparent
            cairo.set_operator (Cairo.Operator.CLEAR);
            cairo.paint ();
            cairo.set_operator (Cairo.Operator.OVER);

            // Get color for waves
            var color = get_color ();

            // Draw animated waves
            cairo.set_line_width (2.0);

            for (int i = 0; i < WAVE_COUNT; i++) {
                var wave_offset = animation_time + (i * Math.PI / WAVE_COUNT);
                var alpha = 0.3 + (i * 0.1);
                alpha = double.min (1.0, alpha);

                cairo.set_source_rgba (color.red, color.green, color.blue, (float) alpha);

                cairo.move_to (0, height / 2.0);

                for (int x = 0; x < width; x += 2) {
                    var y = height / 2.0 +
                            WAVE_AMPLITUDE * Math.sin ((x / 50.0) + wave_offset) +
                            (WAVE_AMPLITUDE * 0.5) * Math.sin ((x / 100.0) + wave_offset * 1.5);

                    cairo.line_to (x, y);
                }

                cairo.stroke ();
            }
        }
    }
}
