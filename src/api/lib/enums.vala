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

public enum ApiBase.HttpMethod {
    GET,
    HEAD,
    OPTIONS,
    TRACE,
    PUT,
    DELETE,
    POST,
    PATCH,
    CONNECT;

    public string to_string () {
        return get_enum_class (typeof (HttpMethod)).get_value (this).value_nick.up ();
    }
}

/**
 * Supported post content types
 */
public enum ApiBase.PostContentType {
    X_WWW_FORM_URLENCODED,
    JSON;

    public string to_string () {
        switch (this) {
            case X_WWW_FORM_URLENCODED:
                return "application/x-www-form-urlencoded";
            case JSON:
                return "application/json";
            default:
                assert_not_reached ();
        }
    }
}

/**
 * Name cases. With AUTO {@link Jsoner} will try detect name case for every member of
 * json object. Useful for working with bad API developers
 */
public enum ApiBase.Case {
    AUTO,
    SNAKE,
    KEBAB,
    CAMEL;
}

/**
 * Type of cookie jar to create
 */
public enum ApiBase.CookieJarType {
    NONE,
    DB,
    TEXT;
}
