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

using Gee;

/**
 * Summary for collection playlist with likes
 */
public class Tape.YaMAPI.CollectionSummary : ApiBase.DataObject {
    public int count { get; set; }
}

/**
 * Collection playlist with liked tracks response
 */
public class Tape.YaMAPI.CollectionPlaylistWithLikes : ApiBase.DataObject {
    public CollectionSummary summary { get; set; }
    public ArrayList<Track> tracks { get; set; default = new ArrayList<Track> (); }
    public Playlist playlist { get; set; }
}
