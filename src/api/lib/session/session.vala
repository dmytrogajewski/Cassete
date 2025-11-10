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
 * along with this program. If not, see <https://www.gnu.org/licenses/>.
 *
 * SPDX-License-Identifier: GPL-3.0-or-later
 */

using Soup;

/**
 * A wrapper class for libsoup
 */
public sealed class ApiBase.Session : Object {

    /**
     * Cookies storage type
     */
    public CookieJarType cookie_jar_type { get; private set; default = NONE; }

    /**
     * Path to cookies
     */
    public string? cookies_file_path { get; private set; }

    HashTable<string, Array<Header>> presets_table = new HashTable<string, Array<Header>> (str_hash, str_equal);

    Soup.Session session = new Soup.Session () {
        timeout = GLOBAL_TIMEOUT,
        idle_timeout = 60
    };

    /**
     * Session user agent
     */
    public string? user_agent { get; construct; }

    /**
     * @param user_agent    Session user agent
     */
    public Session (string? user_agent = null) {
        Object (user_agent: user_agent);
    }

    construct {
        var logger = new Soup.Logger (BODY);

        logger.set_printer ((logger, level, direction, data) => {
            switch (direction) {
                case '<':
                case '>':
                    debug ("%c: %s", direction, data);
                    break;

                default:
                    debug ("");
                    break;
            }
        });

        bind_property ("user-agent", session, "user-agent", BindingFlags.SYNC_CREATE);

        session.add_feature (logger);
    }

    /**
     * Init cookiew with type and path
     *
     * @param cookie_jar_type   Cookies storage type
     * @param cookies_file_path Path to cookies
     *
     * @since 3.0
     */
    public void init_cookies (
        CookieJarType cookie_jar_type,
        string cookies_file_path
    ) {
        this.cookie_jar_type = cookie_jar_type;
        this.cookies_file_path = cookies_file_path;

        reload_cookies ();
    }

    /**
     * Reload cookies, fully resetting it.
     */
    public void reload_cookies () {
        Type? feature_type;

        switch (cookie_jar_type) {
            case DB:
                feature_type = typeof (Soup.CookieJarDB);
                break;

            case TEXT:
                feature_type = typeof (Soup.CookieJarText);
                break;

            case NONE:
                feature_type = null;
                break;

            default:
                assert_not_reached ();
        }

        if (feature_type != null) {
            if (session.has_feature (feature_type)) {
                session.remove_feature_by_type (feature_type);
            }
        }

        if (cookies_file_path != null) {
            Soup.CookieJar cookie_jar;

            switch (cookie_jar_type) {
                case DB:
                    cookie_jar = new Soup.CookieJarDB (cookies_file_path, false);
                    break;

                case TEXT:
                    cookie_jar = new Soup.CookieJarText (cookies_file_path, false);
                    break;

                default:
                    assert_not_reached ();
            }

            session.add_feature (cookie_jar);
            debug ("Cookies updated. New cookies file: \"%s\"", cookies_file_path);
        }
    }

    /**
     * Add preset to session. Headers presets can be used with {@link Request.add_preset_name}
     */
    public void add_headers_preset (string preset_name, Header[] headers) {
        if (!presets_table.contains (preset_name)) {
            presets_table[preset_name] = new Array<Header> ();
        }
        foreach (var header in headers) {
            presets_table[preset_name].append_val (header);
        }
    }

    void fill_request_presets (Request request) {
        foreach (var preset_name in request.presets) {
            Array<Header> headers = presets_table.get (preset_name);
            if (headers != null) {
                request.add_headers ((Header[]) headers.data, false);
            }
        }
    }

    void check_status_code (Soup.Status status_code, Bytes? bytes) throws SoupError, BadStatusCodeError {
        if (status_code == Soup.Status.OK) {
            return;
        }

        string error_message = (string) (bytes.get_data ()) ?? "";

        throw get_error (status_code, error_message);
    }

    /**
     * Synchronously execute the {@link Request}
     *
     * @throws SoupError            Internal error from libsoup
     * @throws BadStatusCodeError   Bad status code from request
     *
     * @since 3.0
     */
    public GLib.Bytes? exec (
        Request request,
        Cancellable? cancellable = null
    ) throws SoupError, BadStatusCodeError {
        GLib.Bytes? bytes = null;

        fill_request_presets (request);

        var message = request.form_message ();

        try {
            bytes = session.send_and_read (message, cancellable);

        } catch (Error e) {
            if (e is IOError.CANCELLED) {
                throw new SoupError.CANCELLED (e.message);
            } else {
                throw new SoupError.INTERNAL ("%s %s: %s".printf (message.method, message.uri.to_string (), e.message));
            }
        }

        check_status_code (request.get_status_code (), bytes);

        return bytes;
    }

    /**
     * Asynchronously execute the {@link Request}
     *
     * @throws SoupError            Internal error from libsoup
     * @throws BadStatusCodeError   Bad status code from request
     *
     * @since 3.0
     */
    public async GLib.Bytes? exec_async (
        Request request,
        int priority = Priority.DEFAULT,
        Cancellable? cancellable = null
    ) throws SoupError, BadStatusCodeError {
        GLib.Bytes? bytes = null;

        fill_request_presets (request);

        var message = request.form_message ();

        try {
            bytes = yield session.send_and_read_async (message, priority, cancellable);

        } catch (Error e) {
            if (e is IOError.CANCELLED) {
                throw new SoupError.CANCELLED (e.message);
            } else {
                throw new SoupError.INTERNAL ("%s %s: %s".printf (message.method, message.uri.to_string (), e.message));
            }
        }

        check_status_code (request.get_status_code (), bytes);

        return bytes;
    }
}
