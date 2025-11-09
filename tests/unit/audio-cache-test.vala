/*
 * Copyright (C) 2025
 *
 * SPDX-License-Identifier: GPL-3.0-or-later
 */

using GLib;
using Tape;

class AudioCacheTestContext : Object {
    public string base_dir { get; private set; }
    string? prev_data_home;
    string? prev_cache_home;

    public AudioCacheTestContext (string name) {
        var template = Path.build_filename (
            Environment.get_tmp_dir (),
            "cassette-audio-cache-%s-XXXXXX".printf (name)
        );
        base_dir = DirUtils.mkdtemp (template);
        var data_dir = Path.build_filename (base_dir, "data");
        var cache_dir = Path.build_filename (base_dir, "cache");

        DirUtils.create_with_parents (data_dir, 0x1ED);
        DirUtils.create_with_parents (cache_dir, 0x1ED);

        prev_data_home = Environment.get_variable ("XDG_DATA_HOME");
        prev_cache_home = Environment.get_variable ("XDG_CACHE_HOME");

        Environment.set_variable ("XDG_DATA_HOME", data_dir, true);
        Environment.set_variable ("XDG_CACHE_HOME", cache_dir, true);

        var settings = new Tape.Settings ("CassetteTest", "space.rirusha.Cassette.Test");
        client = new Tape.Client (settings);
    }

    public Tape.Client client { get; private set; }

    public Tape.Storager storager {
        get { return client.cachier.storager; }
    }

    public void cleanup () {
        if (prev_data_home != null) {
            Environment.set_variable ("XDG_DATA_HOME", prev_data_home, true);
        } else {
            Environment.unset_variable ("XDG_DATA_HOME");
        }

        if (prev_cache_home != null) {
            Environment.set_variable ("XDG_CACHE_HOME", prev_cache_home, true);
        } else {
            Environment.unset_variable ("XDG_CACHE_HOME");
        }

        remove_recursive (File.new_for_path (base_dir));
    }

    void remove_recursive (File file) {
        try {
            var info = file.query_info ("standard::type", FileQueryInfoFlags.NONE);
            if (info.get_file_type () == FileType.DIRECTORY) {
                FileEnumerator? enumerator = file.enumerate_children ("standard::*", FileQueryInfoFlags.NONE, null);
                if (enumerator != null) {
                    FileInfo? child_info;
                    while ((child_info = enumerator.next_file ()) != null) {
                        remove_recursive (file.get_child (child_info.get_name ()));
                    }
                }
            }

            file.delete ();
        } catch (Error e) {
            Test.message ("Cleanup warning: %s", e.message);
        }
    }
}

async void audio_cache_creates_playback_file () throws Error {
    var ctx = new AudioCacheTestContext ("decoded");

    try {
        const string track_id = "109441";
        uint8[] original = { 0x10, 0x20, 0x30, 0x40 };
        uint8[] to_store = original.copy ();
        Bytes audio_bytes = new Bytes.take ((owned) to_store);

        yield ctx.storager.save_audio (audio_bytes, track_id, true);

        var playback_path = yield ctx.storager.ensure_audio_playback_file (track_id);
        assert_nonnull (playback_path);

        var playback_file = File.new_for_path (playback_path);
        uint8[] playback_data;
        yield playback_file.load_contents_async (null, out playback_data, null);

        assert_true (playback_data.length == original.length);
        for (int i = 0; i < playback_data.length; i++) {
            assert_true (playback_data[i] == original[i]);
        }

        var encoded_location = ctx.storager.audio_cache_location (track_id);
        assert_nonnull (encoded_location.file);
        uint8[] encoded_data;
        yield encoded_location.file.load_contents_async (null, out encoded_data, null);

        bool identical = true;
        for (int i = 0; i < encoded_data.length && i < original.length; i++) {
            if (encoded_data[i] != original[i]) {
                identical = false;
                break;
            }
        }
        assert_false (identical);

        for (int i = 0; i < encoded_data.length; i++) {
            encoded_data[i] ^= 0xFF;
        }

        for (int i = 0; i < original.length; i++) {
            assert_true (encoded_data[i] == original[i]);
        }
    } finally {
        ctx.cleanup ();
    }
}

async void audio_cache_returns_null_when_missing () throws Error {
    var ctx = new AudioCacheTestContext ("missing");

    try {
        var playback_path = yield ctx.storager.ensure_audio_playback_file ("no-track");
        assert_true (playback_path == null);
    } finally {
        ctx.cleanup ();
    }
}

async void audio_cache_preserves_fresh_playback_file () throws Error {
    var ctx = new AudioCacheTestContext ("preserve");

    try {
        const string track_id = "109442";
        uint8[] original = { 0xAA, 0xBB, 0xCC, 0xDD };
        uint8[] to_store = original.copy ();
        Bytes audio_bytes = new Bytes.take ((owned) to_store);

        yield ctx.storager.save_audio (audio_bytes, track_id, true);
        var playback_path = yield ctx.storager.ensure_audio_playback_file (track_id);
        assert_nonnull (playback_path);

        var playback_file = File.new_for_path (playback_path);
        uint8[] mutated = original.copy ();
        mutated[0] ^= 0xFF;

        yield playback_file.replace_contents_async (
            mutated,
            null,
            false,
            FileCreateFlags.NONE,
            null,
            null
        );

        Thread.usleep (1000000);

        var replayed_path = yield ctx.storager.ensure_audio_playback_file (track_id);
        assert_true (replayed_path == playback_path);

        uint8[] final_data;
        yield playback_file.load_contents_async (null, out final_data, null);
        assert_true (final_data.length == mutated.length);
        for (int i = 0; i < final_data.length; i++) {
            assert_true (final_data[i] == mutated[i]);
        }
    } finally {
        ctx.cleanup ();
    }
}

void add_audio_cache_tests () {
    Test.add_func ("/cache/audio/decoded-playback-file", () => {
        var loop = new MainLoop ();
        audio_cache_creates_playback_file.begin ((obj, res) => {
            try {
                audio_cache_creates_playback_file.end (res);
            } catch (Error e) {
                Test.message ("Test failure: %s".printf (e.message));
                Test.fail ();
            } finally {
                loop.quit ();
            }
        });
        loop.run ();
    });

    Test.add_func ("/cache/audio/missing-track-returns-null", () => {
        var loop = new MainLoop ();
        audio_cache_returns_null_when_missing.begin ((obj, res) => {
            try {
                audio_cache_returns_null_when_missing.end (res);
            } catch (Error e) {
                Test.message ("Test failure: %s".printf (e.message));
                Test.fail ();
            } finally {
                loop.quit ();
            }
        });
        loop.run ();
    });

    Test.add_func ("/cache/audio/preserve-existing-playback", () => {
        var loop = new MainLoop ();
        audio_cache_preserves_fresh_playback_file.begin ((obj, res) => {
            try {
                audio_cache_preserves_fresh_playback_file.end (res);
            } catch (Error e) {
                Test.message ("Test failure: %s".printf (e.message));
                Test.fail ();
            } finally {
                loop.quit ();
            }
        });
        loop.run ();
    });
}

int main (string[] args) {
    Test.init (ref args);

    add_audio_cache_tests ();

    return Test.run ();
}

