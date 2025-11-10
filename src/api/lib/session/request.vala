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

/**
 * Request object. Can handle parameters, headers, post content.
 * {@link Session.exec} and {@link Session.exec_async}
 * form message via {@link form_message} and set this to readonly
 *
 * @since 3.0
 */
public class ApiBase.Request : Object {

    public HttpMethod method { get; construct; }

    public string uri { get; construct; }

    Soup.Message message;

    Gee.HashSet<Header?> headers = new Gee.HashSet<Header?> (
        (el) => {
            return str_hash (el.name);
        },
        (el1, el2) => {
            return str_equal (el1.name, el2.name);
        }
    );

    Gee.HashSet<Param?> parameters = new Gee.HashSet<Param?> (
        (el) => {
            return str_hash (el.name);
        },
        (el1, el2) => {
            return str_equal (el1.name, el2.name);
        }
    );

    Gee.HashSet<string> _presets = new Gee.HashSet<string> ();
    public string[] presets {
        owned get {
            return _presets.to_array ();
        }
        set {
            _presets.clear ();
            _presets.add_all_array (value);
        }
    }

    PostContent? post_content = null;

    Request (HttpMethod method, string uri) {
        Object (
            method: method,
            uri: uri
        );
    }

    public Request.GET (string uri) {
        this (HttpMethod.GET, uri);
    }

    public Request.HEAD (string uri) {
        this (HttpMethod.HEAD, uri);
    }

    public Request.OPTIONS (string uri) {
        this (HttpMethod.OPTIONS, uri);
    }

    public Request.TRACE (string uri) {
        this (HttpMethod.TRACE, uri);
    }

    public Request.PUT (string uri) {
        this (HttpMethod.PUT, uri);
    }

    public Request.DELETE (string uri) {
        this (HttpMethod.DELETE, uri);
    }

    public Request.POST (string uri) {
        this (HttpMethod.POST, uri);
    }

    public Request.PATCH (string uri) {
        this (HttpMethod.PATCH, uri);
    }

    public Request.CONNECT (string uri) {
        this (HttpMethod.CONNECT, uri);
    }

    construct {
        headers = new Gee.HashSet<Header?> (
            (el) => {
                return str_hash (el.name);
            },
            (el1, el2) => {
                return str_equal (el1.name, el2.name);
            }
        );
    }

    /**
     * Add header with header object
     *
     * @param header    Header object
     * @param replace   Replace existing header with equal name or not
     *
     * @since 4.0
     */
    public void add_header (string name, string value, bool replace = true) {
        add_header_struct ({ name, value }, replace);
    }

    void add_header_struct (Header header, bool replace = true) {
        assert (message == null);

        if (header in headers && !replace) {
            return;
        }
        headers.add (header);
    }

    /**
     * Add header with header objects array
     *
     * @param headers   Header objects array
     * @param replace   Replace existing header with equal name or not
     *
     * @since 3.0
     */
    public void add_headers (Header[] headers, bool replace = true) {
        foreach (var header in headers) {
            add_header_struct (header, replace);
        }
    }

    /**
     * Add parameter with parameter data
     *
     * @param name      Parameter name
     * @param value     Parameter value
     *
     * @since 4.0
     */
    public void add_param (string name, string value) {
        add_param_struct ({ name, value });
    }

    void add_param_struct (Param parameter) {
        assert (message == null);

        parameters.add (parameter);
    }

    /**
     * Add parameters with an array
     *
     * @param parameters Parameter objeccts array
     *
     * @since 3.0
     */
    public void add_parameters (Param[] parameters) {
        foreach (var parameter in parameters) {
            add_param_struct (parameter);
        }
    }

    /**
     * Add post content to request
     *
     * @param post_content  Post content object
     *
     * @since 3.0
     */
    public void add_post_content (PostContent post_content) {
        assert (message == null);
        assert (method == HttpMethod.POST);

        this.post_content = post_content;
    }

    /**
     * Get status code from internal {@link Soup.Message}.
     * Must be run after {@link form_message} or
     * {@link Session.exec}/{@link Session.exec_async}
     *
     * @return  Status
     *
     * @since 3.0
     */
    public Soup.Status get_status_code () {
        assert (message != null);

        return message.get_status ();
    }

    internal Soup.Message form_message () {
        if (message != null) {
            return message;
        }

        string new_uri;

        if (parameters.size != 0) {
            new_uri = form_paramed_uri ();
        } else {
            new_uri = uri;
        }

        message = new Soup.Message (method.to_string (), new_uri);

        if (post_content != null) {
            message.set_request_body_from_bytes (
                post_content.content_type.to_string (),
                post_content.get_bytes ()
            );
        }

        if (headers.size != 0) {
            foreach (var header in headers) {
                message.request_headers.append (header.name, header.value);
            }
        }

        return message;
    }

    string form_paramed_uri () {
        var final_parameters = new Gee.ArrayList<string> ();
        final_parameters.add_all_iterator (parameters.map<string> ((el) => {
            return el.to_string ();
        }));

        var new_uri = "%s?%s".printf (uri, string.joinv ("&", final_parameters.to_array ()));

        return new_uri;
    }

    /**
     * Simple request execution.
     *
     * @throws SoupError            Internal error from libsoup
     * @throws BadStatusCodeError   Bad status code from request
     *
     * @since 3.0
     */
    public GLib.Bytes simple_exec (
        Cancellable? cancellable = null
    ) throws SoupError, BadStatusCodeError {
        var soup_wrapper = new Session ();
        return soup_wrapper.exec (this, cancellable);
    }

    /**
     * Asynchronious version of {@link simple_exec}
     *
     * @throws SoupError            Internal error from libsoup
     * @throws BadStatusCodeError   Bad status code from request
     *
     * @since 3.0
     */
    public async GLib.Bytes simple_exec_async (
        int priority = Priority.DEFAULT,
        Cancellable? cancellable = null
    ) throws SoupError, BadStatusCodeError {
        var soup_wrapper = new Session ();
        return yield soup_wrapper.exec_async (this, priority, cancellable);
    }
}
