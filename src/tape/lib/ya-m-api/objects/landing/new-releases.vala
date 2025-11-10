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
 * New releases landing block item
 */
public class Tape.YaMAPI.Landing.NewReleasesItem : ApiBase.DataObject {
    public Album album { get; set; }
}

/**
 * New releases landing block
 */
public class Tape.YaMAPI.Landing.NewReleases : ApiBase.DataObject {
    public ArrayList<NewReleasesItem> items { get; set; default = new ArrayList<NewReleasesItem> (); }

    // Convenience property
    public ArrayList<Album> get_albums () {
        var albums = new ArrayList<Album> ();
        foreach (var item in items) {
            if (item.album != null) {
                albums.add (item.album);
            }
        }
        return albums;
    }
}
