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
 * Error from libjson
 *
 * @since 3.0
 */
public errordomain ApiBase.JsonError {
    /**
     * Json string is empty
     */
    EMPTY,

    /**
     * Json string is invalid
     */
    INVALID,

    /**
     * Try to deserislize wrong type
     */
    WRONG_TYPE,

    /**
     * Try to 'step' non existing members
     */
    NO_MEMBER;
}

/**
 * Error from libsoup
 *
 * @since 3.0
 */
public errordomain ApiBase.SoupError {
    INTERNAL,
    CANCELLED;
}

/**
 * Bad status codes error
 */
public errordomain ApiBase.BadStatusCodeError {

    BAD_REQUEST = 400,
    UNAUTHORIZED = 401,
    FORBIDDEN = 403,
    NOT_FOUND = 404,
    METHOD_NOT_ALLOWED = 405,
    REQUEST_TIMEOUT = 408,
    CONFLICT = 409,
    GONE = 410,
    PAYLOAD_TOO_LARGE = 413,
    UNSUPPORTED_MEDIA_TYPE = 415,
    TOO_MANY_REQUESTS = 429,

    INTERNAL_SERVER_ERROR = 500,
    NOT_IMPLEMENTED = 501,
    BAD_GATEWAY = 502,
    SERVICE_UNAVAILABLE = 503,
    GATEWAY_TIMEOUT = 504,

    UNKNOWN = 0
}
