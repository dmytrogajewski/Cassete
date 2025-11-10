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
 * In-style artist item (album in style of an artist)
 */
public class Tape.YaMAPI.Landing.InStyleItem : ApiBase.DataObject {
    public Album album { get; set; }
    public ArrayList<Artist> artists { get; set; default = new ArrayList<Artist> (); }
    // Trailer is optional - just ignore it for now
}

/**
 * In-style tab (albums in style of a specific artist)
 */
public class Tape.YaMAPI.Landing.InStyleTab : ApiBase.DataObject {
    public int id { get; set; }
    public string title { get; set; }
    public Cover? cover { get; set; }
    public ArrayList<InStyleItem> items { get; set; default = new ArrayList<InStyleItem> (); }
}

/**
 * In-style section (albums in style of specific artists)
 */
public class Tape.YaMAPI.Landing.InStyle : ApiBase.DataObject {
    // Property name must match JSON field after conversion
    // JSON: inStyleTabs -> Case.AUTO converts to kebab: in-style-tabs
    // Property name when stripped: needs to match "in-style-tabs"
    // Since Vala doesn't allow dashes, we need a property that strips to match
    // Try: property name as-is matches the converted kebab name
    public ArrayList<InStyleTab> inStyleTabs { // vala-lint-disable naming-convention
        get; set; default = new ArrayList<InStyleTab> ();
    }

    // Convenience property for backward compatibility
    public ArrayList<InStyleTab> tabs {
        owned get {
            return inStyleTabs;
        }
    }

    // Convenience methods
    public ArrayList<Artist> get_artists () {
        var artists = new ArrayList<Artist> ();
        foreach (var tab in inStyleTabs) {
            foreach (var item in tab.items) {
                foreach (var artist in item.artists) {
                    if (!artists.contains (artist)) {
                        artists.add (artist);
                    }
                }
            }
        }
        return artists;
    }

    public HashMap<string, ArrayList<Album>> get_albums_by_artist () {
        var albums_by_artist = new HashMap<string, ArrayList<Album>> ();
        foreach (var tab in inStyleTabs) {
            var albums = new ArrayList<Album> ();
            foreach (var item in tab.items) {
                if (item.album != null) {
                    albums.add (item.album);
                }
            }
            albums_by_artist[tab.id.to_string ()] = albums;
        }
        return albums_by_artist;
    }
}
