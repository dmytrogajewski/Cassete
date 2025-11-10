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
 * Collection item data wrapper
 */
public class Tape.YaMAPI.CollectionItemData : ApiBase.DataObject {
    public Album? album { get; set; }
    public Playlist? playlist { get; set; }
}

/**
 * Collection item wrapper (has type and data)
 */
public class Tape.YaMAPI.CollectionItem : ApiBase.DataObject {
    public string type_ { get; set; }
    public CollectionItemData? data { get; set; }

    // Convenience properties
    public Album? album {
        get {
            return data?.album;
        }
    }

    public Playlist? playlist {
        get {
            return data?.playlist;
        }
        set {
            if (data == null) {
                data = new CollectionItemData ();
            }
            data.playlist = value;
        }
    }
}

/**
 * Collection tab item (for albums or playlists)
 */
public class Tape.YaMAPI.CollectionTabItem : ApiBase.DataObject {
    public string type_ { get; set; }
    public string id { get; set; }
    public string title { get; set; }
    public ArrayList<CollectionItem> items { get; set; default = new ArrayList<CollectionItem> (); }
}

/**
 * Collection tabs response (for albums or playlists)
 */
public class Tape.YaMAPI.CollectionTabs : ApiBase.DataObject {
    public ArrayList<CollectionTabItem> tabs { get; set; default = new ArrayList<CollectionTabItem> (); }
}

/**
 * Collection liked albums response
 */
public class Tape.YaMAPI.CollectionLikedAlbums : ApiBase.DataObject {
    public ArrayList<CollectionTabItem> tabs { get; set; default = new ArrayList<CollectionTabItem> (); }
}

/**
 * Collection liked playlists response
 */
public class Tape.YaMAPI.CollectionLikedPlaylists : ApiBase.DataObject {
    public ArrayList<CollectionTabItem> tabs { get; set; default = new ArrayList<CollectionTabItem> (); }
}
